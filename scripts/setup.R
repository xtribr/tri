#!/usr/bin/env Rscript
# Script de setup e verificação do ambiente TRI

cat("=== Setup do Ambiente TRI ===\n\n")

# Verificar pacotes necessários
pacotes <- c("mirt", "plumber", "DBI", "RPostgres", "jsonlite", "dplyr")
cat("Verificando pacotes instalados:\n")

for (pkg in pacotes) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("  ✓ %s %s\n", pkg, packageVersion(pkg)))
  } else {
    cat(sprintf("  ✗ %s - NÃO INSTALADO\n", pkg))
  }
}

cat("\n=== Testando mirt com modelo simples ===\n")

# Teste básico do mirt
set.seed(42)
n_respondentes <- 100
n_itens <- 10

# Gerar dados binários simulados
dados <- matrix(sample(0:1, n_respondentes * n_itens, replace = TRUE), 
                nrow = n_respondentes, ncol = n_itens)
colnames(dados) <- paste0("Q", 1:n_itens)

cat(sprintf("Dados simulados: %d respondentes x %d itens\n", n_respondentes, n_itens))

# Ajustar modelo Rasch 1PL
resultado <- tryCatch({
  modelo <- mirt(dados, model = 1, itemtype = "Rasch", verbose = FALSE)
  cat("✓ Modelo Rasch ajustado com sucesso\n")
  
  # Extrair parâmetros
  params <- coef(modelo, simplify = TRUE)
  cat(sprintf("  - Dificuldade média: %.3f\n", mean(params$items[,2])))
  cat(sprintf("  - Log-likelihood: %.2f\n", modelo@Fit$logLik))
  
  cat("\n✓ Ambiente TRI configurado corretamente!\n")
  0
}, error = function(e) {
  cat(sprintf("✗ Erro ao ajustar modelo: %s\n", e$message))
  1
})

quit(status = resultado)
