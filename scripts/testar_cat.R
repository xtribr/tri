#!/usr/bin/env Rscript
# Testar fluxo completo do CAT

library(httr)
library(jsonlite)

cat("=== Testando Fluxo CAT Completo ===\n\n")

# Carregar dados de teste
cat("Carregando dados de teste...\n")
load("tests/fixtures/dados-teste.RData")
cat(sprintf("✓ Banco de itens: %d itens\n\n", nrow(itens_params)))

# Iniciar servidor plumber em background
cat("Iniciando servidor plumber...\n")
system("pkill -f 'plumber.R' 2>/dev/null; sleep 1", ignore.stdout = TRUE, ignore.stderr = TRUE)

r_process <- parallel::mcparallel({
  plumber::plumb("R/api/plumber.R")$run(host = "127.0.0.1", port = 8000, quiet = TRUE)
})

Sys.sleep(3)

# Verificar servidor
tryCatch({
  resp <- GET("http://127.0.0.1:8000/health")
  if (status_code(resp) == 200) {
    cat("✓ Servidor respondendo\n\n")
  }
}, error = function(e) {
  Sys.sleep(2)
})

# Teste 1: Selecionar item inicial
cat("1. Testando seleção de item (MFI)...\n")
theta_inicial <- 0

payload_selecao <- list(
  theta_estimado = theta_inicial,
  itens_disponiveis = itens_params$item_id,
  parametros = itens_params,
  criterio = "MFI"
)

tryCatch({
  resp <- POST(
    url = "http://127.0.0.1:8000/cat/selecionar_item",
    body = toJSON(payload_selecao, auto_unbox = TRUE),
    encode = "json",
    content_type_json()
  )
  
  if (status_code(resp) == 200) {
    resultado <- fromJSON(content(resp, "text"))
    cat(sprintf("   ✓ Item selecionado: %s\n", resultado$item_selecionado))
    cat(sprintf("   ✓ Informação: %.4f\n\n", resultado$informacao))
  }
}, error = function(e) {
  cat(sprintf("   ✗ Erro: %s\n", e$message))
})

# Teste 2: Simular CAT completo com 5 itens
cat("2. Simulando CAT completo (5 itens)...\n")
theta_verdadeiro <- 1.5  # Simulado com habilidade acima da média

payload_cat <- list(
  theta_verdadeiro = theta_verdadeiro,
  n_itens = 5,
  parametros = itens_params
)

tryCatch({
  resp <- POST(
    url = "http://127.0.0.1:8000/cat/simular",
    body = toJSON(payload_cat, auto_unbox = TRUE),
    encode = "json",
    content_type_json()
  )
  
  if (status_code(resp) == 200) {
    resultado <- fromJSON(content(resp, "text"))
    
    cat(sprintf("   ✓ Theta verdadeiro: %.4f\n", resultado$theta_verdadeiro))
    cat(sprintf("   ✓ Theta estimado: %.4f\n", resultado$theta_estimado_final))
    cat(sprintf("   ✓ Erro padrão: %.4f\n", resultado$erro_padrao_final))
    cat(sprintf("   ✓ Itens aplicados: %d\n\n", resultado$n_itens_aplicados))
    
    cat("   Histórico do CAT:\n")
    cat(sprintf("   %-5s %-8s %-10s %-12s %-10s\n", "Passo", "Item", "Resposta", "Theta Est.", "SE"))
    cat(paste(rep("-", 55), collapse = ""), "\n")
    
    for (i in 1:nrow(resultado$historico)) {
      h <- resultado$historico[i, ]
      cat(sprintf("   %-5d %-8s %-10d %-12.4f %-10.4f\n", 
                  h$passo, h$item_id, h$resposta, h$theta_est, h$se))
    }
    
    # Análise de precisão
    erro <- abs(resultado$theta_verdadeiro - resultado$theta_estimado_final)
    cat("\n   Análise de Precisão:\n")
    cat(sprintf("   - Erro absoluto: %.4f\n", erro))
    cat(sprintf("   - Precisão (1/SE²): %.2f\n", 1/(resultado$erro_padrao_final^2)))
    
    if (erro < 0.5) {
      cat("   ✓ Estimativa precisa (erro < 0.5)\n")
    } else if (erro < 1.0) {
      cat("   ~ Estimativa razoável (erro < 1.0)\n")
    } else {
      cat("   ✗ Estimativa imprecisa\n")
    }
  }
}, error = function(e) {
  cat(sprintf("   ✗ Erro: %s\n", e$message))
})

# Teste 3: Múltiplas simulações com diferentes thetas
cat("\n3. Testando múltiplos níveis de habilidade...\n")
thetas_teste <- c(-2, -1, 0, 1, 2)
resultados <- data.frame(
  theta_verdadeiro = numeric(),
  theta_estimado = numeric(),
  erro = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (tv in thetas_teste) {
  payload <- list(
    theta_verdadeiro = tv,
    n_itens = 5,
    parametros = itens_params
  )
  
  tryCatch({
    resp <- POST(
      url = "http://127.0.0.1:8000/cat/simular",
      body = toJSON(payload, auto_unbox = TRUE),
      encode = "json",
      content_type_json()
    )
    
    if (status_code(resp) == 200) {
      r <- fromJSON(content(resp, "text"))
      resultados <- rbind(resultados, data.frame(
        theta_verdadeiro = tv,
        theta_estimado = r$theta_estimado_final,
        erro = abs(tv - r$theta_estimado_final),
        se = r$erro_padrao_final
      ))
    }
  }, error = function(e) {
    NULL
  })
}

cat(sprintf("   %-8s %-12s %-10s %-10s\n", "Verdadeiro", "Estimado", "Erro", "SE"))
cat(paste(rep("-", 45), collapse = ""), "\n")
for (i in 1:nrow(resultados)) {
  cat(sprintf("   %-8.2f %-12.4f %-10.4f %-10.4f\n", 
              resultados$theta_verdadeiro[i],
              resultados$theta_estimado[i],
              resultados$erro[i],
              resultados$se[i]))
}

cat(sprintf("\n   Erro médio absoluto: %.4f\n", mean(resultados$erro)))
cat(sprintf("   Correlação (verdadeiro vs estimado): %.4f\n", 
            cor(resultados$theta_verdadeiro, resultados$theta_estimado)))

# Encerrar servidor
cat("\nEncerrando servidor...\n")
tools::pskill(r_process$pid)
cat("✓ Teste CAT concluído\n")
