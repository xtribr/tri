#!/usr/bin/env Rscript
# Gera gráficos comparativos: ENAMED vs Simulado Real vs Simulação 40k

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(gridExtra)
})

cat("============================================================\n")
cat("  GERANDO GRÁFICOS COMPARATIVOS - SIMULAÇÃO 40K\n")
cat("============================================================\n\n")

# Criar diretório
if (!dir.exists("output/simulacao_40k/graficos")) {
  dir.create("output/simulacao_40k/graficos", recursive = TRUE)
}

# ============================================================================
# 1. LER DADOS
# ============================================================================
cat("[1/3] Lendo dados...\n")

resultado_40k <- read.csv2("output/simulacao_40k/resultados_40k_candidatos.csv",
                           stringsAsFactors = FALSE)
resultado_real <- read.csv2("output/correcao_enamed/resultado_candidatos.csv",
                            stringsAsFactors = FALSE) %>%
  mutate(nota = as.numeric(gsub(",", ".", nota_enamed_estimada)))

# ENAMED - amostra para gráfico (ler arquivo completo para encontrar válidos)
enamed_raw <- read.csv2("docs/ENAMED/DADOS/Demais Participantes/microdados_demais_part_2025_arq1.txt",
                        stringsAsFactors = FALSE)
area_cols <- grep("^QT_ACERTO_AREA", names(enamed_raw), value = TRUE)
enamed_raw$acertos <- rowSums(enamed_raw[, area_cols], na.rm = TRUE)
enamed_validos <- enamed_raw %>% filter(acertos > 0)
# Amostra aleatória
set.seed(123)
enamed_amostra <- enamed_validos %>% sample_n(min(4000, nrow(.)))

cat("    ✓ Dados carregados\n")

# ============================================================================
# 2. GRÁFICO 1: DISTRIBUIÇÃO DE ACERTOS
# ============================================================================
cat("[2/3] Criando gráficos...\n")

# Preparar dados
dist_enamed <- data.frame(acertos = enamed_amostra$acertos, prova = "ENAMED Oficial")
dist_real <- data.frame(acertos = resultado_real$acertos, prova = "Simulado Real (591)")
dist_40k <- data.frame(acertos = resultado_40k$acertos, prova = "Simulação 40k")

dist_completa <- rbind(dist_enamed, dist_real, dist_40k)

# Gráfico de densidade
p1 <- ggplot(dist_completa, aes(x = acertos, fill = prova)) +
  geom_density(alpha = 0.5) +
  labs(title = "Distribuição de Acertos - Comparação",
       subtitle = "ENAMED vs Simulado Real vs Simulação 40k",
       x = "Número de Acertos (0-100)",
       y = "Densidade",
       fill = "Prova") +
  scale_fill_manual(values = c("ENAMED Oficial" = "#E74C3C",
                               "Simulado Real (591)" = "#3498DB", 
                               "Simulação 40k" = "#2ECC71")) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("output/simulacao_40k/graficos/distribuicao_acertos.png", p1, 
       width = 10, height = 6, dpi = 150)
cat("    ✓ distribuicao_acertos.png\n")

# ============================================================================
# 3. GRÁFICO 2: BOXPLOT COMPARATIVO
# ============================================================================

p2 <- ggplot(dist_completa, aes(x = prova, y = acertos, fill = prova)) +
  geom_boxplot(alpha = 0.7) +
  labs(title = "Boxplot Comparativo de Acertos",
       x = "Prova",
       y = "Acertos") +
  scale_fill_manual(values = c("ENAMED Oficial" = "#E74C3C",
                               "Simulado Real (591)" = "#3498DB", 
                               "Simulação 40k" = "#2ECC71")) +
  theme_minimal() +
  theme(legend.position = "none", axis.text.x = element_text(angle = 15, hjust = 1))

ggsave("output/simulacao_40k/graficos/boxplot_acertos.png", p2, 
       width = 8, height = 6, dpi = 150)
cat("    ✓ boxplot_acertos.png\n")

# ============================================================================
# 4. GRÁFICO 3: COMPARAÇÃO DE QUALIDADE DOS ITENS
# ============================================================================

tct_real <- read.csv2("output/correcao_enamed/estatisticas_tct.csv",
                      stringsAsFactors = FALSE) %>%
  mutate(r_biserial = as.numeric(gsub(",", ".", r_biserial)),
         prova = "Simulado Real (591)")
tct_40k <- read.csv2("output/simulacao_40k/estatisticas_tct_40k.csv",
                     stringsAsFactors = FALSE) %>%
  mutate(prova = "Simulação 40k")

# Combinar
tct_combined <- rbind(
  tct_real %>% select(item, r_biserial, taxa_acerto, prova),
  tct_40k %>% select(item, r_biserial, taxa_acerto, prova)
)

p3 <- ggplot(tct_combined, aes(x = r_biserial, fill = prova)) +
  geom_histogram(alpha = 0.6, position = "identity", bins = 20) +
  geom_vline(xintercept = 0.20, linetype = "dashed", color = "red") +
  geom_vline(xintercept = 0.30, linetype = "dashed", color = "green") +
  annotate("text", x = 0.15, y = Inf, label = "Limite mínimo", 
           vjust = 2, color = "red", size = 3) +
  annotate("text", x = 0.35, y = Inf, label = "Excelente", 
           vjust = 2, color = "green", size = 3) +
  labs(title = "Distribuição da Correlação Bisserial (r)",
       subtitle = "Comparação: Simulado Real vs Simulação 40k",
       x = "Correlação Bisserial",
       y = "Frequência",
       fill = "Prova") +
  scale_fill_manual(values = c("Simulado Real (591)" = "#3498DB", 
                               "Simulação 40k" = "#2ECC71")) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("output/simulacao_40k/graficos/distribuicao_r_biserial.png", p3, 
       width = 10, height = 6, dpi = 150)
cat("    ✓ distribuicao_r_biserial.png\n")

# ============================================================================
# 5. GRÁFICO 4: SCATTER PLOT R_REAL vs R_40k
# ============================================================================

tct_merged <- merge(
  tct_real %>% select(item, r_real = r_biserial),
  tct_40k %>% select(item, r_40k = r_biserial),
  by = "item"
)

p4 <- ggplot(tct_merged, aes(x = r_real, y = r_40k)) +
  geom_point(alpha = 0.6, color = "#3498DB", size = 2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
  geom_smooth(method = "lm", se = FALSE, color = "green") +
  labs(title = "Comparação: r_biseral Real vs Simulação 40k",
       subtitle = paste("Correlação:", round(cor(tct_merged$r_real, tct_merged$r_40k), 4)),
       x = "r_biserial - Simulado Real (591)",
       y = "r_biserial - Simulação 40k") +
  theme_minimal()

ggsave("output/simulacao_40k/graficos/correlacao_r_real_vs_40k.png", p4, 
       width = 8, height = 6, dpi = 150)
cat("    ✓ correlacao_r_real_vs_40k.png\n")

# ============================================================================
# 6. GRÁFICO 5: TAXA DE ACERTO POR ITEM
# ============================================================================

tct_merged$diff_taxa <- tct_merged$r_40k - tct_merged$r_real

# Ordenar por dificuldade
tct_merged$item_num <- as.numeric(gsub("Q", "", tct_merged$item))
tct_merged <- tct_merged[order(tct_merged$item_num), ]

p5 <- ggplot(tct_merged, aes(x = reorder(item, item_num))) +
  geom_bar(aes(y = r_real, fill = "Real"), stat = "identity", alpha = 0.6, width = 0.4) +
  geom_bar(aes(y = r_40k, fill = "40k"), stat = "identity", alpha = 0.6, width = 0.4) +
  geom_hline(yintercept = 0.20, linetype = "dashed", color = "red") +
  scale_fill_manual(values = c("Real" = "#3498DB", "40k" = "#2ECC71")) +
  labs(title = "Comparação da Discriminação por Item",
       subtitle = "Simulado Real (591) vs Simulação 40k",
       x = "Item",
       y = "Correlação Bisserial (r)",
       fill = "Prova") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 5))

ggsave("output/simulacao_40k/graficos/r_por_item.png", p5, 
       width = 14, height = 6, dpi = 150)
cat("    ✓ r_por_item.png\n")

# ============================================================================
# 7. GRÁFICO 6: DASHBOARD COMBINADO
# ============================================================================

# Estatísticas para anotação
stats_text <- data.frame(
  label = c(
    paste0("ENAMED\nN=49.7k\nMédia=59.3\nDP=10.0"),
    paste0("Simulado Real\nN=591\nMédia=58.2\nDP=13.9"),
    paste0("Simulação 40k\nN=40k\nMédia=58.1\nDP=14.7")
  ),
  x = c(1, 2, 3),
  y = c(5, 5, 5)
)

p6a <- ggplot(dist_completa, aes(x = acertos, fill = prova)) +
  geom_histogram(alpha = 0.6, position = "identity", bins = 30) +
  facet_wrap(~prova, ncol = 1, scales = "free_y") +
  scale_fill_manual(values = c("ENAMED Oficial" = "#E74C3C",
                               "Simulado Real (591)" = "#3498DB", 
                               "Simulação 40k" = "#2ECC71")) +
  labs(title = "Histogramas de Acertos por Prova",
       x = "Acertos", y = "Frequência") +
  theme_minimal() +
  theme(legend.position = "none")

p6b <- ggplot(tct_combined, aes(x = prova, y = r_biserial, fill = prova)) +
  geom_boxplot(alpha = 0.7) +
  geom_hline(yintercept = c(0.20, 0.30), linetype = "dashed", 
             color = c("red", "green")) +
  scale_fill_manual(values = c("Simulado Real (591)" = "#3498DB", 
                               "Simulação 40k" = "#2ECC71")) +
  labs(title = "Qualidade dos Itens (r_biserial)",
       y = "Correlação Bisserial") +
  theme_minimal() +
  theme(legend.position = "none")

p6 <- grid.arrange(p6a, p6b, ncol = 2, 
                   top = "Dashboard Comparativo: Simulação 40k")

ggsave("output/simulacao_40k/graficos/dashboard_comparativo.png", p6, 
       width = 14, height = 10, dpi = 150)
cat("    ✓ dashboard_comparativo.png\n")

cat("\n============================================================\n")
cat("  GRÁFICOS GERADOS COM SUCESSO!\n")
cat("============================================================\n")
cat("  Local: output/simulacao_40k/graficos/\n\n")
cat("  Arquivos:\n")
cat("    1. distribuicao_acertos.png\n")
cat("    2. boxplot_acertos.png\n")
cat("    3. distribuicao_r_biserial.png\n")
cat("    4. correlacao_r_real_vs_40k.png\n")
cat("    5. r_por_item.png\n")
cat("    6. dashboard_comparativo.png\n")
cat("============================================================\n")
