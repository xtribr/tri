# Propostas de Melhorias - Sistema TRI para Mentorias

## Visão Geral do Sistema Futuro

Após análise da biblioteca ENEM, documentação INEP e código atual, proponho uma arquitetura robusta para um sistema de correção com:

1. **Regressão linear** para estimativas de scores
2. **Calibração de itens** com múltiplos modelos
3. **CAT (Computerized Adaptive Testing)** com fluxo inteligente

---

## 1. Arquitetura Recomendada

```
┌─────────────────────────────────────────────────────────────────┐
│                    SISTEMA TRI MENTORIAS                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Módulo     │  │   Módulo     │  │   Módulo     │          │
│  │  Calibração  │  │    CAT       │  │   Scoring    │          │
│  │              │  │              │  │              │          │
│  │ • 3PL/Rasch  │  │ • MFI        │  │ • EAP/MAP    │          │
│  │ • Fixação    │  │ • Content    │  │ • Regressão  │          │
│  │ • Prioris    │  │   Balancing  │  │   Linear     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                 │
│         └──────────────────┼──────────────────┘                 │
│                            │                                    │
│                    ┌───────┴───────┐                           │
│                    │  Banco de     │                           │
│                    │  Itens (BNI)  │                           │
│                    │               │                           │
│                    │ • Parâmetros  │                           │
│                    │ • Estatísticas│                           │
│                    │ • Tags        │                           │
│                    └───────────────┘                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Melhorias por Módulo

### 2.1 Módulo de Calibração

#### Problema Atual
- Não suporta fixação de parâmetros (itens âncora)
- Sem especificação de prioris
- Sem análise TCT preliminar

#### Melhorias Propostas

**A. Adicionar Análise TCT Preliminar** (baseado em 93552.pdf)

```r
# Nova função: análise TCT antes da TRI
analisar_tct <- function(dados) {
  n <- nrow(dados)
  resultados <- data.frame(
    item = colnames(dados),
    n_respondentes = colSums(!is.na(dados)),
    taxa_acerto = colMeans(dados, na.rm = TRUE),
    correlacao_bisserial = sapply(1:ncol(dados), function(i) {
      cor(dados[,i], rowSums(dados, na.rm = TRUE) - dados[,i], use = "complete.obs")
    }),
    stringsAsFactors = FALSE
  )
  
  # Flag itens problemáticos
  resultados$flag <- ifelse(
    resultados$taxa_acerto < 0.1 | resultados$taxa_acerto > 0.9,
    "DIFICULDADE_EXTREMA",
    ifelse(
      resultados$correlacao_bisserial < 0.15,
      "BAIXA_DISCRIMINACAO",
      "OK"
    )
  )
  
  return(resultados)
}
```

**B. Suporte a Fixação de Parâmetros** (baseado em INEP e artigo pre-teste.pdf)

```r
# Calibração com itens âncora fixos
calibrar_com_ancoras <- function(dados, itens_ancora = NULL, 
                                 valores_fixos = NULL,
                                 modelo = "3PL") {
  
  # Se há âncoras, preparar matriz de parâmetros
  if (!is.null(itens_ancora)) {
    pars <- mirt(dados, 1, itemtype = modelo, pars = "values")
    
    # Fixar parâmetros das âncoras
    for (i in seq_along(itens_ancora)) {
      item_idx <- itens_ancora[i]
      lin_a <- which(pars$item == item_idx & pars$name == "a1")
      lin_b <- which(pars$item == item_idx & pars$name == "d")
      lin_c <- which(pars$item == item_idx & pars$name == "g")
      
      # Converter b para d (intercepto)
      d_val <- -valores_fixos$a[i] * valores_fixos$b[i]
      
      pars$value[lin_a] <- valores_fixos$a[i]
      pars$est[lin_a] <- FALSE
      pars$value[lin_b] <- d_val
      pars$est[lin_b] <- FALSE
      pars$value[lin_c] <- valores_fixos$c[i]
      pars$est[lin_c] <- FALSE
    }
    
    mod <- mirt(dados, 1, itemtype = modelo, pars = pars)
  } else {
    mod <- mirt(dados, 1, itemtype = modelo)
  }
  
  return(mod)
}
```

**C. Prioris Informativas** (baseado em ENEM - 92067.pdf)

```r
# Configuração ENEM: priori Beta(4,16) para c = 0.20
modelo_enem <- mirt.model('
  F = 1-45
  PRIOR = (1-45, a1, lnorm, -0.6550, 1.1445),   # Discriminação
          (1-45, g, beta, 4, 16)                  # c ~ Beta(4,16)
')

# Configuração ENAMED: Rasch sem prioris (a=1 fixo)
modelo_enamed <- mirt.model('
  F = 1-100
  CONSTRAIN = (1-100, a1)  # Discriminação = 1
')
```

---

### 2.2 Módulo CAT (Computerized Adaptive Testing)

#### Problema Atual
- Apenas critério MFI (Maximum Fisher Information)
- Sem content balancing
- Sem critério de parada baseado em precisão
- Sem exposição de itens

#### Melhorias Propostas

**A. Múltiplos Critérios de Seleção**

```r
# Implementar critérios adicionais
selecionar_item <- function(theta, banco, criterio = "MFI", 
                            content_balancing = NULL,
                            exposicao_max = 0.3) {
  
  switch(criterio,
    "MFI" = {
      # Maximum Fisher Information (atual)
      info <- calcular_informacao(theta, banco)
    },
    "MLWI" = {
      # Maximum Likelihood Weighted Information
      # Considera incerteza sobre theta
      info <- calcular_mlwi(theta, banco)
    },
    "MPWI" = {
      # Maximum Posterior Weighted Information
      # Integra sobre distribuição posterior
      info <- calcular_mpwi(theta, banco)
    },
    "KL" = {
      # Kullback-Leibler Information
      # Maximiza informação esperada
      info <- calcular_kl(theta, banco)
    },
    "randomesque" = {
      # Seleção aleatória dentre os melhores (para segurança)
      info <- calcular_randomesque(theta, banco, n_melhores = 5)
    }
  )
  
  # Content balancing
  if (!is.null(content_balancing)) {
    areas_sobrerrepresentadas <- names(which(content_balancing > 0.4))
    info[banco$area %in% areas_sobrerrepresentadas] <- 
      info[banco$area %in% areas_sobrerrepresentadas] * 0.8
  }
  
  # Controle de exposição (item exposure control)
  itens_muito_expostos <- banco$item_id[banco$taxa_exposicao > exposicao_max]
  info[banco$item_id %in% itens_muito_expostos] <- 0
  
  return(banco$item_id[which.max(info)])
}
```

**B. Critérios de Parada Robusto**

```r
# Critérios de parada do CAT
deve_parar_cat <- function(n_itens, se_theta, historico, 
                           max_itens = 30, min_itens = 10,
                           se_minimo = 0.3,
                           criterio_parada = "SE") {
  
  if (n_itens < min_itens) return(FALSE)
  if (n_itens >= max_itens) return(TRUE)
  
  switch(criterio_parada,
    "SE" = {
      # Parar quando erro padrão atinge mínimo
      return(se_theta <= se_minimo)
    },
    "INFO" = {
      # Parar quando ganho de informação é marginal
      if (n_itens < 5) return(FALSE)
      info_atual <- 1 / (se_theta^2)
      info_anterior <- 1 / (historico$se[n_itens-1]^2)
      ganho <- (info_atual - info_anterior) / info_anterior
      return(ganho < 0.05)  # Ganho menor que 5%
    },
    "CONVERGENCIA" = {
      # Parar quando theta estabiliza
      if (n_itens < 5) return(FALSE)
      mudanca <- abs(historico$theta[n_itens] - historico$theta[n_itens-1])
      return(mudanca < 0.1)
    }
  )
}
```

**C. Fluxo de Sessão com Estados**

```r
# Gerenciar sessão do aluno com máquina de estados
criar_sessao_cat <- function(aluno_id, banco_itens, 
                             configuracao = list(
                               modelo = "3PL",
                               criterio_selecao = "MFI",
                               max_itens = 30,
                               se_alvo = 0.3,
                               content_areas = c("Algebra", "Geometria", "Estatistica")
                             )) {
  list(
    sessao_id = uuid::UUIDgenerate(),
    aluno_id = aluno_id,
    estado = "INICIADO",  # INICIADO -> EM_ANDAMENTO -> FINALIZADO
    theta_atual = 0,
    se_atual = 999,
    n_itens_aplicados = 0,
    itens_aplicados = character(),
    respostas = numeric(),
    historico = data.frame(),
    configuracao = configuracao,
    timestamp_inicio = Sys.time()
  )
}

# Atualizar sessão após resposta
atualizar_sessao <- function(sessao, item_id, resposta) {
  sessao$n_itens_aplicados <- sessao$n_itens_aplicados + 1
  sessao$itens_aplicados <- c(sessao$itens_aplicados, item_id)
  sessao$respostas <- c(sessao$respostas, resposta)
  
  # Reestimar theta
  resultado_theta <- estimar_theta_eap(
    sessao$respostas,
    banco_itens[sessao$itens_aplicados, ]
  )
  
  sessao$theta_atual <- resultado_theta$theta
  sessao$se_atual <- resultado_theta$se
  
  # Verificar parada
  if (deve_parar_cat(sessao$n_itens_aplicados, sessao$se_atual, 
                     sessao$historico, sessao$configuracao$max_itens)) {
    sessao$estado <- "FINALIZADO"
  } else {
    sessao$estado <- "EM_ANDAMENTO"
  }
  
  return(sessao)
}
```

---

### 2.3 Módulo de Scoring com Regressão Linear

#### Problema Atual
- Apenas estimativas TRI puras
- Sem transformação para escala prática
- Sem consideração de fatores contextuais

#### Melhorias Propostas

**A. Transformação TRI → Escala Prática** (baseado em ENEM)

```r
# Transformação similar ao ENEM (escala 0-1000)
transformar_escala <- function(theta, parametros_escala = list(
  media = 500,
  dp = 100,
  min = 0,
  max = 1000
)) {
  nota <- parametros_escala$media + (theta * parametros_escala$dp)
  return(round(pmin(pmax(nota, parametros_escala$min), parametros_escala$max)))
}

# Ou usar equipercentil (baseado em âncoras)
transformar_equipercentil <- function(theta, distribuicao_ancoras) {
  # Encontrar percentil correspondente
  percentil <- ecdf(distribuicao_ancoras$theta)(theta)
  
  # Mapear para escala alvo
  nota <- quantile(distribuicao_ancoras$nota, percentil)
  
  return(nota)
}
```

**B. Regressão Linear para Predição de Desempenho**

```r
# Modelo de regressão para predição de score
# Baseado em variáveis do estudante e histórico
modelo_regressao_score <- function(dados_treino) {
  # Variáveis preditoras
  # - Theta estimado na TRI
  # - Número de itens respondidos
  # - Taxa de acerto
  # - Tempo de resposta médio
  # - Áreas de dificuldade identificadas
  
  modelo <- lm(
    nota_final ~ theta_tri + n_itens + taxa_acerto + 
                 tempo_medio + area_dificuldade,
    data = dados_treino
  )
  
  return(modelo)
}

# Prever score com intervalo de confiança
prever_score <- function(modelo, novo_dado, nivel_confianca = 0.95) {
  pred <- predict(modelo, novo_dado, 
                  interval = "prediction", 
                  level = nivel_confianca)
  
  list(
    estimativa = pred[1],
    ic_inferior = pred[2],
    ic_superior = pred[3],
    precisao = (pred[3] - pred[2]) / 2
  )
}
```

**C. Combinação TRI + Modelos Lineares** (ensemble)

```r
# Ensemble: média ponderada de múltiplos métodos
estimar_score_ensemble <- function(respostas, parametros_itens,
                                   modelo_regressao = NULL,
                                   pesos = c(tri = 0.6, reg = 0.4)) {
  
  # Método 1: TRI pura
  score_tri <- estimar_theta_eap(respostas, parametros_itens)
  nota_tri <- transformar_escala(score_tri$theta)
  
  # Método 2: Regressão (se disponível)
  if (!is.null(modelo_regressao)) {
    dados_pred <- data.frame(
      theta_tri = score_tri$theta,
      n_itens = length(respostas),
      taxa_acerto = mean(respostas, na.rm = TRUE),
      # ... outras variáveis
    )
    nota_reg <- predict(modelo_regressao, dados_pred)
    
    # Média ponderada
    nota_final <- pesos["tri"] * nota_tri + pesos["reg"] * nota_reg
  } else {
    nota_final <- nota_tri
  }
  
  return(list(
    nota_final = nota_final,
    nota_tri = nota_tri,
    nota_reg = if(!is.null(modelo_regressao)) nota_reg else NULL,
    pesos = pesos
  ))
}
```

---

## 3. Melhorias de Infraestrutura

### 3.1 Persistência de Dados

```r
# Estrutura de banco de dados recomendada
# (usar RPostgres ou SQLite)

# Tabelas principais:
# - alunos: id, dados_demograficos, historico
# - itens: id, parametros_a_b_c, estatísticas, tags
# - sessoes_cat: id, aluno_id, theta_inicial, theta_final, status
# - respostas: sessao_id, item_id, resposta, tempo_resposta
# - calibracoes: data, modelo, parametros_estimados, ajuste
```

### 3.2 Cache e Performance

```r
# Cache de informação dos itens (evitar recalcular)
library(memoise)

calcular_informacao_memo <- memoise(function(theta, a, b, c) {
  p <- c + (1 - c) / (1 + exp(-a * (theta - b)))
  q <- 1 - p
  return((a^2 * (q/p) * ((p-c)/(1-c))^2))
})

# Pré-calcular informação em grid
pre_calcular_info <- function(banco_itens, theta_grid = seq(-4, 4, 0.1)) {
  info_matrix <- matrix(0, nrow = length(theta_grid), ncol = nrow(banco_itens))
  for (i in seq_along(theta_grid)) {
    for (j in 1:nrow(banco_itens)) {
      info_matrix[i, j] <- calcular_informacao(
        theta_grid[i],
        banco_itens$a[j],
        banco_itens$b[j],
        banco_itens$c[j]
      )
    }
  }
  return(list(theta = theta_grid, info = info_matrix))
}
```

### 3.3 Logging e Monitoramento

```r
# Sistema de logging estruturado
log_evento <- function(sessao_id, tipo, dados) {
  registro <- list(
    timestamp = Sys.time(),
    sessao_id = sessao_id,
    tipo = tipo,  # "ITEM_APLICADO", "THETA_ATUALIZADO", "SESSAO_FINALIZADA"
    dados = dados
  )
  
  # Salvar em arquivo ou banco
  saveRDS(registro, file = paste0("logs/", uuid::UUIDgenerate(), ".rds"))
}

# Métricas de qualidade do CAT
calcular_metricas_cat <- function(sessao) {
  list(
    # Eficiência: SE final / SE inicial
    eficiencia = sessao$se_atual / 999,
    
    # Cobertura do banco: % do banco utilizado
    cobertura = length(unique(sessao$itens_aplicados)) / nrow(banco_itens),
    
    # Taxa de exposição balanceada
    balanceamento = sd(table(sessao$itens_aplicados)),
    
    # Tempo médio por item
    tempo_medio = mean(sessao$historico$tempo)
  )
}
```

---

## 4. Endpoints API Propostos

### Novos Endpoints

```r
# 1. Calibração avançada
# POST /calibrar/v2
# - Suporta âncoras fixas
# - Retorna estatísticas TCT
# - Inclui diagnóstico de ajuste

# 2. Sessão CAT
# POST /cat/sessao/iniciar
# GET  /cat/sessao/{id}/proximo_item
# POST /cat/sessao/{id}/responder
# GET  /cat/sessao/{id}/resultado

# 3. Scoring com regressão
# POST /scoring/estimar
# - Recebe respostas
# - Retorna theta, nota transformada, IC
# - Inclui predições do modelo de regressão

# 4. Análise de itens
# POST /itens/analise
# - Análise TCT completa
# - Curvas características
# - Diagnóstico de problemas

# 5. Relatórios
# GET /relatorios/aluno/{id}
# GET /relatorios/item/{id}
# GET /relatorios/banco/resumo
```

---

## 5. Implementação por Fases

### Fase 1: Fundação (2-3 semanas)
- [ ] Refatorar calibração com suporte a âncoras
- [ ] Implementar análise TCT
- [ ] Adicionar prioris configuráveis
- [ ] Criar estrutura de banco de dados

### Fase 2: CAT Robustecido (2-3 semanas)
- [ ] Implementar múltiplos critérios de seleção
- [ ] Adicionar content balancing
- [ ] Criar sistema de sessões com estados
- [ ] Implementar critérios de parada avançados

### Fase 3: Scoring Avançado (1-2 semanas)
- [ ] Implementar transformações de escala
- [ ] Criar modelo de regressão
- [ ] Desenvolver ensemble TRI + Regressão
- [ ] Adicionar intervalos de confiança

### Fase 4: Infraestrutura (1-2 semanas)
- [ ] Implementar cache
- [ ] Criar sistema de logging
- [ ] Desenvolver dashboards
- [ ] Otimizar performance

---

## 6. Código de Exemplo Completo

Ver arquivo: `R/api/plumber_v2.R` (a ser criado)

---

## Referências

- **92067.pdf**: Como TRI atribui escores no ENEM
- **93552.pdf**: Comparação TCT vs TRI
- **93979.pdf**: Efeito de posição
- **artigo pre-teste.pdf**: Calibração sem pré-teste
- **INEP_MIRT_RESUMO.md**: Configurações INEP
- **SKILL_TRI_CONTEXTOS.md**: Modelos por exame
