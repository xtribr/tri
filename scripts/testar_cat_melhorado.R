#!/usr/bin/env Rscript
# Teste do CAT com mais itens e diferentes cenários

library(mirt)
library(httr)
library(jsonlite)

cat("=== Teste Melhorado do CAT ===\n\n")

# Carregar dados
load("tests/fixtures/dados-teste.RData")

# Função para simular CAT
simular_cat <- function(theta_true, n_itens, itens_params) {
  a <- itens_params$a
  b <- itens_params$b
  c <- itens_params$c
  item_ids <- itens_params$item_id
  
  theta_est <- 0
  respostas <- numeric(length(item_ids))
  respostas[] <- NA
  itens_aplicados <- character()
  historico <- data.frame()
  
  for (passo in 1:n_itens) {
    disponiveis <- setdiff(item_ids, itens_aplicados)
    idx_disp <- which(item_ids %in% disponiveis)
    
    # MFI
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
    
    # EAP
    theta_grid <- seq(-4, 4, length.out = 500)
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
    
    historico <- rbind(historico, data.frame(
      passo = passo,
      item = item_sel,
      b = b[melhor_idx],
      resp = resp,
      theta = round(theta_est, 4),
      se = round(theta_se, 4)
    ))
  }
  
  list(theta_est = theta_est, se = theta_se, historico = historico)
}

# Testar com diferentes números de itens
cenarios <- data.frame(
  theta_true = c(1.5, 1.5, 1.5, -1.0, -1.0, 0),
  n_itens = c(5, 10, 20, 10, 20, 10)
)

cat("Testando diferentes cenários:\n")
cat(sprintf("%-10s %-10s %-12s %-10s %-10s\n", "Theta", "N Itens", "Estimado", "SE", "Erro"))
cat(paste(rep("-", 55), collapse = ""), "\n")

set.seed(42)
for (i in 1:nrow(cenarios)) {
  resultado <- simular_cat(cenarios$theta_true[i], cenarios$n_itens[i], itens_params)
  erro <- abs(cenarios$theta_true[i] - resultado$theta_est)
  cat(sprintf("%-10.2f %-10d %-12.4f %-10.4f %-10.4f\n",
              cenarios$theta_true[i], cenarios$n_itens[i],
              resultado$theta_est, resultado$se, erro))
}

# Detalhar um caso
cat("\n=== Detalhamento: Theta=1.5, 20 itens ===\n")
set.seed(123)
resultado <- simular_cat(1.5, 20, itens_params)
print(resultado$historico)
cat(sprintf("\nTheta verdadeiro: 1.5\n"))
cat(sprintf("Theta estimado: %.4f\n", resultado$theta_est))
cat(sprintf("Erro: %.4f\n", abs(1.5 - resultado$theta_est)))

# Verificar distribuição dos itens selecionados
cat(sprintf("\nDistribuição das dificuldades selecionadas:\n"))
cat(sprintf("  Média: %.3f\n", mean(resultado$historico$b)))
cat(sprintf("  Min: %.3f, Max: %.3f\n", min(resultado$historico$b), max(resultado$historico$b)))
