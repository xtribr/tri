#!/usr/bin/env Rscript
# Teste final da API com verificações detalhadas

library(httr)
library(jsonlite)

cat("=== Teste Final da API ===\n\n")

# Carregar dados
load("tests/fixtures/dados-teste.RData")

# Iniciar servidor
cat("Iniciando servidor...\n")
system("pkill -f 'plumber.R' 2>/dev/null; sleep 1", ignore.stdout = TRUE, ignore.stderr = TRUE)
r_process <- parallel::mcparallel({
  plumber::plumb("R/api/plumber.R")$run(host = "127.0.0.1", port = 8000, quiet = TRUE)
})
Sys.sleep(3)

# Testar endpoint /cat/simular diretamente
cat("Testando /cat/simular...\n")

# Preparar payload - garantir que os dados estão no formato correto
payload <- list(
  theta_verdadeiro = 1.5,
  n_itens = 5,
  parametros = list(
    item_id = itens_params$item_id,
    a = as.numeric(itens_params$a),
    b = as.numeric(itens_params$b),
    c = as.numeric(itens_params$c)
  )
)

# Verificar payload
cat("Payload preparado:\n")
cat(sprintf("  theta_verdadeiro: %.2f\n", payload$theta_verdadeiro))
cat(sprintf("  n_itens: %d\n", payload$n_itens))
cat(sprintf("  n_parametros: %d\n", length(payload$parametros$a)))

tryCatch({
  resp <- POST(
    url = "http://127.0.0.1:8000/cat/simular",
    body = toJSON(payload, auto_unbox = TRUE, digits = 6),
    encode = "json",
    content_type_json()
  )
  
  cat(sprintf("\nStatus: %d\n", status_code(resp)))
  
  if (status_code(resp) == 200) {
    resultado <- fromJSON(content(resp, "text"))
    
    if (resultado$sucesso) {
      cat(sprintf("Theta verdadeiro: %.4f\n", resultado$theta_verdadeiro))
      cat(sprintf("Theta estimado: %.4f\n", resultado$theta_estimado_final))
      cat(sprintf("Erro: %.4f\n", abs(resultado$theta_verdadeiro - resultado$theta_estimado_final)))
      cat(sprintf("SE: %.4f\n", resultado$erro_padrao_final))
      
      cat("\nHistórico:\n")
      print(resultado$historico)
      
      if (abs(resultado$theta_estimado_final) < 0.01) {
        cat("\n⚠️  ATENÇÃO: Theta estimado está em 0, indicando problema!\n")
      } else {
        cat("\n✓ CAT funcionando corretamente!\n")
      }
    } else {
      cat(sprintf("Erro: %s\n", resultado$error))
    }
  } else {
    cat(sprintf("Erro HTTP %d\n", status_code(resp)))
    cat(content(resp, "text"))
  }
}, error = function(e) {
  cat(sprintf("Erro: %s\n", e$message))
})

# Encerrar servidor
cat("\nEncerrando servidor...\n")
tools::pskill(r_process$pid)
