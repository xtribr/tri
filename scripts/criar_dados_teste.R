#!/usr/bin/env Rscript
# Criar dados de teste para o projeto TRI

library(mirt)

set.seed(123)

cat("=== Criando Dados de Teste ===\n\n")

# Configuração
n_respondentes <- 1000
n_itens <- 50

# Gerar parâmetros de itens reais (modelo 2PL)
cat(sprintf("Gerando %d itens com parâmetros realistas...\n", n_itens))

# a (discriminação): valores entre 0.5 e 2
a <- runif(n_itens, 0.5, 2.0)

# b (dificuldade): valores entre -3 e 3 (distribuição normal)
b <- rnorm(n_itens, 0, 1.5)
b <- pmin(pmax(b, -3), 3)  # Limitar entre -3 e 3

# c (pseudo-chute): valores entre 0 e 0.25
c <- runif(n_itens, 0, 0.25)

# Criar matriz de parâmetros
itens_params <- data.frame(
  item_id = paste0("Q", 1:n_itens),
  a = a,
  b = b,
  c = c,
  stringsAsFactors = FALSE
)

cat(sprintf("  - Dificuldade média: %.3f (SD: %.3f)\n", mean(b), sd(b)))
cat(sprintf("  - Discriminação média: %.3f (SD: %.3f)\n", mean(a), sd(a)))

# Gerar habilidades dos respondentes (theta)
theta <- rnorm(n_respondentes, 0, 1)
cat(sprintf("\nGerando %d respondentes...\n", n_respondentes))
cat(sprintf("  - Theta médio: %.3f (SD: %.3f)\n", mean(theta), sd(theta)))

# Simular respostas usando o modelo 2PL
cat("\nSimulando respostas...\n")

# Função de probabilidade do modelo 2PL
prob_2pl <- function(theta, a, b, c) {
  c + (1 - c) / (1 + exp(-a * (theta - b)))
}

# Gerar matriz de respostas
respostas <- matrix(0, nrow = n_respondentes, ncol = n_itens)
for (i in 1:n_respondentes) {
  for (j in 1:n_itens) {
    p <- prob_2pl(theta[i], a[j], b[j], c[j])
    respostas[i, j] <- ifelse(runif(1) < p, 1, 0)
  }
}

colnames(respostas) <- itens_params$item_id

# Calcular estatísticas descritivas
 taxa_acerto <- colMeans(respostas)
cat(sprintf("  - Taxa de acerto média: %.1f%%\n", mean(taxa_acerto) * 100))
cat(sprintf("  - Score médio: %.1f%%\n", mean(rowSums(respostas) / n_itens) * 100))

# Criar dados de gabarito
gabarito <- data.frame(
  item_id = itens_params$item_id,
  resposta_correta = sample(LETTERS[1:5], n_itens, replace = TRUE),
  stringsAsFactors = FALSE
)

# Salvar dados
cat("\n=== Salvando Dados ===\n")

# Criar diretório se não existir
dir.create("tests/fixtures", showWarnings = FALSE, recursive = TRUE)

# Salvar em formato RData
save(itens_params, respostas, theta, gabarito, 
     file = "tests/fixtures/dados-teste.RData")
cat("✓ Dados salvos em: tests/fixtures/dados-teste.RData\n")

# Também salvar em CSV para fácil inspeção
write.csv(respostas, "tests/fixtures/respostas_teste.csv", row.names = FALSE)
write.csv(itens_params, "tests/fixtures/parametros_itens.csv", row.names = FALSE)
write.csv(gabarito, "tests/fixtures/gabarito.csv", row.names = FALSE)
cat("✓ CSVs salvos em: tests/fixtures/\n")

# Resumo
cat("\n=== Resumo dos Dados de Teste ===\n")
cat(sprintf("Respondentes: %d\n", n_respondentes))
cat(sprintf("Itens: %d\n", n_itens))
cat(sprintf("  - Dificuldade: %.2f a %.2f\n", min(b), max(b)))
cat(sprintf("  - Discriminação: %.2f a %.2f\n", min(a), max(a)))
cat(sprintf("  - Pseudo-chute: %.2f a %.2f\n", min(c), max(c)))

cat("\n✓ Dados de teste criados com sucesso!\n")
