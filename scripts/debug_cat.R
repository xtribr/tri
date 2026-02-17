#!/usr/bin/env Rscript
# Debug do algoritmo CAT

library(mirt)

cat("=== Debug do CAT ===\n\n")

# Carregar dados
load("tests/fixtures/dados-teste.RData")

# Usar apenas 3 itens para debug
a <- itens_params$a[1:3]
b <- itens_params$b[1:3]
c <- itens_params$c[1:3]

cat("Parâmetros dos itens:\n")
for (i in 1:3) {
  cat(sprintf("  Item %d: a=%.3f, b=%.3f, c=%.3f\n", i, a[i], b[i], c[i]))
}

# Simular respostas para theta = 1.5
theta_true <- 1.5
respostas <- c(1, 1, 0)  # Acertou Q1, Q2, errou Q3

cat(sprintf("\nTheta verdadeiro: %.2f\n", theta_true))
cat("Respostas simuladas:", respostas, "\n")

# Calcular EAP
theta_grid <- seq(-4, 4, length.out = 200)
prior <- dnorm(theta_grid, mean = 0, sd = 1)

likelihood <- rep(1, length(theta_grid))
for (i in 1:length(respostas)) {
  p <- c[i] + (1 - c[i]) / (1 + exp(-a[i] * (theta_grid - b[i])))
  likelihood_item <- ifelse(respostas[i] == 1, p, 1 - p)
  cat(sprintf("\nItem %d (b=%.3f):\n", i, b[i]))
  cat(sprintf("  P(acerto|theta=0) = %.3f\n", c[i] + (1 - c[i]) / (1 + exp(-a[i] * (0 - b[i])))))
  cat(sprintf("  P(acerto|theta=1.5) = %.3f\n", c[i] + (1 - c[i]) / (1 + exp(-a[i] * (1.5 - b[i])))))
  likelihood <- likelihood * likelihood_item
}

cat(sprintf("\nLikelihood em theta=0: %.6f\n", likelihood[101]))
cat(sprintf("Likelihood em theta=1.5: %.6f\n", approx(theta_grid, likelihood, 1.5)$y))

posterior <- likelihood * prior
total_posterior <- sum(posterior)

cat(sprintf("\nTotal posterior: %.6f\n", total_posterior))

if (total_posterior > 0) {
  posterior <- posterior / total_posterior
  theta_est <- sum(theta_grid * posterior)
  cat(sprintf("Theta estimado: %.4f\n", theta_est))
  
  # Plot da distribuição posterior
  cat("\nDistribuição posterior (amostra):\n")
  idx <- seq(1, length(theta_grid), by = 20)
  for (i in idx) {
    cat(sprintf("  theta=%.2f: posterior=%.6f\n", theta_grid[i], posterior[i]))
  }
}
