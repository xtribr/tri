#!/usr/bin/env Rscript
# Teste do CAT com padrão de respostas mais informativo

library(mirt)

cat("=== Teste CAT com Padrão Informativo ===\n\n")

load("tests/fixtures/dados-teste.RData")

# Função para simular CAT com log de debug
simular_cat_debug <- function(theta_true, n_itens, itens_params, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  a <- itens_params$a
  b <- itens_params$b
  c <- itens_params$c
  item_ids <- itens_params$item_id
  
  theta_est <- 0
  respostas <- numeric(length(item_ids))
  respostas[] <- NA
  itens_aplicados <- character()
  
  cat(sprintf("Theta verdadeiro: %.2f\n\n", theta_true))
  cat("Passo a passo:\n")
  cat(sprintf("%-5s %-6s %-8s %-10s %-10s %-10s\n", 
              "Passo", "Item", "b", "Resp", "Theta", "SE"))
  cat(paste(rep("-", 55), collapse = ""), "\n")
  
  for (passo in 1:n_itens) {
    disponiveis <- setdiff(item_ids, itens_aplicados)
    idx_disp <- which(item_ids %in% disponiveis)
    
    # MFI
    p_info <- c[idx_disp] + (1 - c[idx_disp]) / (1 + exp(-a[idx_disp] * (theta_est - b[idx_disp])))
    q_info <- 1 - p_info
    info <- (a[idx_disp]^2 * (q_info / p_info) * ((p_info - c[idx_disp]) / (1 - c[idx_disp]))^2)
    melhor_idx <- idx_disp[which.max(info)]
    item_sel <- item_ids[melhor_idx]
    b_item <- b[melhor_idx]
    
    # Simular resposta
    p_resp <- c[melhor_idx] + (1 - c[melhor_idx]) / (1 + exp(-a[melhor_idx] * (theta_true - b[melhor_idx])))
    resp <- ifelse(runif(1) < p_resp, 1, 0)
    
    respostas[melhor_idx] <- resp
    itens_aplicados <- c(itens_aplicados, item_sel)
    
    # EAP com grid mais fino
    theta_grid <- seq(-4, 4, length.out = 1000)
    prior <- dnorm(theta_grid, mean = 0, sd = 1)
    
    likelihood <- rep(1, length(theta_grid))
    for (i in which(!is.na(respostas))) {
      p <- c[i] + (1 - c[i]) / (1 + exp(-a[i] * (theta_grid - b[i])))
      likelihood <- likelihood * ifelse(respostas[i] == 1, p, 1 - p)
    }
    
    posterior <- likelihood * prior
    total_posterior <- sum(posterior)
    
    if (total_posterior > 0 && !is.na(total_posterior)) {
      posterior <- posterior / total_posterior
      theta_est <- sum(theta_grid * posterior)
      theta_var <- sum((theta_grid - theta_est)^2 * posterior)
      theta_se <- sqrt(max(theta_var, 0.0001))
    }
    
    cat(sprintf("%-5d %-6s %-8.3f %-10d %-10.4f %-10.4f\n",
                passo, item_sel, b_item, resp, theta_est, theta_se))
  }
  
  cat("\n")
  list(theta_est = theta_est, se = theta_se, respostas = respostas, itens_aplicados = itens_aplicados)
}

# Teste 1: Theta alto (2.0) - deve acertar a maioria
cat("=== Teste 1: Theta = 2.0 (alta habilidade) ===\n")
r1 <- simular_cat_debug(2.0, 10, itens_params, seed = 42)
cat(sprintf("Erro: %.4f\n\n", abs(2.0 - r1$theta_est)))

# Teste 2: Theta baixo (-2.0) - deve errar a maioria
cat("=== Teste 2: Theta = -2.0 (baixa habilidade) ===\n")
r2 <- simular_cat_debug(-2.0, 10, itens_params, seed = 42)
cat(sprintf("Erro: %.4f\n\n", abs(-2.0 - r2$theta_est)))

# Teste 3: Theta médio (0.5)
cat("=== Teste 3: Theta = 0.5 ===\n")
r3 <- simular_cat_debug(0.5, 10, itens_params, seed = 42)
cat(sprintf("Erro: %.4f\n\n", abs(0.5 - r3$theta_est)))

# Resumo
cat("=== Resumo ===\n")
cat(sprintf("%-12s %-12s %-12s %-12s\n", "Verdadeiro", "Estimado", "Erro", "SE"))
cat(paste(rep("-", 50), collapse = ""), "\n")
cat(sprintf("%-12.2f %-12.4f %-12.4f %-12.4f\n", 2.0, r1$theta_est, abs(2.0 - r1$theta_est), r1$se))
cat(sprintf("%-12.2f %-12.4f %-12.4f %-12.4f\n", -2.0, r2$theta_est, abs(-2.0 - r2$theta_est), r2$se))
cat(sprintf("%-12.2f %-12.4f %-12.4f %-12.4f\n", 0.5, r3$theta_est, abs(0.5 - r3$theta_est), r3$se))
