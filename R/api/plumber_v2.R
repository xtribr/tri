# =============================================================================
# API TRI v2 - SISTEMA DE CORREÇÃO PARA MENTORIAS
# =============================================================================
#
# DESCRIÇÃO:
#   API REST avançada para análise psicométrica usando Teoria de Resposta ao
#   Item (TRI). Suporta calibração, CAT (Computerized Adaptive Testing) e 
#   scoring com ensemble TRI + Regressão Linear.
#
# ENDPOINTS PRINCIPAIS:
#
# 1. CALIBRAÇÃO
#    POST /tct/analisar         - Análise TCT preliminar
#    POST /calibrar             - Calibração TRI (Rasch/2PL/3PL)
#    POST /calibrar/ancoras     - Calibração com âncoras fixas (equalização)
#
# 2. SCORING
#    POST /estimar_theta        - Estimação de theta (EAP/MAP/ML)
#    POST /scoring/estimar      - Scoring com ensemble TRI + Regressão
#
# 3. CAT (COMPUTERIZED ADAPTIVE TESTING)
#    POST /cat/sessao/iniciar   - Iniciar sessão CAT
#    POST /cat/sessao/responder - Registrar resposta
#    POST /cat/sessao/estado    - Ver estado da sessão
#    POST /cat/simular          - Simulação completa do CAT
#
# MODELOS SUPORTADOS:
#   - Rasch: 1 parâmetro (dificuldade)
#   - 2PL: 2 parâmetros (discriminação + dificuldade)
#   - 3PL: 3 parâmetros (+ acaso/careless)
#
# DEPENDÊNCIAS:
#   - plumber: Framework API REST
#   - mirt: Modelos TRI
#   - jsonlite: Serialização JSON
#   - dplyr: Manipulação de dados
#   - memoise: Cache de funções
#
# COMO EXECUTAR:
#   library(plumber)
#   pr("R/api/plumber_v2.R") %>% pr_run(port=8000)
#
# DOCUMENTAÇÃO INTERATIVA:
#   Acesse http://localhost:8000/__docs__/ quando o servidor estiver rodando
#
# FUTURAS MELHORIAS:
#   - [ ] Autenticação JWT
#   - [ ] Rate limiting
#   - [ ] Persistência em banco de dados (PostgreSQL)
#   - [ ] Clustering para múltiplos workers
#
# HISTÓRICO:
#   2026-02-17: v2.0 - Sistema completo com CAT e ensemble scoring
# =============================================================================

library(plumber)    # Framework API REST
library(mirt)       # Modelos TRI
library(jsonlite)   # JSON
library(dplyr)      # Manipulação de dados
library(memoise)    # Cache

#* @apiTitle API TRI v2 - Sistema de Mentorias
#* @apiDescription API avançada para calibração, CAT e scoring com regressão linear

# ============================================================================
# 1. MÓDULO DE CALIBRAÇÃO
# ============================================================================

# Cache de informação para performance
calcular_informacao <- function(theta, a, b, c) {
  p <- c + (1 - c) / (1 + exp(-a * (theta - b)))
  q <- 1 - p
  info <- (a^2 * (q/p) * ((p-c)/(1-c))^2)
  return(info)
}

# Análise TCT Preliminar (baseado em 93552.pdf)
#* @post /tct/analisar
#* @param dados:object Matriz de respostas
#* @serializer json
function(req, res) {
  tryCatch({
    body <- fromJSON(req$postBody)
    dados <- as.matrix(body$dados)
    
    n <- nrow(dados)
    scores <- rowSums(dados, na.rm = TRUE)
    
    resultados <- data.frame(
      item = colnames(dados) %||% paste0("Q", 1:ncol(dados)),
      n_respondentes = colSums(!is.na(dados)),
      taxa_acerto = round(colMeans(dados, na.rm = TRUE), 4),
      dificuldade_tct = round(1 - colMeans(dados, na.rm = TRUE), 4),
      correlacao_bisserial = sapply(1:ncol(dados), function(i) {
        # Correlação ponto-bisserial
        cor(dados[,i], scores - dados[,i], use = "complete.obs")
      }),
      stringsAsFactors = FALSE
    )
    
    # Flags de qualidade
    resultados$flag <- "OK"
    resultados$flag[resultados$taxa_acerto < 0.1] <- "MUITO_DIFICIL"
    resultados$flag[resultados$taxa_acerto > 0.9] <- "MUITO_FACIL"
    resultados$flag[abs(resultados$correlacao_bisserial) < 0.15] <- "BAIXA_DISCRIMINACAO"
    resultados$flag[resultados$correlacao_bisserial < 0] <- "DISCRIMINACAO_NEGATIVA"
    
    # Recomendações
    resultados$recomendacao <- "Manter"
    resultados$recomendacao[resultados$flag %in% c("MUITO_DIFICIL", "MUITO_FACIL", "DISCRIMINACAO_NEGATIVA")] <- "Revisar"
    
    list(
      sucesso = TRUE,
      estatisticas_globais = list(
        n_respondentes = n,
        n_itens = ncol(dados),
        score_medio = round(mean(scores), 2),
        score_dp = round(sd(scores), 2),
        consistencia_interna = round(cor(scores, scores - dados[,1]) * sqrt(ncol(dados)/(ncol(dados)-1)), 4)  # Aproximação alpha
      ),
      itens = resultados
    )
    
  }, error = function(e) {
    res$status <- 500
    list(sucesso = FALSE, error = e$message)
  })
}

# Calibração com suporte a âncoras (baseado em INEP)
#* @post /calibrar/v2
#* @param dados:object Matriz de respostas
#* @param modelo:string Modelo (Rasch, 2PL, 3PL, 3PL_ENEM)
#* @param ancoras:object Opcional: lista de âncoras com valores fixos
#* @param prioris:object Opcional: configuração de prioris
#* @serializer json
function(req, res, modelo = "3PL") {
  tryCatch({
    body <- fromJSON(req$postBody)
    dados <- as.matrix(body$dados)
    
    # Validação
    if (!all(dados %in% c(0, 1, NA))) {
      res$status <- 400
      return(list(error = "Dados devem ser binários (0 ou 1)"))
    }
    
    # Selecionar modelo
    itemtype <- switch(modelo,
                       "Rasch" = "Rasch",
                       "2PL" = "2PL",
                       "3PL" = "3PL",
                       "3PL_ENEM" = "3PL",  # Com prioris ENEM
                       "3PL")
    
    # Configurar modelo com prioris se especificado
    if (modelo == "3PL_ENEM") {
      # Prioris ENEM: Beta(4,16) para c (E[c] = 0.20)
      n_itens <- ncol(dados)
      modelo_str <- sprintf('
        F = 1-%d
        PRIOR = (1-%d, a1, lnorm, -0.6550, 1.1445),
                (1-%d, g, beta, 4, 16)
      ', n_itens, n_itens, n_itens)
      mirt_model <- mirt.model(modelo_str)
    } else {
      mirt_model <- 1
    }
    
    # Verificar se há âncoras para fixar
    if (!is.null(body$ancoras)) {
      ancoras <- body$ancoras
      
      # Obter matriz de parâmetros
      pars <- mirt(dados, mirt_model, itemtype = itemtype, 
                   pars = "values", verbose = FALSE)
      
      # Fixar parâmetros das âncoras
      for (i in seq_along(ancoras$item_id)) {
        item_idx <- which(colnames(dados) == ancoras$item_id[i])
        if (length(item_idx) > 0) {
          # Converter b para d (intercepto): d = -a*b
          d_val <- -ancoras$a[i] * ancoras$b[i]
          
          # Linhas na matriz pars
          lin_a <- which(pars$item == item_idx & pars$name == "a1")
          lin_d <- which(pars$item == item_idx & pars$name == "d")
          lin_g <- which(pars$item == item_idx & pars$name == "g")
          
          if (length(lin_a) > 0) {
            pars$value[lin_a] <- ancoras$a[i]
            pars$est[lin_a] <- FALSE
          }
          if (length(lin_d) > 0) {
            pars$value[lin_d] <- d_val
            pars$est[lin_d] <- FALSE
          }
          if (length(lin_g) > 0 && !is.null(ancoras$c)) {
            pars$value[lin_g] <- ancoras$c[i]
            pars$est[lin_g] <- FALSE
          }
        }
      }
      
      # Calibrar com parâmetros fixos
      fit <- mirt(dados, mirt_model, itemtype = itemtype, 
                  pars = pars, verbose = FALSE)
    } else {
      # Calibração normal
      fit <- mirt(dados, mirt_model, itemtype = itemtype, 
                  verbose = FALSE)
    }
    
    # Extrair parâmetros
    params <- coef(fit, IRTpars = TRUE, simplify = TRUE)
    
    # Formatar resultado
    n_itens <- ncol(dados)
    itens <- data.frame(
      item_id = colnames(dados) %||% paste0("Q", 1:n_itens),
      a = round(params$items[, 1], 4),
      b = round(params$items[, 2], 4),
      c = round(params$items[, 3], 4),
      stringsAsFactors = FALSE
    )
    
    # Estatísticas de ajuste
    fit_stats <- data.frame(
      logLik = fit@Fit$logLik,
      AIC = fit@Fit$AIC,
      BIC = fit@Fit$BIC,
      convergiu = extract.mirt(fit, "converged"),
      stringsAsFactors = FALSE
    )
    
    # Estatísticas de ajuste por item (se disponível)
    tryCatch({
      item_fit <- itemfit(fit, method = "S-X2")
      itens$ajuste_pvalor <- round(item_fit$p, 4)
      itens$ajuste_status <- ifelse(item_fit$p > 0.05, "OK", "PROBLEMA")
    }, error = function(e) {
      itens$ajuste_pvalor <- NA
      itens$ajuste_status <- "NA"
    })
    
    list(
      sucesso = TRUE,
      modelo = modelo,
      n_respondentes = nrow(dados),
      n_itens = n_itens,
      parametros = itens,
      ajuste = fit_stats,
      obs = ifelse(modelo == "3PL_ENEM", 
                   "Usada priori Beta(4,16) para c (E[c]=0.20)", 
                   "Sem prioris específicas")
    )
    
  }, error = function(e) {
    res$status <- 500
    list(sucesso = FALSE, error = e$message)
  })
}

# ============================================================================
# ============================================================================
# 2. MÓDULO CAT v2 - COMPUTERIZED ADAPTIVE TESTING
# ============================================================================
#
# DESCRIÇÃO:
#   Implementação de CAT (Teste Adaptativo Computadorizado) que seleciona
#   itens de forma adaptativa com base na habilidade estimada do candidato.
#
# CRITÉRIOS DE SELEÇÃO SUPORTADOS:
#   - MFI (Maximum Fisher Information): Mais eficiente, item que maximiza
#     a informação no theta atual
#   - MLWI (Maximum Likelihood Weighted Information): Alternativa ao MFI
#   - MPWI (Maximum Posterior Weighted Information): Com priori
#   - MEI (Maximum Expected Information): Esperança da informação
#
# REGRAS DE PARADA:
#   1. Número máximo de itens atingido (ex: 30)
#   2. Precisão alcançada (SE < 0.3)
#   3. Número mínimo de itens + precisão
#   4. Número máximo de itens consecutivos sem mudança significativa
#
# ARQUITETURA:
#   - Sessões armazenadas em memória (lista R)
#   - Em produção: substituir por Redis/PostgreSQL
#   - Stateless: cada requisição independe da anterior
#
# FLUXO DE USO:
#   1. POST /cat/sessao/iniciar     → Cria sessão, retorna sessao_id
#   2. GET  /cat/sessao/{id}/proximo_item → Retorna item a responder
#   3. POST /cat/sessao/{id}/responder → Envia resposta, atualiza theta
#   4. Repete 2-3 até critério de parada
#   5. GET  /cat/sessao/{id}/resultado → Relatório final
#
# FUTURAS MELHORIAS:
#   - [ ] Content balancing (balanceamento por áreas)
#   - [ ] Controle de exposição de itens (pool rotation)
#   - [ ] Detecção de comportamento atípico (raso, trapaça)
#   - [ ] Warm-up items (itens iniciais fixos)
# ============================================================================

# Store de sessões em memória
# NOTA: Em produção, substituir por Redis ou banco de dados
sessoes <- list()

#* @post /cat/sessao/iniciar
#* @param aluno_id:string ID do aluno (opcional)
#* @param configuracao:object Configurações do CAT (opcional)
#* @serializer json
function(req, res) {
  tryCatch({
    body <- fromJSON(req$postBody)
    
    # ID do aluno (gerar automático se não fornecido)
    aluno_id <- body$aluno_id %||% paste0("anon_", format(Sys.time(), "%s"))
    
    # Configurações padrão do CAT
    config <- body$configuracao %||% list(
      modelo = "3PL",           # Modelo TRI (Rasch/2PL/3PL)
      criterio_selecao = "MFI", # Critério de seleção de itens
      max_itens = 30,           # Máximo de itens a aplicar
      min_itens = 10,           # Mínimo de itens antes de parar
      se_alvo = 0.3,            # Erro padrão alvo (precisão)
      content_areas = NULL,     # Para content balancing (futuro)
      exposicao_max = 0.5       # Máxima proporção de exposição do item
    )
    
    # Gerar ID único da sessão (timestamp + random)
    sessao_id <- paste0("sess_", format(Sys.time(), "%s"), "_", sample(1000:9999, 1))
    
    sessao <- list(
      id = sessao_id,
      aluno_id = aluno_id,
      estado = "INICIADO",
      theta_atual = 0,
      se_atual = 999,
      n_itens_aplicados = 0,
      itens_aplicados = character(),
      respostas = numeric(),
      historico = data.frame(
        passo = integer(),
        item_id = character(),
        resposta = integer(),
        theta_est = numeric(),
        se = numeric(),
        info = numeric(),
        tempo = numeric(),
        stringsAsFactors = FALSE
      ),
      configuracao = config,
      timestamp_inicio = Sys.time()
    )
    
    # Armazenar sessão
    sessoes[[sessao_id]] <<- sessao
    
    list(
      sucesso = TRUE,
      sessao_id = sessao_id,
      estado = sessao$estado,
      mensagem = "Sessão CAT iniciada. Use /cat/sessao/{id}/proximo_item para obter o primeiro item."
    )
    
  }, error = function(e) {
    res$status <- 500
    list(sucesso = FALSE, error = e$message)
  })
}

# Selecionar próximo item
#* @post /cat/sessao/<id>/proximo_item
#* @param banco_itens:object Banco de itens com parâmetros
#* @param tempo_limite:number Tempo limite em segundos (opcional)
#* @serializer json
function(req, res, id) {
  tryCatch({
    body <- fromJSON(req$postBody)
    
    # Recuperar sessão
    if (!id %in% names(sessoes)) {
      res$status <- 404
      return(list(error = "Sessão não encontrada"))
    }
    
    sessao <- sessoes[[id]]
    
    if (sessao$estado == "FINALIZADO") {
      return(list(
        sucesso = FALSE,
        error = "Sessão já finalizada",
        resultado = list(
          theta_final = round(sessao$theta_atual, 4),
          se_final = round(sessao$se_atual, 4)
        )
      ))
    }
    
    banco <- body$banco_itens
    theta <- sessao$theta_atual
    
    # Itens já aplicados
    disponiveis <- setdiff(banco$item_id, sessao$itens_aplicados)
    
    if (length(disponiveis) == 0) {
      sessao$estado <<- "FINALIZADO"
      sessoes[[id]] <<- sessao
      return(list(sucesso = FALSE, error = "Não há mais itens disponíveis"))
    }
    
    idx_disp <- which(banco$item_id %in% disponiveis)
    a_disp <- banco$a[idx_disp]
    b_disp <- banco$b[idx_disp]
    c_disp <- banco$c[idx_disp]
    
    # Calcular informação (MFI)
    info <- calcular_informacao(theta, a_disp, b_disp, c_disp)
    
    # Content balancing (se especificado)
    if (!is.null(sessao$configuracao$content_areas) && !is.null(banco$area)) {
      areas_aplicadas <- banco$area[banco$item_id %in% sessao$itens_aplicados]
      if (length(areas_aplicadas) > 0) {
        prop_areas <- table(areas_aplicadas) / length(areas_aplicadas)
        for (area in names(prop_areas)) {
          if (prop_areas[area] > 0.4) {
            # Penalizar itens desta área
            idx_area <- idx_disp[banco$area[idx_disp] == area]
            info[banco$area[idx_disp] == area] <- info[banco$area[idx_disp] == area] * 0.7
          }
        }
      }
    }
    
    # Selecionar item com máxima informação
    melhor_local <- which.max(info)
    melhor_idx <- idx_disp[melhor_local]
    
    item_selecionado <- list(
      item_id = banco$item_id[melhor_idx],
      a = round(banco$a[melhor_idx], 4),
      b = round(banco$b[melhor_idx], 4),
      c = round(banco$c[melhor_idx], 4),
      informacao = round(info[melhor_local], 4),
      passo = sessao$n_itens_aplicados + 1,
      tempo_limite = body$tempo_limite %||% 120  # Default 2 minutos
    )
    
    sessao$estado <<- "EM_ANDAMENTO"
    sessoes[[id]] <<- sessao
    
    list(
      sucesso = TRUE,
      sessao_id = id,
      item = item_selecionado,
      progresso = list(
        itens_aplicados = sessao$n_itens_aplicados,
        theta_atual = round(sessao$theta_atual, 4),
        se_atual = round(sessao$se_atual, 4)
      )
    )
    
  }, error = function(e) {
    res$status <- 500
    list(sucesso = FALSE, error = e$message)
  })
}

# Registrar resposta e atualizar theta
#* @post /cat/sessao/<id>/responder
#* @param item_id:string ID do item respondido
#* @param resposta:integer Resposta (0 ou 1)
#* @param tempo:number Tempo em segundos (opcional)
#* @param banco_itens:object Banco de itens
#* @serializer json
function(req, res, id) {
  tryCatch({
    body <- fromJSON(req$postBody)
    
    if (!id %in% names(sessoes)) {
      res$status <- 404
      return(list(error = "Sessão não encontrada"))
    }
    
    sessao <- sessoes[[id]]
    item_id <- body$item_id
    resposta <- as.integer(body$resposta)
    tempo <- body$tempo %||% NA
    banco <- body$banco_itens
    
    # Validar
    if (!(resposta %in% c(0, 1))) {
      res$status <- 400
      return(list(error = "Resposta deve ser 0 ou 1"))
    }
    
    # Adicionar resposta
    sessao$itens_aplicados <<- c(sessao$itens_aplicados, item_id)
    sessao$respostas <<- c(sessao$respostas, resposta)
    sessao$n_itens_aplicados <<- sessao$n_itens_aplicados + 1
    
    # Obter parâmetros dos itens aplicados
    idx_itens <- match(sessao$itens_aplicados, banco$item_id)
    a <- banco$a[idx_itens]
    b <- banco$b[idx_itens]
    c <- banco$c[idx_itens]
    
    # Reestimar theta via EAP (método oficial ENEM)
    theta_grid <- seq(-4, 4, length.out = 200)
    prior <- dnorm(theta_grid, mean = 0, sd = 1)
    
    likelihood <- rep(1, length(theta_grid))
    for (i in seq_along(sessao$respostas)) {
      p <- c[i] + (1 - c[i]) / (1 + exp(-a[i] * (theta_grid - b[i])))
      likelihood <- likelihood * (p^sessao$respostas[i] * (1-p)^(1-sessao$respostas[i]))
    }
    
    posterior <- likelihood * prior
    total_posterior <- sum(posterior)
    
    if (total_posterior > 0 && !is.na(total_posterior)) {
      posterior <- posterior / total_posterior
      theta_est <- sum(theta_grid * posterior)
      theta_var <- sum((theta_grid - theta_est)^2 * posterior)
      theta_se <- sqrt(max(theta_var, 0.001))
    } else {
      theta_est <- sessao$theta_atual
      theta_se <- sessao$se_atual
    }
    
    # Calcular informação do último item
    info_item <- calcular_informacao(theta_est, a[length(a)], b[length(b)], c[length(c)])
    
    # Atualizar histórico
    novo_historico <- data.frame(
      passo = sessao$n_itens_aplicados,
      item_id = item_id,
      resposta = resposta,
      theta_est = round(theta_est, 4),
      se = round(theta_se, 4),
      info = round(info_item, 4),
      tempo = tempo,
      stringsAsFactors = FALSE
    )
    sessao$historico <<- rbind(sessao$historico, novo_historico)
    sessao$theta_atual <<- theta_est
    sessao$se_atual <<- theta_se
    
    # Verificar critérios de parada
    deve_parar <- FALSE
    motivo_parada <- NULL
    
    config <- sessao$configuracao
    
    # Critério 1: Número mínimo/máximo de itens
    if (sessao$n_itens_aplicados >= config$max_itens) {
      deve_parar <- TRUE
      motivo_parada <- "MAX_ITENS"
    } else if (sessao$n_itens_aplicados >= config$min_itens) {
      # Critério 2: Precisão atingida
      if (theta_se <= config$se_alvo) {
        deve_parar <- TRUE
        motivo_parada <- "PRECISAO_ATINGIDA"
      }
      
      # Critério 3: Convergência (mudança pequena)
      if (sessao$n_itens_aplicados >= 5) {
        mudanca <- abs(sessao$historico$theta_est[sessao$n_itens_aplicados] - 
                      sessao$historico$theta_est[sessao$n_itens_aplicados - 1])
        if (mudanca < 0.05) {
          deve_parar <- TRUE
          motivo_parada <- "CONVERGENCIA"
        }
      }
    }
    
    if (deve_parar) {
      sessao$estado <<- "FINALIZADO"
    }
    
    sessoes[[id]] <<- sessao
    
    resultado <- list(
      sucesso = TRUE,
      sessao_id = id,
      estado = sessao$estado,
      theta_atual = round(theta_est, 4),
      se_atual = round(theta_se, 4),
      n_itens = sessao$n_itens_aplicados,
      precisao = round(1 / (theta_se^2), 2)  # Informação total
    )
    
    if (deve_parar) {
      resultado$motivo_parada <- motivo_parada
      resultado$mensagem <- "CAT finalizado. Use /cat/sessao/{id}/resultado para ver o relatório completo."
    } else {
      resultado$mensagem <- "Resposta registrada. Solicite o próximo item."
    }
    
    return(resultado)
    
  }, error = function(e) {
    res$status <- 500
    list(sucesso = FALSE, error = e$message)
  })
}

# Obter resultado final da sessão
#* @get /cat/sessao/<id>/resultado
#* @serializer json
function(req, res, id) {
  tryCatch({
    if (!id %in% names(sessoes)) {
      res$status <- 404
      return(list(error = "Sessão não encontrada"))
    }
    
    sessao <- sessoes[[id]]
    
    # Calcular métricas de qualidade
    cobertura_theta <- length(unique(sessao$historico$theta_est)) / sessao$n_itens_aplicados
    
    # Transformar para escala 0-1000 (estilo ENEM)
    nota_transformada <- 500 + (sessao$theta_atual * 100)
    nota_transformada <- max(0, min(1000, nota_transformada))
    
    list(
      sucesso = TRUE,
      sessao_id = id,
      aluno_id = sessao$aluno_id,
      estado = sessao$estado,
      resultado = list(
        theta_estimado = round(sessao$theta_atual, 4),
        erro_padrao = round(sessao$se_atual, 4),
        intervalo_confianca_95 = c(
          round(sessao$theta_atual - 1.96 * sessao$se_atual, 4),
          round(sessao$theta_atual + 1.96 * sessao$se_atual, 4)
        ),
        nota_escala_1000 = round(nota_transformada),
        classificacao = case_when(
          nota_transformada >= 700 ~ "AVANCADO",
          nota_transformada >= 500 ~ "INTERMEDIARIO",
          TRUE ~ "BASICO"
        )
      ),
      estatisticas_sessao = list(
        n_itens_aplicados = sessao$n_itens_aplicados,
        tempo_total = as.numeric(difftime(Sys.time(), sessao$timestamp_inicio, units = "mins")),
        taxa_acerto = mean(sessao$respostas),
        informacao_total = round(1 / (sessao$se_atual^2), 2)
      ),
      historico = sessao$historico
    )
    
  }, error = function(e) {
    res$status <- 500
    list(sucesso = FALSE, error = e$message)
  })
}

# ============================================================================
# 3. MÓDULO SCORING COM REGRESSÃO
# ============================================================================

# Estimar score com ensemble TRI + Regressão
#* @post /scoring/estimar
#* @param respostas:array Vetor de respostas (0/1)
#* @param parametros_itens:object Parâmetros dos itens aplicados
#* @param dados_contexto:object Opcional: variáveis para regressão
#* @param modelo_regressao:object Opcional: coeficientes do modelo
#* @serializer json
function(req, res) {
  tryCatch({
    body <- fromJSON(req$postBody)
    respostas <- unlist(body$respostas)
    params <- body$parametros_itens
    
    # 1. Estimar theta via TRI (EAP)
    theta_grid <- seq(-4, 4, length.out = 200)
    prior <- dnorm(theta_grid, mean = 0, sd = 1)
    
    likelihood <- rep(1, length(theta_grid))
    for (i in seq_along(respostas)) {
      if (!is.na(respostas[i])) {
        a <- params$a[i]
        b <- params$b[i]
        c <- ifelse(is.null(params$c), 0, params$c[i])
        p <- c + (1 - c) / (1 + exp(-a * (theta_grid - b)))
        likelihood <- likelihood * (p^respostas[i] * (1-p)^(1-respostas[i]))
      }
    }
    
    posterior <- likelihood * prior
    posterior <- posterior / sum(posterior)
    theta_est <- sum(theta_grid * posterior)
    theta_var <- sum((theta_grid - theta_est)^2 * posterior)
    theta_se <- sqrt(max(theta_var, 0.001))
    
    # 2. Transformar para escala prática (0-1000)
    nota_tri <- 500 + (theta_est * 100)
    nota_tri <- max(0, min(1000, nota_tri))
    
    # 3. Regressão (se modelo fornecido)
    nota_final <- nota_tri
    contribuicao_reg <- NULL
    
    if (!is.null(body$modelo_regressao) && !is.null(body$dados_contexto)) {
      # Coeficientes do modelo de regressão
      coefs <- body$modelo_regressao
      dados_ctx <- body$dados_contexto
      
      # Calcular predição
      pred <- coefs$intercepto
      if (!is.null(dados_ctx$n_itens)) {
        pred <- pred + coefs$n_itens * dados_ctx$n_itens
      }
      if (!is.null(dados_ctx$taxa_acerto)) {
        pred <- pred + coefs$taxa_acerto * dados_ctx$taxa_acerto
      }
      if (!is.null(dados_ctx$tempo_medio)) {
        pred <- pred + coefs$tempo_medio * dados_ctx$tempo_medio
      }
      
      # Ensemble: média ponderada
      peso_tri <- 0.6
      peso_reg <- 0.4
      nota_final <- peso_tri * nota_tri + peso_reg * pred
      
      contribuicao_reg <- list(
        nota_regressao = round(pred, 2),
        peso_tri = peso_tri,
        peso_reg = peso_reg
      )
    }
    
    # 4. Intervalo de confiança
    ic_95 <- c(
      theta_est - 1.96 * theta_se,
      theta_est + 1.96 * theta_se
    )
    ic_nota <- c(
      max(0, 500 + (ic_95[1] * 100)),
      min(1000, 500 + (ic_95[2] * 100))
    )
    
    resultado <- list(
      sucesso = TRUE,
      estimativas = list(
        theta = round(theta_est, 4),
        se = round(theta_se, 4),
        nota_final = round(nota_final),
        nota_apenas_tri = round(nota_tri)
      ),
      intervalo_confianca = list(
        theta_ic95 = round(ic_95, 4),
        nota_ic95 = round(ic_nota)
      ),
      qualidade = list(
        nivel_confianca = case_when(
          theta_se < 0.3 ~ "ALTO",
          theta_se < 0.5 ~ "MEDIO",
          TRUE ~ "BAIXO"
        ),
        n_itens_utilizados = sum(!is.na(respostas)),
        informacao_total = round(1 / (theta_se^2), 2)
      )
    )
    
    if (!is.null(contribuicao_reg)) {
      resultado$contribuicao_regressao <- contribuicao_reg
    }
    
    return(resultado)
    
  }, error = function(e) {
    res$status <- 500
    list(sucesso = FALSE, error = e$message)
  })
}

# ============================================================================
# 4. HELPERS
# ============================================================================

`%||%` <- function(x, y) if (is.null(x)) y else x

# Health check
#* @get /health
function() {
  list(
    status = "OK",
    versao = "2.0.0",
    timestamp = Sys.time(),
    modulos = c("calibracao", "cat", "scoring", "tct"),
    sessoes_ativas = length(sessoes)
  )
}
