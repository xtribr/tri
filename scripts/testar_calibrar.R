#!/usr/bin/env Rscript
# Testar endpoint /calibrar

library(httr)
library(jsonlite)
library(mirt)

cat("=== Testando Endpoint /calibrar ===\n\n")

# Carregar dados de teste
cat("Carregando dados de teste...\n")
load("tests/fixtures/dados-teste.RData")
cat(sprintf("✓ Dados carregados: %d respondentes x %d itens\n\n", 
            nrow(respostas), ncol(respostas)))

# Iniciar servidor plumber em background
cat("Iniciando servidor plumber...\n")
system("pkill -f 'plumber.R' 2>/dev/null; sleep 1", ignore.stdout = TRUE, ignore.stderr = TRUE)

# Iniciar servidor em background
r_process <- parallel::mcparallel({
  plumber::plumb("R/api/plumber.R")$run(host = "127.0.0.1", port = 8000, quiet = TRUE)
})

# Aguardar servidor iniciar
Sys.sleep(3)

# Testar health check
cat("Verificando health check...\n")
tryCatch({
  resp <- GET("http://127.0.0.1:8000/health")
  if (status_code(resp) == 200) {
    cat("✓ Servidor respondendo\n\n")
  }
}, error = function(e) {
  cat("✗ Servidor não respondeu, tentando novamente...\n")
  Sys.sleep(2)
})

# Testar /calibrar com modelo 2PL
cat("Testando /calibrar com modelo 2PL...\n")

# Usar subconjunto dos dados para teste rápido
set.seed(42)
subset_idx <- sample(1:nrow(respostas), 200)
dados_teste <- respostas[subset_idx, 1:20]  # 200 respondentes, 20 itens

# Preparar payload
payload <- list(
  dados = as.data.frame(dados_teste),
  modelo = "2PL"
)

# Fazer requisição
tryCatch({
  resp <- POST(
    url = "http://127.0.0.1:8000/calibrar",
    body = toJSON(payload, auto_unbox = TRUE, dataframe = "rows"),
    encode = "json",
    content_type_json()
  )
  
  if (status_code(resp) == 200) {
    resultado <- fromJSON(content(resp, "text"))
    
    cat("✓ Calibração concluída com sucesso!\n\n")
    cat("Resultados:\n")
    cat(sprintf("  Modelo: %s\n", resultado$modelo))
    cat(sprintf("  Respondentes: %d\n", resultado$n_respondentes))
    cat(sprintf("  Itens: %d\n", resultado$n_itens))
    cat(sprintf("  Log-likelihood: %.2f\n", resultado$ajuste$logLik))
    cat(sprintf("  AIC: %.2f\n", resultado$ajuste$AIC))
    cat(sprintf("  BIC: %.2f\n", resultado$ajuste$BIC))
    
    cat("\nParâmetros estimados (primeiros 5 itens):\n")
    params <- resultado$parametros
    for (i in 1:min(5, nrow(params))) {
      cat(sprintf("  %s: a=%.3f, b=%.3f, c=%.3f\n", 
                  params$item_id[i], params$a[i], params$b[i], params$c[i]))
    }
    
    # Comparar com parâmetros verdadeiros
    cat("\nComparação com parâmetros verdadeiros:\n")
    cat(sprintf("  Dificuldade estimada: M=%.3f, SD=%.3f\n", 
                mean(params$b), sd(params$b)))
    cat(sprintf("  Dificuldade verdadeira: M=%.3f, SD=%.3f\n", 
                mean(itens_params$b[1:20]), sd(itens_params$b[1:20])))
    
  } else {
    cat(sprintf("✗ Erro HTTP %d\n", status_code(resp)))
    cat(content(resp, "text"))
  }
  
}, error = function(e) {
  cat(sprintf("✗ Erro na requisição: %s\n", e$message))
})

# Encerrar servidor
cat("\nEncerrando servidor...\n")
tools::pskill(r_process$pid)
cat("✓ Teste concluído\n")
