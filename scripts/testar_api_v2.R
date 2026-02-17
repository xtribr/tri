#!/usr/bin/env Rscript
# Script de teste da API TRI v2

library(httr)
library(jsonlite)

cat("=== Teste da API TRI v2 ===\n\n")

# Configuração
BASE_URL <- "http://127.0.0.1:8000"

# Função auxiliar para POST
post <- function(endpoint, body) {
  POST(
    url = paste0(BASE_URL, endpoint),
    body = toJSON(body, auto_unbox = TRUE, digits = 6),
    encode = "json",
    content_type_json()
  )
}

# 1. Health Check
cat("1. Health Check\n")
tryCatch({
  resp <- GET(paste0(BASE_URL, "/health"))
  if (status_code(resp) == 200) {
    result <- fromJSON(content(resp, "text"))
    cat(sprintf("   ✓ API versão %s rodando\n", result$versao))
    cat(sprintf("   ✓ Sessões ativas: %d\n\n", result$sessoes_ativas))
  }
}, error = function(e) {
  cat("   ✗ API não responde. Inicie o servidor primeiro:\n")
  cat("   R -e \"plumber::plumb('R/api/plumber_v2.R')\$run(port=8000)\")\n\n")
  quit(status = 1)
})

# 2. Testar Análise TCT
cat("2. Testando Análise TCT\n")
set.seed(42)
dados_teste <- matrix(sample(0:1, 100*20, replace = TRUE, prob = c(0.4, 0.6)), 
                      nrow = 100, ncol = 20)
colnames(dados_teste) <- paste0("Q", 1:20)

resp <- post("/tct/analisar", list(dados = dados_teste))
if (status_code(resp) == 200) {
  result <- fromJSON(content(resp, "text"))
  cat(sprintf("   ✓ Análise TCT concluída\n"))
  cat(sprintf("   ✓ Score médio: %.2f\n", result$estatisticas_globais$score_medio))
  cat(sprintf("   ✓ Itens com problema: %d\n\n", 
              sum(result$itens$flag != "OK")))
}

# 3. Testar Calibração v2
cat("3. Testando Calibração v2 (3PL ENEM)\n")
resp <- post("/calibrar/v2", list(
  dados = dados_teste,
  modelo = "3PL_ENEM"
))

if (status_code(resp) == 200) {
  result <- fromJSON(content(resp, "text"))
  cat(sprintf("   ✓ Modelo: %s\n", result$modelo))
  cat(sprintf("   ✓ Convergiu: %s\n", result$ajuste$convergiu))
  cat(sprintf("   ✓ Média discriminação (a): %.3f\n", mean(result$parametros$a)))
  cat(sprintf("   ✓ Média dificuldade (b): %.3f\n", mean(result$parametros$b)))
  cat(sprintf("   ✓ Média acerto casual (c): %.3f\n\n", mean(result$parametros$c)))
  
  banco_itens <- result$parametros
}

# 4. Testar Calibração com Âncoras
cat("4. Testando Calibração com Âncoras Fixas\n")
ancoras <- list(
  item_id = c("Q1", "Q5", "Q10"),
  a = c(1.2, 0.9, 1.5),
  b = c(-1.0, 0.0, 1.0),
  c = c(0.15, 0.20, 0.10)
)

resp <- post("/calibrar/v2", list(
  dados = dados_teste,
  modelo = "3PL",
  ancoras = ancoras
))

if (status_code(resp) == 200) {
  result <- fromJSON(content(resp, "text"))
  cat(sprintf("   ✓ Calibração com âncoras concluída\n"))
  cat(sprintf("   ✓ Itens calibrados: %d\n\n", nrow(result$parametros)))
}

# 5. Testar Sessão CAT
cat("5. Testando Fluxo CAT Completo\n")

# 5.1 Iniciar sessão
resp <- post("/cat/sessao/iniciar", list(
  aluno_id = "aluno_teste_001",
  configuracao = list(
    modelo = "3PL",
    max_itens = 10,
    min_itens = 5,
    se_alvo = 0.4
  )
))

if (status_code(resp) == 200) {
  result <- fromJSON(content(resp, "text"))
  sessao_id <- result$sessao_id
  cat(sprintf("   ✓ Sessão iniciada: %s\n", sessao_id))
}

# 5.2 Simular CAT (10 itens)
for (i in 1:10) {
  # Obter próximo item
  resp <- post(sprintf("/cat/sessao/%s/proximo_item", sessao_id), 
               list(banco_itens = banco_itens))
  
  if (status_code(resp) != 200) break
  
  item <- fromJSON(content(resp, "text"))
  item_id <- item$item$item_id
  
  # Simular resposta (acerto com probabilidade 0.6)
  resposta <- sample(c(0, 1), 1, prob = c(0.4, 0.6))
  tempo <- sample(30:120, 1)
  
  # Enviar resposta
  resp <- post(sprintf("/cat/sessao/%s/responder", sessao_id),
               list(
                 item_id = item_id,
                 resposta = resposta,
                 tempo = tempo,
                 banco_itens = banco_itens
               ))
  
  if (status_code(resp) == 200) {
    result <- fromJSON(content(resp, "text"))
    cat(sprintf("   Item %d: %s (resp=%d) -> theta=%.3f, SE=%.3f [%s]\n",
                i, item_id, resposta, 
                result$theta_atual, 
                result$se_atual,
                result$estado))
    
    if (result$estado == "FINALIZADO") {
      cat(sprintf("   → Finalizado: %s\n", result$motivo_parada))
      break
    }
  }
}

# 5.3 Obter resultado final
cat("\n   Obtendo resultado final...\n")
resp <- GET(paste0(BASE_URL, sprintf("/cat/sessao/%s/resultado", sessao_id)))

if (status_code(resp) == 200) {
  result <- fromJSON(content(resp, "text"))
  cat(sprintf("   ✓ Theta final: %.3f (SE=%.3f)\n", 
              result$resultado$theta_estimado,
              result$resultado$erro_padrao))
  cat(sprintf("   ✓ Nota escala 0-1000: %d (%s)\n",
              result$resultado$nota_escala_1000,
              result$resultado$classificacao))
  cat(sprintf("   ✓ Taxa de acerto: %.1f%%\n",
              result$estatisticas_sessao$taxa_acerto * 100))
  cat(sprintf("   ✓ Tempo total: %.1f minutos\n\n",
              result$estatisticas_sessao$tempo_total))
}

# 6. Testar Scoring com Regressão
cat("6. Testando Scoring com Ensemble TRI + Regressão\n")

# Respostas de teste
respostas_teste <- c(1, 1, 0, 1, 0, 1, 1, 0, 1, 1)
params_teste <- banco_itens[1:10, ]

# Modelo de regressão simples (simulado)
modelo_reg <- list(
  intercepto = 400,
  n_itens = 5,
  taxa_acerto = 200,
  tempo_medio = -0.5
)

dados_ctx <- list(
  n_itens = 10,
  taxa_acerto = mean(respostas_teste),
  tempo_medio = 60
)

resp <- post("/scoring/estimar", list(
  respostas = respostas_teste,
  parametros_itens = params_teste,
  dados_contexto = dados_ctx,
  modelo_regressao = modelo_reg
))

if (status_code(resp) == 200) {
  result <- fromJSON(content(resp, "text"))
  cat(sprintf("   ✓ Nota TRI: %d\n", result$estimativas$nota_apenas_tri))
  cat(sprintf("   ✓ Nota Regressão: %d\n", result$contribuicao_regressao$nota_regressao))
  cat(sprintf("   ✓ Nota Final (ensemble): %d\n", result$estimativas$nota_final))
  cat(sprintf("   ✓ Intervalo 95%%: [%d, %d]\n",
              result$intervalo_confianca$nota_ic95[1],
              result$intervalo_confianca$nota_ic95[2]))
  cat(sprintf("   ✓ Nível de confiança: %s\n\n", result$qualidade$nivel_confianca))
}

cat("=== Testes Concluídos ===\n")
cat("API v2 está funcionando corretamente!\n")
