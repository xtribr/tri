# API TRI - Teoria de Resposta ao Item
# Endpoints para calibração e CAT

library(plumber)
library(mirt)
library(jsonlite)
library(dplyr)

#* @apiTitle API TRI - Análise de Itens
#* @apiDescription API para calibração de itens e Teste Adaptativo Computadorizado (CAT)

# Health check -----------------------------------------------------------
#* Health check
#* @get /health
function() {
  list(
    status = "OK",
    timestamp = Sys.time(),
    version = "1.0.0"
  )
}

# Calibrar itens ---------------------------------------------------------
#* Calibrar itens usando modelo TRI
#* @post /calibrar
#* @param dados:object Matriz de respostas (0/1)
#* @param modelo:string Modelo a usar (Rasch, 2PL, 3PL)
#* @serializer json
function(req, res, modelo = "2PL") {
  tryCatch({
    # Parse do body
    body <- fromJSON(req$postBody)
    
    if (is.null(body$dados)) {
      res$status <- 400
      return(list(error = "Dados não fornecidos"))
    }
    
    # Converter para matriz
    dados <- as.matrix(body$dados)
    
    # Validar dados binários
    if (!all(dados %in% c(0, 1, NA))) {
      res$status <- 400
      return(list(error = "Dados devem ser binários (0 ou 1)"))
    }
    
    # Selecionar tipo de modelo
    itemtype <- switch(modelo,
                       "Rasch" = "Rasch",
                       "2PL" = "2PL",
                       "3PL" = "3PL",
                       "2PL")
    
    # Ajustar modelo
    fit <- mirt(dados, model = 1, itemtype = itemtype, verbose = FALSE)
    
    # Extrair parâmetros
    params <- coef(fit, simplify = TRUE)
    
    # Formatar resultado
    n_itens <- ncol(dados)
    itens <- data.frame(
      item_id = colnames(dados) %||% paste0("Q", 1:n_itens),
      stringsAsFactors = FALSE
    )
    
    if (modelo == "Rasch") {
      itens$a <- 1
      itens$b <- params$items[, 2]
      itens$c <- 0
    } else if (modelo == "2PL") {
      itens$a <- params$items[, 1]
      itens$b <- params$items[, 2]
      itens$c <- 0
    } else {
      itens$a <- params$items[, 1]
      itens$b <- params$items[, 2]
      itens$c <- params$items[, 3]
    }
    
    # Estatísticas de ajuste
    fit_stats <- data.frame(
      logLik = fit@Fit$logLik,
      AIC = fit@Fit$AIC,
      BIC = fit@Fit$BIC,
      n_params = length(fit@Fit$pars),
      stringsAsFactors = FALSE
    )
    
    list(
      sucesso = TRUE,
      modelo = modelo,
      n_respondentes = nrow(dados),
      n_itens = n_itens,
      parametros = itens,
      ajuste = fit_stats
    )
    
  }, error = function(e) {
    res$status <- 500
    list(
      sucesso = FALSE,
      error = e$message
    )
  })
}

# Estimar habilidade (theta) ---------------------------------------------
#* Estimar habilidade de um respondente
#* @post /estimar_theta
#* @param respostas:array Respostas do respondente
#* @param parametros:object Parâmetros dos itens
#* @serializer json
function(req, res) {
  tryCatch({
    body <- fromJSON(req$postBody)
    
    if (is.null(body$respostas) || is.null(body$parametros)) {
      res$status <- 400
      return(list(error = "Respostas e parâmetros são obrigatórios"))
    }
    
    respostas <- unlist(body$respostas)
    params <- body$parametros
    
    # Calcular theta usando EAP (Expected A Posteriori)
    theta_grid <- seq(-4, 4, length.out = 200)
    prior <- dnorm(theta_grid, mean = 0, sd = 1)
    
    likelihood <- rep(1, length(theta_grid))
    for (i in seq_along(respostas)) {
      if (!is.na(respostas[i])) {
        # Modelo 2PL/3PL
        a <- params$a[i]
        b <- params$b[i]
        c <- ifelse(is.null(params$c) || is.na(params$c[i]), 0, params$c[i])
        p <- c + (1 - c) / (1 + exp(-a * (theta_grid - b)))
        likelihood <- likelihood * ifelse(respostas[i] == 1, p, 1 - p)
      }
    }
    
    # Normalizar posterior
    posterior <- likelihood * prior
    total_posterior <- sum(posterior)
    
    if (total_posterior == 0 || is.na(total_posterior)) {
      # Fallback: usar theta anterior ou 0
      theta_est <- body$theta_anterior %||% 0
      theta_se <- 1
    } else {
      posterior <- posterior / total_posterior
      theta_est <- sum(theta_grid * posterior)
      theta_var <- sum((theta_grid - theta_est)^2 * posterior)
      theta_se <- sqrt(max(theta_var, 0.001))  # Evitar SE muito pequeno
    }
    
    list(
      sucesso = TRUE,
      theta = round(theta_est, 4),
      se = round(theta_se, 4),
      intervalo_95 = c(
        round(theta_est - 1.96 * theta_se, 4),
        round(theta_est + 1.96 * theta_se, 4)
      )
    )
    
  }, error = function(e) {
    res$status <- 500
    list(
      sucesso = FALSE,
      error = e$message
    )
  })
}

# Selecionar próximo item (CAT) ------------------------------------------
#* Selecionar próximo item para CAT
#* @post /cat/selecionar_item
#* @param theta_estimado:number Theta atual
#* @param itens_disponiveis:array IDs dos itens disponíveis
#* @param parametros:object Parâmetros dos itens
#* @param criterio:string Critério de seleção (MFI, MLWI, MPWI)
#* @serializer json
function(req, res, criterio = "MFI") {
  tryCatch({
    body <- fromJSON(req$postBody)
    
    theta <- body$theta_estimado %||% 0
    disponiveis <- body$itens_disponiveis
    params <- body$parametros
    
    if (is.null(disponiveis) || length(disponiveis) == 0) {
      return(list(sucesso = FALSE, error = "Nenhum item disponível"))
    }
    
    # Filtrar itens disponíveis
    idx <- which(params$item_id %in% disponiveis)
    a_disp <- params$a[idx]
    b_disp <- params$b[idx]
    c_disp <- params$c[idx]
    
    # Calcular informação para cada item
    p <- c_disp + (1 - c_disp) / (1 + exp(-a_disp * (theta - b_disp)))
    q <- 1 - p
    info <- (a_disp^2 * (q / p) * ((p - c_disp) / (1 - c_disp))^2)
    
    # Selecionar item com máxima informação
    melhor_idx <- idx[which.max(info)]
    
    list(
      sucesso = TRUE,
      item_selecionado = params$item_id[melhor_idx],
      informacao = round(max(info), 4),
      criterio = criterio,
      theta_atual = round(theta, 4)
    )
    
  }, error = function(e) {
    res$status <- 500
    list(sucesso = FALSE, error = e$message)
  })
}

# Simular CAT completo ---------------------------------------------------
#* Simular um CAT completo
#* @post /cat/simular
#* @param theta_verdadeiro:number Theta verdadeiro do simulado
#* @param n_itens:number Número de itens a aplicar
#* @param parametros:object Parâmetros do banco de itens
#* @serializer json
function(req, res, theta_verdadeiro = 0, n_itens = 5) {
  tryCatch({
    body <- fromJSON(req$postBody)
    
    theta_true <- body$theta_verdadeiro %||% as.numeric(theta_verdadeiro)
    n <- body$n_itens %||% as.numeric(n_itens)
    params <- body$parametros
    
    a <- params$a
    b <- params$b
    c <- params$c
    item_ids <- params$item_id
    
    # Inicializar CAT
    theta_est <- 0
    respostas <- numeric(length(item_ids))
    respostas[] <- NA
    itens_aplicados <- character()
    historico <- data.frame(
      passo = integer(),
      item_id = character(),
      resposta = integer(),
      theta_est = numeric(),
      se = numeric(),
      stringsAsFactors = FALSE
    )
    
    # Simular aplicação dos itens
    for (passo in 1:n) {
      # Itens disponíveis
      disponiveis <- setdiff(item_ids, itens_aplicados)
      
      # Selecionar próximo item
      idx_disp <- which(item_ids %in% disponiveis)
      p_info <- c[idx_disp] + (1 - c[idx_disp]) / (1 + exp(-a[idx_disp] * (theta_est - b[idx_disp])))
      q_info <- 1 - p_info
      info <- (a[idx_disp]^2 * (q_info / p_info) * ((p_info - c[idx_disp]) / (1 - c[idx_disp]))^2)
      melhor_idx <- idx_disp[which.max(info)]
      item_sel <- item_ids[melhor_idx]
      
      # Simular resposta
      p_resp <- c[melhor_idx] + (1 - c[melhor_idx]) / (1 + exp(-a[melhor_idx] * (theta_true - b[melhor_idx])))
      resp <- ifelse(runif(1) < p_resp, 1, 0)
      
      respostas[melhor_idx] <- resp
      itens_aplicados <- c(itens_aplicados, item_sel)
      
      # Reestimar theta
      theta_grid <- seq(-4, 4, length.out = 200)
      prior <- dnorm(theta_grid, mean = 0, sd = 1)
      
      likelihood <- rep(1, length(theta_grid))
      for (i in which(!is.na(respostas))) {
        p <- c[i] + (1 - c[i]) / (1 + exp(-a[i] * (theta_grid - b[i])))
        likelihood <- likelihood * (p^respostas[i] * (1-p)^(1-respostas[i]))
      }
      
      posterior <- likelihood * prior
      total_posterior <- sum(posterior)
      
      if (total_posterior == 0 || is.na(total_posterior)) {
        theta_est <- theta_est  # Manter anterior
        theta_se <- 1
      } else {
        posterior <- posterior / total_posterior
        theta_est <- sum(theta_grid * posterior)
        theta_var <- sum((theta_grid - theta_est)^2 * posterior)
        theta_se <- sqrt(max(theta_var, 0.001))
      }
      
      historico <- rbind(historico, data.frame(
        passo = passo,
        item_id = item_sel,
        resposta = resp,
        theta_est = round(theta_est, 4),
        se = round(theta_se, 4),
        stringsAsFactors = FALSE
      ))
    }
    
    list(
      sucesso = TRUE,
      theta_verdadeiro = round(theta_true, 4),
      theta_estimado_final = round(theta_est, 4),
      erro_padrao_final = round(theta_se, 4),
      n_itens_aplicados = n,
      historico = historico
    )
    
  }, error = function(e) {
    res$status <- 500
    list(sucesso = FALSE, error = e$message)
  })
}

# Helper para operador %||%
`%||%` <- function(x, y) if (is.null(x)) y else x
