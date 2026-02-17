#!/usr/bin/env Rscript
# =============================================================================
# SIMULAÇÃO DE 40.000 CANDIDATOS - VALIDAÇÃO EM ESCALA
# =============================================================================
#
# DESCRIÇÃO:
#   Este script simula 40.000 candidatos respondendo ao simulado para validar
#   a qualidade dos itens em amostras grandes e comparar com o ENAMED oficial.
#
# OBJETIVOS:
#   1. Validar que os 100 itens funcionam bem em amostras grandes
#   2. Verificar se a qualidade melhora com n=40k vs n=591
#   3. Comparar distribuição de escores com ENAMED oficial
#   4. Gerar evidências de que a prova é apta para aplicação em escala
#
# METODOLOGIA:
#   - Usa parâmetros b calibrados no simulado real (591 candidatos)
#   - Gera thetas de distribuição normal (baseada nos reais)
#   - Simula respostas segundo modelo Rasch 1PL
#   - Recalibra modelo e compara parâmetros
#
# ENTRADA:
#   - output/correcao_enamed/modelo_rasch.rds: Parâmetros calibrados
#   - output/correcao_enamed/resultado_candidatos.csv: Thetas reais
#
# SAÍDA:
#   - output/simulacao_40k/resultados_40k_candidatos.csv: Notas simuladas
#   - output/simulacao_40k/estatisticas_tct_40k.csv: TCT na amostra grande
#   - output/simulacao_40k/comparacao_enamed_40k.csv: Comparação estatística
#   - output/simulacao_40k/modelo_rasch_40k.rds: Modelo recalibrado
#
# RESULTADOS ESPERADOS:
#   - r_biserial médio deve aumentar (estimativas mais precisas)
#   - Nenhum item problemático (todos discriminam bem)
#   - Distribuição similar ao ENAMED oficial
#
# NOTAS PARA MANUTENÇÃO:
#   - Se mudar de modelo (2PL/3PL), adaptar função prob_rasch()
#   - Para simulações maiores (100k+), considerar paralelização
#   - O seed (42) garante reprodutibilidade
#
# REFERÊNCIAS:
#   - mirt::simdata(): Função nativa de simulação (alternativa)
#   - Lord (1980): Applications of Item Response Theory
# =============================================================================

suppressPackageStartupMessages({
  library(mirt)    # Pacote TRI
  library(dplyr)   # Manipulação de dados
})

cat("============================================================\n")
cat("  SIMULAÇÃO: 40.000 CANDIDATOS NO SIMULADO\n")
cat("  Baseado nos parâmetros calibrados (Rasch 1PL)\n")
cat("============================================================\n\n")

set.seed(42)  # Reprodutibilidade

# ============================================================================
# 1. CARREGAR PARÂMETROS CALIBRADOS
# ============================================================================
cat("[1/6] Carregando parâmetros calibrados...\n")

# Ler modelo Rasch calibrado
mod_rasch <- readRDS("output/correcao_enamed/modelo_rasch.rds")

# Extrair parâmetros dos itens (b)
coef_itens <- coef(mod_rasch, simplify = TRUE, IRTpars = TRUE)$items
parametros_b <- coef_itens[, 2]  # Coluna 2 é o parâmetro b no Rasch
n_itens <- length(parametros_b)

cat(sprintf("    ✓ Modelo Rasch carregado: %d itens\n", n_itens))
cat(sprintf("    - Range de dificuldade b: [%.2f, %.2f]\n", 
            min(parametros_b), max(parametros_b)))

# Ler thetas reais para basear a distribuição
thetas_reais <- read.csv2("output/correcao_enamed/resultado_candidatos.csv",
                          stringsAsFactors = FALSE) %>%
  mutate(theta = as.numeric(gsub(",", ".", theta)))

cat(sprintf("    ✓ %d thetas reais carregados\n", nrow(thetas_reais)))
cat(sprintf("    - Theta médio real: %.3f (DP: %.3f)\n", 
            mean(thetas_reais$theta), sd(thetas_reais$theta)))

# ============================================================================
# 2. GERAR 40.000 THETAS
# ============================================================================
cat("\n[2/6] Gerando 40.000 thetas simulados...\n")

# Usar distribuição normal com mesma média e DP dos reais
# Mas expandir ligeiramente para cobrir melhor o range
n_sim <- 40000
theta_media <- mean(thetas_reais$theta)
theta_dp <- sd(thetas_reais$theta) * 1.1  # Aumentar 10% para mais variabilidade

thetas_sim <- rnorm(n_sim, mean = theta_media, sd = theta_dp)

# Garantir que não foge muito da realidade (clip em -3.5 a 3.5)
thetas_sim <- pmax(pmin(thetas_sim, 3.5), -3.5)

cat(sprintf("    ✓ %d thetas gerados\n", n_sim))
cat(sprintf("    - Theta médio simulado: %.3f (DP: %.3f)\n", 
            mean(thetas_sim), sd(thetas_sim)))

# ============================================================================
# 3. SIMULAR RESPOSTAS (Rasch 1PL)
# ============================================================================
#
# PROCESSO DE SIMULAÇÃO:
#   1. Calcular probabilidade de acerto para cada (theta, item)
#   2. Gerar número aleatório U ~ Uniforme(0,1)
#   3. Se U < P, resposta = 1 (acerto), senão 0 (erro)
#
# FÓRMULA DO MODELO RASCH:
#   P(X=1|θ,b) = 1 / (1 + exp(-(θ - b)))
#
#   Onde:
#   - θ = habilidade do candidato (gerado na etapa anterior)
#   - b = dificuldade do item (parâmetro calibrado)
#   - P = probabilidade de acertar o item
#
# ALTERNATIVA (pacote mirt):
#   mirt::simdata(a, b, N, itemtype="Rasch")
#   Vantagem: mais rápido, já otimizado
#   Desvantagem: menos controle sobre o processo
#
# POR QUE SIMULAR EM VEZ DE USAR DADOS REAIS?
#   - Permite controlar os parâmetros verdadeiros
#   - Permite avaliar a recuperação dos parâmetros
#   - Permite testar a prova antes de aplicar em escala
# ============================================================================

cat("\n[3/6] Simulando respostas aos itens (Rasch 1PL)...\n")

# Função de probabilidade do modelo Rasch 1PL
prob_rasch <- function(theta, b) {
  # Fórmula: P = 1 / (1 + exp(-(theta - b)))
  1 / (1 + exp(-(theta - b)))
}

# Função para simular respostas segundo modelo Rasch
simular_respostas <- function(thetas, b_params) {
  n_pessoas <- length(thetas)
  n_itens <- length(b_params)
  
  # Matriz de probabilidades P[i,j] = prob(candidato i acertar item j)
  P <- matrix(0, nrow = n_pessoas, ncol = n_itens)
  for (i in 1:n_pessoas) {
    P[i, ] <- prob_rasch(thetas[i], b_params)
  }
  
  # Simular respostas usando método da transformada inversa
  # U ~ Uniforme(0,1); se U < P, acerto (1), senão erro (0)
  U <- matrix(runif(n_pessoas * n_itens), nrow = n_pessoas, ncol = n_itens)
  respostas <- ifelse(U < P, 1, 0)
  
  colnames(respostas) <- paste0("Q", 1:n_itens)
  return(respostas)
}

# Gerar matriz de respostas (40.000 × 100)
matriz_respostas <- simular_respostas(thetas_sim, parametros_b)

cat(sprintf("    ✓ Matriz de respostas: %d x %d\n", nrow(matriz_respostas), ncol(matriz_respostas)))

# Calcular acertos por candidato
acertos_sim <- rowSums(matriz_respostas)
cat(sprintf("    - Média de acertos: %.2f (DP: %.2f)\n", mean(acertos_sim), sd(acertos_sim)))
cat(sprintf("    - Range: %d a %d acertos\n", min(acertos_sim), max(acertos_sim)))

# ============================================================================
# 4. RECALIBRAR MODELO NA AMOSTRA SIMULADA
# ============================================================================
cat("\n[4/6] Recalibrando modelo Rasch na amostra simulada...\n")

# Ajustar modelo Rasch nos dados simulados
mod_simulado <- mirt(matriz_respostas, model = 1, itemtype = "Rasch", 
                     verbose = FALSE, technical = list(NCYCLES = 1000))

# Extrair novos parâmetros
coef_sim <- coef(mod_simulado, simplify = TRUE, IRTpars = TRUE)$items
parametros_b_sim <- coef_sim[, 2]

# Calcular correlação entre parâmetros originais e simulados
corr_b <- cor(parametros_b, parametros_b_sim)
cat(sprintf("    ✓ Modelo recalibrado\n"))
cat(sprintf("    - Correlação parâmetros b (original vs simulado): %.4f\n", corr_b))

# Calcular estatísticas de ajuste dos itens
ajuste_itens <- itemfit(mod_simulado)
cat(sprintf("    - Média do S-X2 p-value: %.3f\n", mean(ajuste_itens$p, na.rm = TRUE)))

# ============================================================================
# 5. ESTIMAR THETAS NA AMOSTRA SIMULADA
# ============================================================================
cat("\n[5/6] Estimando thetas na amostra simulada...\n")

# EAP estimation
theta_estimado <- fscores(mod_simulado, method = "EAP", full.scores = TRUE, 
                          full.scores.SE = TRUE)
theta_estimado <- as.data.frame(theta_estimado)

thetas_eap <- theta_estimado[, 1]
se_theta <- if (ncol(theta_estimado) > 1) theta_estimado[, 2] else rep(NA, length(thetas_eap))

# Calcular correlação entre thetas gerados e estimados
corr_theta <- cor(thetas_sim, thetas_eap)
cat(sprintf("    - Correlação theta (gerado vs estimado): %.4f\n", corr_theta))
cat(sprintf("    - SE médio: %.3f\n", mean(se_theta, na.rm = TRUE)))

# Calcular notas na escala ENAMED
# Transformação: Nota = 50 + 10 * theta (aproximação)
notas_sim <- pmin(pmax(50 + 10 * thetas_eap, 0), 100)

cat(sprintf("    - Nota média: %.2f (DP: %.2f)\n", mean(notas_sim), sd(notas_sim)))

# ============================================================================
# 6. ANÁLISE TCT NA AMOSTRA SIMULADA
# ============================================================================
cat("\n[6/6] Calculando estatísticas TCT...\n")

# Calcular estatísticas TCT
calcular_tct <- function(respostas) {
  n <- nrow(respostas)
  scores <- rowSums(respostas)
  
  stats <- data.frame(
    item = colnames(respostas),
    taxa_acerto = colMeans(respostas),
    stringsAsFactors = FALSE
  )
  
  # Correlação bisserial
  stats$r_biserial <- sapply(1:ncol(respostas), function(i) {
    cor(respostas[, i], scores, use = "complete.obs")
  })
  
  # Dificuldade (1 - taxa de acerto)
  stats$dificuldade <- 1 - stats$taxa_acerto
  
  # Categorizar
  stats$categoria_dificuldade <- cut(stats$taxa_acerto,
                                     breaks = c(0, 0.3, 0.5, 0.7, 0.9, 1),
                                     labels = c("Muito Difícil", "Difícil", "Médio", "Fácil", "Muito Fácil"),
                                     include.lowest = TRUE)
  
  stats$status <- ifelse(stats$r_biserial < 0.20, "REVISAR", "OK")
  
  return(stats)
}

tct_sim <- calcular_tct(matriz_respostas)

# Resumo TCT
cat("    Estatísticas TCT (simulação 40k):\n")
cat(sprintf("    - Correlação bisserial média: %.3f\n", mean(tct_sim$r_biserial)))
cat(sprintf("    - Itens com baixa discriminação (<0.20): %d\n", sum(tct_sim$r_biserial < 0.20)))

# ============================================================================
# 7. COMPARAR COM ENAMED OFICIAL
# ============================================================================
cat("\n[6.5/6] Comparando com ENAMED oficial...\n")

# Ler dados do ENAMED
enamed_raw <- read.csv2("docs/ENAMED/DADOS/Demais Participantes/microdados_demais_part_2025_arq1.txt",
                        stringsAsFactors = FALSE, fileEncoding = "UTF-8")

# Processar
area_cols <- grep("^QT_ACERTO_AREA", names(enamed_raw), value = TRUE)
enamed_raw$acertos_total <- rowSums(enamed_raw[, area_cols], na.rm = TRUE)
enamed_stats <- enamed_raw %>%
  filter(acertos_total > 0, NT_GER > 0) %>%
  mutate(
    acertos = acertos_total,
    nota_final = suppressWarnings(as.numeric(NT_GER))
  )

# Estatísticas comparativas
stats_comp <- data.frame(
  Metrica = c("N", "Media_Acertos", "DP_Acertos", "Mediana_Acertos", 
              "Min_Acertos", "Max_Acertos", "R_Biserial_Medio"),
  ENAMED_Oficial = c(nrow(enamed_stats),
                     round(mean(enamed_stats$acertos), 2),
                     round(sd(enamed_stats$acertos), 2),
                     round(median(enamed_stats$acertos), 2),
                     round(min(enamed_stats$acertos), 2),
                     round(max(enamed_stats$acertos), 2),
                     NA),  # Não temos r_biserial do ENAMED
  Simulado_40k = c(n_sim,
                   round(mean(acertos_sim), 2),
                   round(sd(acertos_sim), 2),
                   round(median(acertos_sim), 2),
                   round(min(acertos_sim), 2),
                   round(max(acertos_sim), 2),
                   round(mean(tct_sim$r_biserial), 3))
)

cat("\n    COMPARAÇÃO ESTATÍSTICA:\n")
cat("    --------------------------------------------------------\n")
cat(sprintf("    %-20s %15s %15s\n", "Métrica", "ENAMED", "Simulado 40k"))
cat("    --------------------------------------------------------\n")
for (i in 1:nrow(stats_comp)) {
  cat(sprintf("    %-20s %15s %15s\n", 
              stats_comp$Metrica[i], 
              ifelse(is.na(stats_comp$ENAMED_Oficial[i]), "-", as.character(stats_comp$ENAMED_Oficial[i])),
              stats_comp$Simulado_40k[i]))
}

# ============================================================================
# 8. SALVAR RESULTADOS
# ============================================================================
cat("\n[7/6] Salvando resultados...\n")

dir.create("output/simulacao_40k", showWarnings = FALSE, recursive = TRUE)

# Data frame final dos candidatos simulados
resultado_sim_40k <- data.frame(
  id_candidato = 1:n_sim,
  theta_gerado = round(thetas_sim, 4),
  theta_estimado = round(thetas_eap, 4),
  se_theta = round(se_theta, 4),
  acertos = acertos_sim,
  percentual = round(100 * acertos_sim / n_itens, 2),
  nota_enamed = round(notas_sim, 1),
  classificacao = ifelse(notas_sim >= 70, "APROVADO",
                         ifelse(notas_sim >= 60, "LIMITE", "REPROVADO"))
)

write.csv2(resultado_sim_40k, "output/simulacao_40k/resultados_40k_candidatos.csv",
           row.names = FALSE)

# Estatísticas TCT
write.csv2(tct_sim, "output/simulacao_40k/estatisticas_tct_40k.csv", row.names = FALSE)

# Comparação com ENAMED
write.csv2(stats_comp, "output/simulacao_40k/comparacao_enamed_40k.csv", row.names = FALSE)

# Resumo geral
resumo_geral <- data.frame(
  Indicador = c("Candidatos Simulados", "Media Acertos", "DP Acertos", 
                "Mediana Acertos", "Nota Media", "DP Nota",
                "Aprovados (>=70)", "Limite (60-69)", "Reprovados (<60)",
                "R_Biserial Medio", "Itens Problema"),
  Valor = c(n_sim,
            round(mean(acertos_sim), 2),
            round(sd(acertos_sim), 2),
            round(median(acertos_sim), 2),
            round(mean(notas_sim), 2),
            round(sd(notas_sim), 2),
            paste0(sum(resultado_sim_40k$classificacao == "APROVADO"), 
                   " (", round(100*sum(resultado_sim_40k$classificacao == "APROVADO")/n_sim, 1), "%)"),
            paste0(sum(resultado_sim_40k$classificacao == "LIMITE"),
                   " (", round(100*sum(resultado_sim_40k$classificacao == "LIMITE")/n_sim, 1), "%)"),
            paste0(sum(resultado_sim_40k$classificacao == "REPROVADO"),
                   " (", round(100*sum(resultado_sim_40k$classificacao == "REPROVADO")/n_sim, 1), "%)"),
            round(mean(tct_sim$r_biserial), 3),
            sum(tct_sim$r_biserial < 0.20))
)
write.csv2(resumo_geral, "output/simulacao_40k/resumo_geral_40k.csv", row.names = FALSE)

# Salvar modelo
saveRDS(mod_simulado, "output/simulacao_40k/modelo_rasch_40k.rds")

# ============================================================================
# 9. RELATÓRIO FINAL
# ============================================================================
cat("\n============================================================\n")
cat("  SIMULAÇÃO 40K CONCLUÍDA!\n")
cat("============================================================\n\n")

cat("RESULTADOS PRINCIPAIS:\n")
cat(sprintf("  - Candidatos simulados: %d\n", n_sim))
cat(sprintf("  - Média de acertos: %.2f (DP: %.2f)\n", mean(acertos_sim), sd(acertos_sim)))
cat(sprintf("  - Mediana: %.1f acertos\n", median(acertos_sim)))
cat(sprintf("  - Nota média: %.2f\n", mean(notas_sim)))
cat(sprintf("  - Correlação theta (gerado vs estimado): %.4f\n", corr_theta))
cat(sprintf("  - Correlação parâmetros b: %.4f\n", corr_b))
cat("\n")

cat("DISTRIBUIÇÃO DE DESEMPENHO:\n")
cat(sprintf("  - Aprovados (>=70): %.1f%%\n", 100*sum(notas_sim >= 70)/n_sim))
cat(sprintf("  - Limite (60-69): %.1f%%\n", 100*sum(notas_sim >= 60 & notas_sim < 70)/n_sim))
cat(sprintf("  - Reprovados (<60): %.1f%%\n", 100*sum(notas_sim < 60)/n_sim))
cat("\n")

cat("QUALIDADE DOS ITENS (simulação):\n")
cat(sprintf("  - r_biserial médio: %.3f\n", mean(tct_sim$r_biserial)))
cat(sprintf("  - Itens com problema: %d\n", sum(tct_sim$r_biserial < 0.20)))
cat("\n")

cat("COMPARAÇÃO COM ENAMED:\n")
cat(sprintf("  - ENAMED média: %.2f acertos | Simulado: %.2f acertos\n",
            mean(enamed_stats$acertos), mean(acertos_sim)))
cat(sprintf("  - Diferença: %+.2f acertos\n", mean(acertos_sim) - mean(enamed_stats$acertos)))
cat("\n")

cat("ARQUIVOS GERADOS:\n")
cat("  - resultados_40k_candidatos.csv\n")
cat("  - estatisticas_tct_40k.csv\n")
cat("  - comparacao_enamed_40k.csv\n")
cat("  - resumo_geral_40k.csv\n")
cat("  - modelo_rasch_40k.rds\n")
cat("\n============================================================\n")
