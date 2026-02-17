#!/usr/bin/env Rscript
# Debug final do problema

cat("=== Debug Final ===\n\n")

# Teste simples: 1 item
a <- 1.0
b <- 0.5
c <- 0
resp <- 1

theta_grid <- seq(-4, 4, length.out = 200)
p <- c + (1 - c) / (1 + exp(-a * (theta_grid - b)))
li <- ifelse(resp == 1, p, 1 - p)

cat("Teste com 1 item (a=1, b=0.5, resp=1):\n")
cat(sprintf("L(theta=0) = %.6f\n", li[which.min(abs(theta_grid - 0))]))
cat(sprintf("L(theta=1) = %.6f\n", li[which.min(abs(theta_grid - 1))]))
cat(sprintf("L(theta=2) = %.6f\n", li[which.min(abs(theta_grid - 2))]))

# Verificar se o problema é na indexação
cat("\nVerificação da indexação:\n")
cat(sprintf("theta_grid[101] = %.4f (deveria ser ~0)\n", theta_grid[101]))
cat(sprintf("theta_grid[which.min(abs(theta_grid - 0))] = %.4f\n", 
            theta_grid[which.min(abs(theta_grid - 0))]))

# Agora testar com dados reais
load("tests/fixtures/dados-teste.RData")

cat("\n\nTeste com dados reais (primeiro item):\n")
a <- itens_params$a[1]
b <- itens_params$b[1]
c <- itens_params$c[1]

cat(sprintf("Item Q1: a=%.3f, b=%.3f, c=%.3f\n", a, b, c))

p <- c + (1 - c) / (1 + exp(-a * (theta_grid - b)))
li_1 <- ifelse(1 == 1, p, 1 - p)  # Acertou
li_0 <- ifelse(0 == 1, p, 1 - p)  # Errou

cat("Se acertou:\n")
cat(sprintf("  L(theta=-2) = %.6f\n", li_1[which.min(abs(theta_grid - (-2)))]))
cat(sprintf("  L(theta=0) = %.6f\n", li_1[which.min(abs(theta_grid - 0))]))
cat(sprintf("  L(theta=2) = %.6f\n", li_1[which.min(abs(theta_grid - 2))]))

cat("Se errou:\n")
cat(sprintf("  L(theta=-2) = %.6f\n", li_0[which.min(abs(theta_grid - (-2)))]))
cat(sprintf("  L(theta=0) = %.6f\n", li_0[which.min(abs(theta_grid - 0))]))
cat(sprintf("  L(theta=2) = %.6f\n", li_0[which.min(abs(theta_grid - 2))]))

# O problema: quando b é muito negativo (item fácil), acertar não discrimina!
# E quando b é muito positivo (item difícil), errar também não discrimina!

cat("\n=== Conclusão ===\n")
cat("O problema é que o banco de itens tem itens muito fáceis (b<-2) e\n")
cat("muito difíceis (b>2). Quando o CAT seleciona esses itens para um\n")
cat("respondente com theta médio, as respostas não são informativas:\n")
cat("- Item fácil: todo mundo acerta, não discrimina\n")
cat("- Item difícil: todo mundo erra, não discrimina\n")
cat("\nSolução: O CAT precisa selecionar itens PRÓXIMOS ao theta estimado.\n")
