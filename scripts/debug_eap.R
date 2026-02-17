#!/usr/bin/env Rscript
# Debug detalhado do EAP

cat("=== Debug do EAP ===\n\n")

# Parâmetros de 3 itens
a <- c(1.5, 1.5, 1.5)
b <- c(-1, 0, 1)
c <- c(0, 0, 0)

# Respostas: acertou fácil, errou médio, errou difícil
respostas <- c(1, 0, 0)

cat("Configuração:\n")
for (i in 1:3) {
  cat(sprintf("  Item %d: a=%.1f, b=%.1f, resposta=%d\n", i, a[i], b[i], respostas[i]))
}

# Calcular likelihood em diferentes thetas
theta_grid <- seq(-3, 3, length.out = 100)
likelihood <- rep(1, length(theta_grid))

for (i in 1:length(respostas)) {
  p <- 1 / (1 + exp(-a[i] * (theta_grid - b[i])))
  li <- ifelse(respostas[i] == 1, p, 1 - p)
  likelihood <- likelihood * li
}

prior <- dnorm(theta_grid)
posterior <- likelihood * prior
posterior <- posterior / sum(posterior)

theta_est <- sum(theta_grid * posterior)

cat(sprintf("\nTheta estimado: %.4f\n", theta_est))

# Mostrar alguns pontos
cat("\nPontos chave:\n")
for (th in c(-2, -1, 0, 1, 2)) {
  idx <- which.min(abs(theta_grid - th))
  cat(sprintf("  theta=%.1f: L=%.6f, prior=%.6f, post=%.6f\n",
              th, likelihood[idx], prior[idx], posterior[idx]))
}

# Verificar se há simetria
cat("\nVerificando simetria do likelihood em torno de 0:\n")
cat(sprintf("  L(-1) = %.6f, L(1) = %.6f\n", 
            likelihood[which.min(abs(theta_grid - (-1)))],
            likelihood[which.min(abs(theta_grid - 1))]))
cat(sprintf("  L(-2) = %.6f, L(2) = %.6f\n",
            likelihood[which.min(abs(theta_grid - (-2)))],
            likelihood[which.min(abs(theta_grid - 2))]))
