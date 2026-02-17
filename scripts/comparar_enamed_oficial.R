#!/usr/bin/env Rscript
# Comparação detalhada: Prova Simulada vs ENAMED Oficial 2025

suppressPackageStartupMessages({
  library(dplyr)
})

cat("============================================================\n")
cat("  COMPARAÇÃO: SIMULADO vs ENAMED OFICIAL 2025\n")
cat("============================================================\n\n")

# ============================================================================
# 1. LER DADOS DO ENAMED OFICIAL
# ============================================================================
cat("[1/6] Carregando microdados do ENAMED oficial...\n")

# Ler UM arquivo completo do ENAMED (arq1 tem ~57k registros)
arquivo_enamed <- "docs/ENAMED/DADOS/Demais Participantes/microdados_demais_part_2025_arq1.txt"

cat(sprintf("    Lendo %s...\n", basename(arquivo_enamed)))
enamed_raw <- read.csv2(arquivo_enamed, stringsAsFactors = FALSE, 
                        fileEncoding = "UTF-8")

cat(sprintf("    ✓ %d registros brutos carregados\n", nrow(enamed_raw)))

# Processar e filtrar dados válidos
area_cols <- grep("^QT_ACERTO_AREA", names(enamed_raw), value = TRUE)
enamed_raw$acertos_total <- rowSums(enamed_raw[, area_cols], na.rm = TRUE)

# Converter para numérico
enamed_raw$PROFICIENCIA_NUM <- suppressWarnings(as.numeric(enamed_raw$PROFICIENCIA))
enamed_raw$NT_GER_NUM <- suppressWarnings(as.numeric(enamed_raw$NT_GER))

# Filtrar apenas registros válidos (com acertos e nota)
enamed_stats <- enamed_raw %>%
  filter(acertos_total > 0, !is.na(NT_GER_NUM), NT_GER_NUM > 0) %>%
  mutate(
    acertos = acertos_total,
    proficiencia = PROFICIENCIA_NUM,
    nota_final = NT_GER_NUM,
    perc_acerto = suppressWarnings(as.numeric(PER_ACERTO_ENARE))
  )

cat(sprintf("    ✓ %d candidatos válidos do ENAMED\n", nrow(enamed_stats)))

# ============================================================================
# 2. LER DADOS DO SIMULADO
# ============================================================================
cat("\n[2/6] Carregando dados do simulado...\n")

resultado_simulado <- read.csv2("output/correcao_enamed/resultado_candidatos.csv",
                                 stringsAsFactors = FALSE)

# Converter notas
resultado_simulado <- resultado_simulado %>%
  mutate(
    acertos = as.integer(acertos),
    nota_enamed = as.numeric(gsub(",", ".", nota_enamed_estimada)),
    theta = as.numeric(gsub(",", ".", theta))
  )

cat(sprintf("    ✓ %d candidatos do simulado carregados\n", nrow(resultado_simulado)))

# ============================================================================
# 3. ESTATÍSTICAS DESCRITIVAS COMPARADAS
# ============================================================================
cat("\n[3/6] Calculando estatísticas comparativas...\n")

# Estatísticas do ENAMED
stats_enamed <- enamed_stats %>%
  summarise(
    n = n(),
    media_acertos = mean(acertos, na.rm = TRUE),
    mediana_acertos = median(acertos, na.rm = TRUE),
    dp_acertos = sd(acertos, na.rm = TRUE),
    min_acertos = min(acertos, na.rm = TRUE),
    max_acertos = max(acertos, na.rm = TRUE),
    media_nota = mean(nota_final, na.rm = TRUE),
    dp_nota = sd(nota_final, na.rm = TRUE),
    media_prof = mean(proficiencia, na.rm = TRUE),
    dp_prof = sd(proficiencia, na.rm = TRUE),
    media_perc = mean(perc_acerto, na.rm = TRUE)
  )

# Estatísticas do Simulado
stats_simulado <- resultado_simulado %>%
  summarise(
    n = n(),
    media_acertos = mean(acertos),
    mediana_acertos = median(acertos),
    dp_acertos = sd(acertos),
    min_acertos = min(acertos),
    max_acertos = max(acertos),
    media_nota = mean(nota_enamed),
    dp_nota = sd(nota_enamed),
    media_theta = mean(theta),
    dp_theta = sd(theta)
  )

cat("\n    ESTATÍSTICAS COMPARATIVAS:\n")
cat("    --------------------------------------------------------\n")
cat(sprintf("    %-25s %-15s %-15s\n", "Métrica", "ENAMED Oficial", "Simulado SPRMED"))
cat("    --------------------------------------------------------\n")
cat(sprintf("    %-25s %15d %15d\n", "N candidatos", 
            stats_enamed$n, stats_simulado$n))
cat(sprintf("    %-25s %15.2f %15.2f\n", "Média acertos", 
            stats_enamed$media_acertos, stats_simulado$media_acertos))
cat(sprintf("    %-25s %15.2f %15.2f\n", "DP acertos", 
            stats_enamed$dp_acertos, stats_simulado$dp_acertos))
cat(sprintf("    %-25s %15.1f %15.1f\n", "Mediana acertos", 
            stats_enamed$mediana_acertos, stats_simulado$mediana_acertos))
cat(sprintf("    %-25s %15.2f %15.2f\n", "Min acertos", 
            stats_enamed$min_acertos, stats_simulado$min_acertos))
cat(sprintf("    %-25s %15.2f %15.2f\n", "Max acertos", 
            stats_enamed$max_acertos, stats_simulado$max_acertos))
cat(sprintf("    %-25s %15.2f %15.2f\n", "Nota média (0-100)", 
            stats_enamed$media_nota, stats_simulado$media_nota))
cat(sprintf("    %-25s %15.2f %15.2f\n", "DP nota", 
            stats_enamed$dp_nota, stats_simulado$dp_nota))
cat(sprintf("    %-25s %15.2f %15s\n", "% Acerto médio", 
            stats_enamed$media_perc, "-"))
cat("    --------------------------------------------------------\n")

# ============================================================================
# 4. DISTRIBUIÇÃO COMPARATIVA
# ============================================================================
cat("\n[4/6] Analisando distribuições...\n")

# Amostra para teste KS (máximo 1000 por grupo)
size_enamed <- min(1000, nrow(enamed_stats))
size_simulado <- min(1000, nrow(resultado_simulado))

amostra_enamed <- sample(enamed_stats$acertos, size_enamed)
amostra_simulado <- sample(resultado_simulado$acertos, size_simulado)

# Teste KS (Kolmogorov-Smirnov) para comparar distribuições
ks_test <- ks.test(amostra_enamed, amostra_simulado)

cat("    Teste Kolmogorov-Smirnov:\n")
cat(sprintf("    - Estatística D: %.4f\n", ks_test$statistic))
cat(sprintf("    - p-valor: %.4f\n", ks_test$p.value))
cat(sprintf("    - Interpretação: %s\n", 
            ifelse(ks_test$p.value > 0.05, 
                   "Distribuições ESTATISTICAMENTE SIMILARES ✓",
                   "Distribuições DIFERENTES ✗")))

# Análise de percentis
calcular_percentis <- function(x) {
  quantile(x, probs = c(0.10, 0.25, 0.50, 0.75, 0.90), na.rm = TRUE)
}

perc_enamed <- calcular_percentis(enamed_stats$acertos)
perc_simulado <- calcular_percentis(resultado_simulado$acertos)

cat("\n    Percentis dos Acertos:\n")
cat("    --------------------------------------------------------\n")
cat(sprintf("    %-10s %15s %15s\n", "Percentil", "ENAMED", "Simulado"))
cat("    --------------------------------------------------------\n")
for (i in 1:length(perc_enamed)) {
  cat(sprintf("    %-10s %15.1f %15.1f\n", 
              names(perc_enamed)[i], perc_enamed[i], perc_simulado[i]))
}

# ============================================================================
# 5. ANÁLISE DE ITENS (TCT) DO SIMULADO
# ============================================================================
cat("\n[5/6] Analisando qualidade dos itens do simulado...\n")

# Ler estatísticas TCT do simulado
tct_simulado <- read.csv2("output/correcao_enamed/estatisticas_tct.csv",
                          stringsAsFactors = FALSE) %>%
  mutate(
    taxa_acerto = as.numeric(gsub(",", ".", taxa_acerto)),
    r_biserial = as.numeric(gsub(",", ".", r_biserial))
  )

# Estatísticas de discriminação
stats_discrim <- tct_simulado %>%
  summarise(
    n_itens = n(),
    media_r = mean(r_biserial, na.rm = TRUE),
    mediana_r = median(r_biserial, na.rm = TRUE),
    min_r = min(r_biserial, na.rm = TRUE),
    max_r = max(r_biserial, na.rm = TRUE),
    itens_baixa_disc = sum(r_biserial < 0.20, na.rm = TRUE),
    itens_alta_disc = sum(r_biserial >= 0.30, na.rm = TRUE),
    pct_baixa_disc = round(100 * sum(r_biserial < 0.20, na.rm = TRUE) / n(), 1),
    pct_alta_disc = round(100 * sum(r_biserial >= 0.30, na.rm = TRUE) / n(), 1)
  )

cat("    Qualidade dos itens do simulado:\n")
cat(sprintf("    - Total de itens: %d\n", stats_discrim$n_itens))
cat(sprintf("    - Correlação bisserial média: %.3f\n", stats_discrim$media_r))
cat(sprintf("    - Range: %.3f a %.3f\n", stats_discrim$min_r, stats_discrim$max_r))
cat(sprintf("    - Itens com alta discriminação (≥0.30): %d (%.1f%%)\n",
            stats_discrim$itens_alta_disc, stats_discrim$pct_alta_disc))
cat(sprintf("    - Itens com baixa discriminação (<0.20): %d (%.1f%%)\n",
            stats_discrim$itens_baixa_disc, stats_discrim$pct_baixa_disc))

# Classificação da qualidade
cat("\n    AVALIAÇÃO DA QUALIDADE:\n")
if (stats_discrim$media_r >= 0.30) {
  cat("    ✓ EXCELENTE: Discriminação média alta\n")
} else if (stats_discrim$media_r >= 0.25) {
  cat("    ✓ BOM: Discriminação média adequada\n")
} else if (stats_discrim$media_r >= 0.20) {
  cat("    ⚠ REGULAR: Discriminação média na fronteira\n")
} else {
  cat("    ✗ PRECISA MELHORAR: Discriminação média baixa\n")
}

# Distribuição de dificuldade
dist_dif <- tct_simulado %>%
  group_by(categoria_dificuldade) %>%
  summarise(n = n(), pct = round(100 * n() / nrow(tct_simulado), 1))

cat("\n    Distribuição de dificuldade dos itens:\n")
for (i in 1:nrow(dist_dif)) {
  cat(sprintf("    - %s: %d itens (%.1f%%)\n", 
              dist_dif$categoria_dificuldade[i], dist_dif$n[i], dist_dif$pct[i]))
}

# ============================================================================
# 6. RELATÓRIO FINAL
# ============================================================================
cat("\n[6/6] Gerando relatório comparativo...\n")

# Criar diretório de saída
dir.create("output/comparacao_enamed", showWarnings = FALSE, recursive = TRUE)

# Salvar resumo estatístico
resumo_comparativo <- data.frame(
  Metrica = c("N_Candidatos", "Media_Acertos", "DP_Acertos", "Mediana_Acertos",
              "Min_Acertos", "Max_Acertos", "Nota_Media", "DP_Nota",
              "Percentil_10", "Percentil_25", "Percentil_50", "Percentil_75", "Percentil_90"),
  ENAMED_Oficial = c(stats_enamed$n, stats_enamed$media_acertos, 
                     stats_enamed$dp_acertos, stats_enamed$mediana_acertos,
                     stats_enamed$min_acertos, stats_enamed$max_acertos,
                     stats_enamed$media_nota, stats_enamed$dp_nota,
                     perc_enamed[1], perc_enamed[2], perc_enamed[3], perc_enamed[4], perc_enamed[5]),
  Simulado_SPRMED = c(stats_simulado$n, stats_simulado$media_acertos,
                      stats_simulado$dp_acertos, stats_simulado$mediana_acertos,
                      stats_simulado$min_acertos, stats_simulado$max_acertos,
                      stats_simulado$media_nota, stats_simulado$dp_nota,
                      perc_simulado[1], perc_simulado[2], perc_simulado[3], perc_simulado[4], perc_simulado[5])
)
write.csv2(resumo_comparativo, "output/comparacao_enamed/resumo_comparativo.csv",
           row.names = FALSE)

# Salvar estatísticas de itens
stats_itens <- data.frame(
  Metrica = c("Total_Itens", "Media_R_Biserial", "Mediana_R", "Min_R", "Max_R",
              "Itens_Alta_Discriminacao", "Pct_Alta_Disc",
              "Itens_Baixa_Discriminacao", "Pct_Baixa_Disc"),
  Valor = c(stats_discrim$n_itens, stats_discrim$media_r, stats_discrim$mediana_r,
            stats_discrim$min_r, stats_discrim$max_r,
            stats_discrim$itens_alta_disc, stats_discrim$pct_alta_disc,
            stats_discrim$itens_baixa_disc, stats_discrim$pct_baixa_disc)
)
write.csv2(stats_itens, "output/comparacao_enamed/estatisticas_itens.csv",
           row.names = FALSE)

# Relatório completo em TXT
sink("output/comparacao_enamed/relatorio_comparativo.txt")
cat("============================================================\n")
cat("  RELATÓRIO COMPARATIVO: SIMULADO vs ENAMED OFICIAL 2025\n")
cat("============================================================\n\n")

cat("1. AMOSTRAS ANALISADAS\n")
cat("   - ENAMED Oficial: ", format(stats_enamed$n, big.mark = "."), " candidatos\n")
cat("   - Simulado SPRMED: ", format(stats_simulado$n, big.mark = "."), " candidatos\n\n")

cat("2. ESTATÍSTICAS DESCRITIVAS COMPARADAS\n")
cat("   -------------------------------------------------------\n")
cat(sprintf("   %-22s %12s %12s\n", "Métrica", "ENAMED", "Simulado"))
cat("   -------------------------------------------------------\n")
cat(sprintf("   %-22s %12.1f %12.1f\n", "Média acertos", 
            stats_enamed$media_acertos, stats_simulado$media_acertos))
cat(sprintf("   %-22s %12.1f %12.1f\n", "DP acertos", 
            stats_enamed$dp_acertos, stats_simulado$dp_acertos))
cat(sprintf("   %-22s %12.1f %12.1f\n", "Mediana acertos", 
            stats_enamed$mediana_acertos, stats_simulado$mediana_acertos))
cat(sprintf("   %-22s %12.1f %12.1f\n", "Nota média", 
            stats_enamed$media_nota, stats_simulado$media_nota))
cat(sprintf("   %-22s %12.1f %12.1f\n", "DP nota", 
            stats_enamed$dp_nota, stats_simulado$dp_nota))
cat("   -------------------------------------------------------\n\n")

cat("3. ANÁLISE DE PERCENTIS\n")
cat("   -------------------------------------------------------\n")
cat(sprintf("   %-10s %12s %12s\n", "Percentil", "ENAMED", "Simulado"))
cat("   -------------------------------------------------------\n")
for (i in 1:length(perc_enamed)) {
  cat(sprintf("   %-10s %12.1f %12.1f\n", 
              names(perc_enamed)[i], perc_enamed[i], perc_simulado[i]))
}
cat("   -------------------------------------------------------\n\n")

cat("4. SIMILARIDADE DAS DISTRIBUIÇÕES\n")
cat(sprintf("   - Teste Kolmogorov-Smirnov:\n"))
cat(sprintf("     Estatística D: %.4f\n", ks_test$statistic))
cat(sprintf("     p-valor: %.4f\n", ks_test$p.value))
cat(sprintf("   - Conclusão: %s\n\n", 
            ifelse(ks_test$p.value > 0.05, 
                   "As distribuições são ESTATISTICAMENTE SIMILARES",
                   "As distribuições são DIFERENTES")))

cat("5. QUALIDADE DOS ITENS DO SIMULADO\n")
cat(sprintf("   - Total de itens analisados: %d\n", stats_discrim$n_itens))
cat(sprintf("   - Correlação bisserial média: %.3f\n", stats_discrim$media_r))
cat(sprintf("   - Itens com alta discriminação (≥0.30): %d (%.1f%%)\n",
            stats_discrim$itens_alta_disc, stats_discrim$pct_alta_disc))
cat(sprintf("   - Itens com baixa discriminação (<0.20): %d (%.1f%%)\n\n",
            stats_discrim$itens_baixa_disc, stats_discrim$pct_baixa_disc))

cat("6. PONTOS FORTES DO SIMULADO\n")
cat("   ✓ Amostra representativa (591 candidatos)\n")
if (ks_test$p.value > 0.05) {
  cat("   ✓ Distribuição de escores similar ao ENAMED oficial\n")
}
if (stats_simulado$dp_acertos > 10) {
  cat("   ✓ Boa variabilidade de escores (DP =", round(stats_simulado$dp_acertos, 1), ")\n")
}
if (stats_discrim$media_r >= 0.25) {
  cat("   ✓ Itens com boa capacidade discriminatória\n")
}
cat("\n")

cat("7. OPORTUNIDADES DE MELHORIA\n")
if (abs(stats_simulado$media_acertos - stats_enamed$media_acertos) > 5) {
  dif <- stats_simulado$media_acertos - stats_enamed$media_acertos
  cat(sprintf("   ⚠ Diferença na média de acertos: %+.1f (simulado %s)\n",
              dif, ifelse(dif > 0, "mais fácil", "mais difícil")))
}
if (stats_discrim$itens_baixa_disc > 5) {
  cat(sprintf("   ⚠ %d itens com baixa discriminação (< 0.20)\n", 
              stats_discrim$itens_baixa_disc))
  cat("     Sugestão: Revisar ou substituir estes itens\n")
}
cat("\n")

cat("8. RECOMENDAÇÕES PARA PRÓXIMAS EDIÇÕES\n")
cat("   1. Manter itens com r_biserial > 0.25\n")
cat("   2. Substituir itens com r_biserial < 0.15\n")
cat("   3. Balancear dificuldade para média ~50-60 acertos\n")
cat("   4. Manter variabilidade (DP > 12)\n")
cat("   5. Validar com método Angoff para definição de cortes\n")

cat("\n============================================================\n")
cat("  Relatório gerado em: ", format(Sys.time(), "%d/%m/%Y %H:%M"), "\n")
cat("============================================================\n")
sink()

cat("\n    Arquivos gerados:\n")
cat("    - relatorio_comparativo.txt\n")
cat("    - resumo_comparativo.csv\n")
cat("    - estatisticas_itens.csv\n")

cat("\n============================================================\n")
cat("  ANÁLISE COMPARATIVA CONCLUÍDA!\n")
cat("============================================================\n")
