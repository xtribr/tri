#!/usr/bin/env Rscript
# Teste simplificado do CAT

library(mirt)
library(jsonlite)

cat("=== Teste Direto do Algoritmo CAT ===\n\n")

# Carregar dados
load("tests/fixtures/dados-teste.RData")

# Simular CAT manualmente
theta_true <- 1.5
n_itens <- 5

a <- itens_params$a
b <- itens_params$b
c <- itens_params$c
item_ids <- itens_params$item_id

theta_est <- 0
respostas <- numeric(length(item_ids))
respostas[] <- NA
itens_aplicados <- character()

cat(sprintf("Theta verdadeiro: %.2f\n\n", theta_true))
cat("Simulação passo a passo:\n")

for (passo in 1:n_itens) {
  # Selecionar item
  disponiveis <- setdiff(item_ids, itens_aplicados)
  idx_disp <- which(item_ids %in% disponiveis)
  
  # Calcular informação
  p_info <- c[idx_disp] + (1 - c[idx_disp]) / (1 + exp(-a[idx_disp] * (theta_est - b[idx_disp])))
  q_info <- 1 - p_info
  info <- (a[idx_disp]^2 * (q_info / p_info) * ((p_info - c[idx_disp]) / (1 - c[idx_disp]))^2)
  melhor_idx <- idx_disp[which.max(info)]
  item_sel <- item_ids[melhor_idx]
  
  # Simular resposta
  p_resp <- c[melhor_idx] + (1 - c[melhor_idx]) / (1 + exp(-a[melhor_idx] * (theta_true - b[melhor_idx])))
  resp <- ifelse(runif(1) < p_resp, 1, 0)
  
  respostas[melhor_idx] <- resp
  itens_aplicados <- c(itens_aplicados, item_sel)
  
  # Estimar theta via EAP
  theta_grid <- seq(-4, 4, length.out = 200)
  prior <- dnorm(theta_grid, mean = 0, sd = 1)
  
  likelihood <- rep(1, length(theta_grid))
  for (i in which(!is.na(respostas))) {
    p <- c[i] + (1 - c[i]) / (1 + exp(-a[i] * (theta_grid - b[i])))
    likelihood <- likelihood * ifelse(respostas[i] == 1, p, 1 - p)
  }
  
  posterior <- likelihood * prior
  total_posterior <- sum(posterior)
  
  cat(sprintf("Passo %d: Item=%s, Resp=%d, ", passo, item_sel, resp))
  
  if (total_posterior > 0 && !is.na(total_posterior)) {
    posterior <- posterior / total_posterior
    theta_est <- sum(theta_grid * posterior)
    theta_var <- sum((theta_grid - theta_est)^2 * posterior)
    theta_se <- sqrt(max(theta_var, 0.001))
    cat(sprintf("Theta=%.4f, SE=%.4f\n", theta_est, theta_se))
  } else {
    cat("ERRO: Posterior inválido\n")
  }
}

cat(sprintf("\nResultado final:\n"))
cat(sprintf("  Theta verdadeiro: %.4f\n", theta_true))
cat(sprintf("  Theta estimado:   %.4f\n", theta_est))
cat(sprintf("  Erro:             %.4f\n", abs(theta_true - theta_est)))
