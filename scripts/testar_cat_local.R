#!/usr/bin/env Rscript
# Teste local do CAT sem API para isolar o problema

cat("=== Teste Local do CAT (sem API) ===\n\n")

load("tests/fixtures/dados-teste.RData")

# Simular exatamente o que a API faz
theta_true <- 1.5
n <- 5

a <- itens_params$a
b <- itens_params$b
c <- itens_params$c
item_ids <- itens_params$item_id

cat(sprintf("Dados carregados: %d itens\n", length(item_ids)))
cat(sprintf("Theta verdadeiro: %.2f\n", theta_true))
cat(sprintf("N itens a aplicar: %d\n\n", n))

# Inicializar
theta_est <- 0
respostas <- numeric(length(item_ids))
respostas[] <- NA
itens_aplicados <- character()

set.seed(42)  # Para reprodutibilidade

for (passo in 1:n) {
  cat(sprintf("=== Passo %d ===\n", passo))
  
  disponiveis <- setdiff(item_ids, itens_aplicados)
  idx_disp <- which(item_ids %in% disponiveis)
  
  cat(sprintf("Theta atual: %.4f\n", theta_est))
  cat(sprintf("Itens disponíveis: %d\n", length(disponiveis)))
  
  # Calcular informação
  p_info <- c[idx_disp] + (1 - c[idx_disp]) / (1 + exp(-a[idx_disp] * (theta_est - b[idx_disp])))
  q_info <- 1 - p_info
  info <- (a[idx_disp]^2 * (q_info / p_info) * ((p_info - c[idx_disp]) / (1 - c[idx_disp]))^2)
  
  melhor_idx <- idx_disp[which.max(info)]
  item_sel <- item_ids[melhor_idx]
  
  cat(sprintf("Item selecionado: %s (b=%.3f, info=%.4f)\n", 
              item_sel, b[melhor_idx], max(info)))
  
  # Simular resposta
  p_resp <- c[melhor_idx] + (1 - c[melhor_idx]) / (1 + exp(-a[melhor_idx] * (theta_true - b[melhor_idx])))
  resp <- ifelse(runif(1) < p_resp, 1, 0)
  
  cat(sprintf("P(acerto) = %.4f, Resposta = %d\n", p_resp, resp))
  
  respostas[melhor_idx] <- resp
  itens_aplicados <- c(itens_aplicados, item_sel)
  
  # EAP
  theta_grid <- seq(-4, 4, length.out = 200)
  prior <- dnorm(theta_grid, mean = 0, sd = 1)
  
  likelihood <- rep(1, length(theta_grid))
  for (i in which(!is.na(respostas))) {
    p <- c[i] + (1 - c[i]) / (1 + exp(-a[i] * (theta_grid - b[i])))
    li <- ifelse(respostas[i] == 1, p, 1 - p)
    likelihood <- likelihood * li
  }
  
  cat(sprintf("Likelihood range: [%.6f, %.6f]\n", min(likelihood), max(likelihood)))
  
  posterior <- likelihood * prior
  total_posterior <- sum(posterior)
  
  cat(sprintf("Total posterior: %.6f\n", total_posterior))
  
  if (total_posterior == 0 || is.na(total_posterior)) {
    cat("AVISO: Posterior inválido, mantendo theta anterior\n")
    theta_se <- 1
  } else {
    posterior <- posterior / total_posterior
    theta_est <- sum(theta_grid * posterior)
    theta_var <- sum((theta_grid - theta_est)^2 * posterior)
    theta_se <- sqrt(max(theta_var, 0.001))
    cat(sprintf("Novo theta: %.4f, SE: %.4f\n", theta_est, theta_se))
  }
  
  cat("\n")
}

cat("=== Resultado Final ===\n")
cat(sprintf("Theta verdadeiro: %.4f\n", theta_true))
cat(sprintf("Theta estimado: %.4f\n", theta_est))
cat(sprintf("Erro: %.4f\n", abs(theta_true - theta_est)))
