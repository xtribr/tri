#!/usr/bin/env Rscript
# Debug passo a passo do CAT

library(mirt)

cat("=== Debug Detalhado do CAT ===\n\n")

load("tests/fixtures/dados-teste.RData")

# Usar apenas 5 itens para debug
n_itens_debug <- 5
a <- itens_params$a[1:n_itens_debug]
b <- itens_params$b[1:n_itens_debug]
c <- itens_params$c[1:n_itens_debug]
item_ids <- itens_params$item_id[1:n_itens_debug]

cat("Parâmetros dos itens:\n")
for (i in 1:n_itens_debug) {
  cat(sprintf("  %s: a=%.3f, b=%.3f, c=%.3f\n", item_ids[i], a[i], b[i], c[i]))
}

theta_true <- 1.5
theta_est <- 0
respostas <- numeric(n_itens_debug)
respostas[] <- NA

cat(sprintf("\nTheta verdadeiro: %.2f\n\n", theta_true))

for (passo in 1:3) {
  cat(sprintf("=== Passo %d ===\n", passo))
  
  # Selecionar item
  disponiveis <- item_ids[is.na(respostas)]
  idx_disp <- which(is.na(respostas))
  
  cat(sprintf("Theta atual: %.4f\n", theta_est))
  cat(sprintf("Itens disponíveis: %s\n", paste(disponiveis, collapse = ", ")))
  
  # Calcular informação
  p_info <- c[idx_disp] + (1 - c[idx_disp]) / (1 + exp(-a[idx_disp] * (theta_est - b[idx_disp])))
  q_info <- 1 - p_info
  info <- (a[idx_disp]^2 * (q_info / p_info) * ((p_info - c[idx_disp]) / (1 - c[idx_disp]))^2)
  
  cat(sprintf("Informação dos itens disponíveis:\n"))
  for (i in 1:length(idx_disp)) {
    cat(sprintf("  %s: info=%.4f\n", item_ids[idx_disp[i]], info[i]))
  }
  
  melhor_idx <- idx_disp[which.max(info)]
  item_sel <- item_ids[melhor_idx]
  cat(sprintf("Item selecionado: %s (b=%.3f)\n", item_sel, b[melhor_idx]))
  
  # Simular resposta
  p_resp <- c[melhor_idx] + (1 - c[melhor_idx]) / (1 + exp(-a[melhor_idx] * (theta_true - b[melhor_idx])))
  resp <- ifelse(runif(1) < p_resp, 1, 0)
  cat(sprintf("P(acerto) = %.4f, Resposta = %d\n", p_resp, resp))
  
  respostas[melhor_idx] <- resp
  
  # EAP
  theta_grid <- seq(-4, 4, length.out = 200)
  prior <- dnorm(theta_grid)
  
  likelihood <- rep(1, length(theta_grid))
  for (i in which(!is.na(respostas))) {
    p <- c[i] + (1 - c[i]) / (1 + exp(-a[i] * (theta_grid - b[i])))
    li <- ifelse(respostas[i] == 1, p, 1 - p)
    cat(sprintf("  Item %s (b=%.3f, resp=%d): L(theta=0)=%.6f, L(theta=1.5)=%.6f\n",
                item_ids[i], b[i], respostas[i], 
                li[which.min(abs(theta_grid - 0))],
                li[which.min(abs(theta_grid - 1.5))]))
    likelihood <- likelihood * li
  }
  
  cat(sprintf("Likelihood combinada: L(0)=%.6f, L(1.5)=%.6f\n",
              likelihood[which.min(abs(theta_grid - 0))],
              likelihood[which.min(abs(theta_grid - 1.5))]))
  
  posterior <- likelihood * prior
  total_posterior <- sum(posterior)
  cat(sprintf("Total posterior: %.6f\n", total_posterior))
  
  if (total_posterior > 0 && !is.na(total_posterior)) {
    posterior <- posterior / total_posterior
    theta_est <- sum(theta_grid * posterior)
    cat(sprintf("Novo theta estimado: %.4f\n", theta_est))
    
    # Verificar se há problema de precisão numérica
    cat(sprintf("Max posterior: %.6f em theta=%.2f\n", 
                max(posterior), theta_grid[which.max(posterior)]))
  }
  
  cat("\n")
}
