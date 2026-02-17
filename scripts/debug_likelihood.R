#!/usr/bin/env Rscript
# Debug do cálculo do likelihood

cat("=== Debug do Likelihood ===\n\n")

# Caso simples: 1 item, 1 resposta
a <- 1.5
b <- 1.0  # Item difícil
c <- 0
resp <- 1  # Acertou

theta_grid <- seq(-3, 3, by = 0.5)

cat("Item: a=1.5, b=1.0 (difícil), resposta=1 (acerto)\n\n")
cat(sprintf("%-8s %-12s %-12s\n", "Theta", "P(acerto)", "Likelihood"))
cat(paste(rep("-", 35), collapse = ""), "\n")

for (th in theta_grid) {
  p <- c + (1 - c) / (1 + exp(-a * (th - b)))
  li <- ifelse(resp == 1, p, 1 - p)
  cat(sprintf("%-8.2f %-12.6f %-12.6f\n", th, p, li))
}

# Agora com 2 itens
cat("\n\n=== Com 2 itens ===\n")
a <- c(1.5, 1.5)
b <- c(-1.0, 1.0)  # Um fácil, um difícil
c <- c(0, 0)
resp <- c(1, 1)  # Acertou ambos

cat("Itens: (a=1.5, b=-1.0) e (a=1.5, b=1.0)\n")
cat("Respostas: 1, 1 (acertou ambos)\n\n")

cat(sprintf("%-8s %-12s %-12s %-12s\n", "Theta", "L1", "L2", "L_total"))
cat(paste(rep("-", 50), collapse = ""), "\n")

for (th in theta_grid) {
  l_total <- 1
  l_vals <- numeric(length(a))
  for (i in 1:length(a)) {
    p <- c[i] + (1 - c[i]) / (1 + exp(-a[i] * (th - b[i])))
    l_vals[i] <- ifelse(resp[i] == 1, p, 1 - p)
    l_total <- l_total * l_vals[i]
  }
  cat(sprintf("%-8.2f %-12.6f %-12.6f %-12.6f\n", th, l_vals[1], l_vals[2], l_total))
}

# Verificar simetria
cat("\nVerificando simetria:\n")
th <- 2
p_pos <- 1 / (1 + exp(-1.5 * (th - 1)))
p_neg <- 1 / (1 + exp(-1.5 * ((-th) - 1)))
cat(sprintf("P(acerto|theta=2) = %.6f\n", p_pos))
cat(sprintf("P(acerto|theta=-2) = %.6f (para item com b=-1)\n", p_neg))

# O problema: quando acerta item fácil e difícil, o likelihood pode ser simétrico!
cat("\n=== Problema identificado ===\n")
cat("Quando o respondente acerta itens tanto abaixo quanto acima de seu theta,\n")
cat("o likelihood pode ficar simétrico em torno de 0.\n")
cat("Isso acontece especialmente com poucos itens.\n")
