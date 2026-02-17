#!/usr/bin/env Rscript
# Gera Excel comparativo completo: Simulado vs ENAMED Oficial

suppressPackageStartupMessages({
  library(openxlsx)
  library(dplyr)
})

cat("============================================================\n")
cat("  GERANDO EXCEL COMPARATIVO ENAMED\n")
cat("============================================================\n\n")

# ============================================================================
# 1. LER DADOS
# ============================================================================
cat("[1/3] Lendo dados...\n")

resumo_comp <- read.csv2("output/comparacao_enamed/resumo_comparativo.csv",
                         stringsAsFactors = FALSE)
estat_itens <- read.csv2("output/comparacao_enamed/estatisticas_itens.csv",
                         stringsAsFactors = FALSE)
tct_simulado <- read.csv2("output/correcao_enamed/estatisticas_tct.csv",
                          stringsAsFactors = FALSE) %>%
  mutate(
    taxa_acerto = as.numeric(gsub(",", ".", taxa_acerto)),
    r_biserial = as.numeric(gsub(",", ".", r_biserial))
  )

cat("    ✓ Dados carregados\n")

# ============================================================================
# 2. CRIAR WORKBOOK
# ============================================================================
cat("[2/3] Criando Excel...\n")

wb <- createWorkbook()

# Estilos
titulo_style <- createStyle(fontSize = 18, fontColour = "#1F4E78", 
                            textDecoration = "bold")
subtitulo_style <- createStyle(fontSize = 13, fontColour = "#1F4E78",
                               textDecoration = "bold")
header_style <- createStyle(fontSize = 11, fontColour = "white", 
                            fgFill = "#4472C4", textDecoration = "bold",
                            halign = "center")
num_style <- createStyle(halign = "right", numFmt = "0.00")
verde_style <- createStyle(fgFill = "#C6EFCE", fontColour = "#006100")
amarelo_style <- createStyle(fgFill = "#FFEB9C", fontColour = "#9C5700")
vermelho_style <- createStyle(fgFill = "#FFC7CE", fontColour = "#9C0006")

# ============================================================================
# ABA 1 - DASHBOARD COMPARATIVO
# ============================================================================
cat("    Criando Dashboard...\n")
addWorksheet(wb, "Dashboard", gridLines = FALSE)

# Título
writeData(wb, "Dashboard", "COMPARAÇÃO: SIMULADO vs ENAMED OFICIAL 2025", 
          startRow = 1, startCol = 1)
addStyle(wb, "Dashboard", titulo_style, rows = 1, cols = 1)
writeData(wb, "Dashboard", paste("Gerado em:", format(Sys.time(), "%d/%m/%Y")), 
          startRow = 2, startCol = 1)

# KPIs lado a lado
writeData(wb, "Dashboard", "INDICADORES PRINCIPAIS", startRow = 4, startCol = 1)
addStyle(wb, "Dashboard", subtitulo_style, rows = 4, cols = 1)

kpis <- data.frame(
  Indicador = c("Candidatos", "Média Acertos", "Mediana", "DP Acertos", 
                "Nota Média", "DP Nota", "% Acerto Médio"),
  ENAMED_Oficial = c("49.745", "59.3", "59.0", "10.0", "68.6", "10.2", "69.3%"),
  Simulado = c("591", "58.2", "59.0", "13.9", "53.4", "22.8", "-"),
  Avaliacao = c("✓", "✓", "✓", "✓ Melhor", "⚠", "⚠", "-")
)
writeData(wb, "Dashboard", kpis, startRow = 5, startCol = 1, borders = "all")
addStyle(wb, "Dashboard", header_style, rows = 5, cols = 1:4)

# Análise textual
writeData(wb, "Dashboard", "ANÁLISE DA COMPARAÇÃO", startRow = 13, startCol = 1)
addStyle(wb, "Dashboard", subtitulo_style, rows = 13, cols = 1)

analise_texto <- data.frame(
  Aspecto = c("Distribuição de Acertos", "Variabilidade", 
              "Discriminação dos Itens", "Dificuldade da Prova",
              "Amostragem"),
  Resultado = c("SIMILAR - Mediana idêntica (59)", 
                "SIMULADO MELHOR - Maior DP (13.9 vs 10.0)",
                "BOM - Média r=0.268 (37% itens excelentes)",
                "SIMILAR - Média próxima (58.2 vs 59.3)",
                "ENAMED maior (49.7k vs 591)"),
  Status = c("✓", "✓", "✓", "✓", "⚠")
)
writeData(wb, "Dashboard", analise_texto, startRow = 14, startCol = 1, borders = "all")
addStyle(wb, "Dashboard", header_style, rows = 14, cols = 1:3)

# Destacar status
for (i in 1:nrow(analise_texto)) {
  if (analise_texto$Status[i] == "✓") {
    addStyle(wb, "Dashboard", verde_style, rows = 14 + i, cols = 3, stack = TRUE)
  } else {
    addStyle(wb, "Dashboard", amarelo_style, rows = 14 + i, cols = 3, stack = TRUE)
  }
}

# ============================================================================
# ABA 2 - TABELA COMPARATIVA DETALHADA
# ============================================================================
cat("    Criando Tabela Comparativa...\n")
addWorksheet(wb, "Comparacao_Detalhada", gridLines = FALSE)

writeData(wb, "Comparacao_Detalhada", "TABELA COMPARATIVA DETALHADA", 
          startRow = 1, startCol = 1)
addStyle(wb, "Comparacao_Detalhada", titulo_style, rows = 1, cols = 1)

writeData(wb, "Comparacao_Detalhada", resumo_comp, startRow = 3, startCol = 1, 
          borders = "all")
addStyle(wb, "Comparacao_Detalhada", header_style, rows = 3, cols = 1:3)

# Formatar números
addStyle(wb, "Comparacao_Detalhada", num_style, rows = 4:(3+nrow(resumo_comp)), 
         cols = 2:3, stack = TRUE, gridExpand = TRUE)

# ============================================================================
# ABA 3 - PERCENTIS
# ============================================================================
cat("    Criando Análise de Percentis...\n")
addWorksheet(wb, "Percentis", gridLines = FALSE)

writeData(wb, "Percentis", "COMPARAÇÃO DE PERCENTIS", startRow = 1, startCol = 1)
addStyle(wb, "Percentis", titulo_style, rows = 1, cols = 1)

percentis_df <- resumo_comp %>% 
  filter(grepl("Percentil", Metrica)) %>%
  mutate(Percentil = gsub("Percentil_", "", Metrica),
         Diferenca = round(ENAMED_Oficial - Simulado_SPRMED, 1))

writeData(wb, "Percentis", percentis_df %>% select(Percentil, ENAMED_Oficial, Simulado_SPRMED, Diferenca),
          startRow = 3, startCol = 1, borders = "all")
addStyle(wb, "Percentis", header_style, rows = 3, cols = 1:4)

# ============================================================================
# ABA 4 - QUALIDADE DOS ITENS
# ============================================================================
cat("    Criando Análise de Itens...\n")
addWorksheet(wb, "Qualidade_Itens", gridLines = FALSE)

writeData(wb, "Qualidade_Itens", "QUALIDADE DOS ITENS DO SIMULADO", 
          startRow = 1, startCol = 1)
addStyle(wb, "Qualidade_Itens", titulo_style, rows = 1, cols = 1)

# Estatísticas gerais
writeData(wb, "Qualidade_Itens", "Estatísticas Gerais", startRow = 3, startCol = 1)
addStyle(wb, "Qualidade_Itens", subtitulo_style, rows = 3, cols = 1)

writeData(wb, "Qualidade_Itens", estat_itens, startRow = 4, startCol = 1, borders = "all")
addStyle(wb, "Qualidade_Itens", header_style, rows = 4, cols = 1:2)

# Classificação
writeData(wb, "Qualidade_Itens", "Classificação da Qualidade", startRow = 17, startCol = 1)
addStyle(wb, "Qualidade_Itens", subtitulo_style, rows = 17, cols = 1)

classif_qualidade <- data.frame(
  Faixa_R = c("r ≥ 0.30 (Excelente)", "0.25 ≤ r < 0.30 (Bom)", 
              "0.20 ≤ r < 0.25 (Regular)", "r < 0.20 (Baixo)"),
  Quantidade = c(37, 19, 27, 17),
  Percentual = c("37.0%", "19.0%", "27.0%", "17.0%"),
  Status = c("✓ Manter", "✓ Manter", "⚠ Revisar", "✗ Substituir")
)
writeData(wb, "Qualidade_Itens", classif_qualidade, startRow = 18, startCol = 1, borders = "all")
addStyle(wb, "Qualidade_Itens", header_style, rows = 18, cols = 1:4)

# Cores para status
for (i in 1:nrow(classif_qualidade)) {
  status_val <- as.character(classif_qualidade$Status[i])
  if (grepl("✓", status_val)) {
    addStyle(wb, "Qualidade_Itens", verde_style, rows = 18 + i, cols = 4, stack = TRUE)
  } else if (grepl("✗", status_val)) {
    addStyle(wb, "Qualidade_Itens", vermelho_style, rows = 18 + i, cols = 4, stack = TRUE)
  } else {
    addStyle(wb, "Qualidade_Itens", amarelo_style, rows = 18 + i, cols = 4, stack = TRUE)
  }
}

# Lista de itens problemáticos
writeData(wb, "Qualidade_Itens", "Itens com Problemas (r < 0.20)", 
          startRow = 24, startCol = 1)
addStyle(wb, "Qualidade_Itens", subtitulo_style, rows = 24, cols = 1)

itens_problema <- tct_simulado %>% 
  filter(r_biserial < 0.20) %>%
  select(item, posicao, taxa_acerto, r_biserial, status) %>%
  arrange(r_biserial)

writeData(wb, "Qualidade_Itens", itens_problema, startRow = 25, startCol = 1, borders = "all")
addStyle(wb, "Qualidade_Itens", header_style, rows = 25, cols = 1:5)
for (r in 26:(25+nrow(itens_problema))) {
  addStyle(wb, "Qualidade_Itens", vermelho_style, rows = r, cols = 1:5, stack = TRUE, gridExpand = TRUE)
}

# ============================================================================
# ABA 5 - DISTRIBUIÇÃO DE DIFICULDADE
# ============================================================================
cat("    Criando Distribuição de Dificuldade...\n")
addWorksheet(wb, "Dificuldade", gridLines = FALSE)

writeData(wb, "Dificuldade", "DISTRIBUIÇÃO DE DIFICULDADE DOS ITENS", 
          startRow = 1, startCol = 1)
addStyle(wb, "Dificuldade", titulo_style, rows = 1, cols = 1)

# Tabela de distribuição
dist_dif <- tct_simulado %>%
  group_by(categoria_dificuldade) %>%
  summarise(
    n = n(),
    pct = round(100 * n() / nrow(tct_simulado), 1),
    media_r = round(mean(r_biserial), 3)
  )

dist_dif_fmt <- data.frame(
  Categoria = dist_dif$categoria_dificuldade,
  Quantidade = dist_dif$n,
  Percentual = paste0(dist_dif$pct, "%"),
  Media_R = dist_dif$media_r
)

writeData(wb, "Dificuldade", dist_dif_fmt, startRow = 3, startCol = 1, borders = "all")
addStyle(wb, "Dificuldade", header_style, rows = 3, cols = 1:4)

# Recomendações
writeData(wb, "Dificuldade", "Recomendações de Balanceamento", startRow = 10, startCol = 1)
addStyle(wb, "Dificuldade", subtitulo_style, rows = 10, cols = 1)

recomendacoes <- data.frame(
  Categoria = c("Muito Fácil", "Fácil", "Médio", "Difícil", "Muito Difícil"),
  Atual = c("12%", "58%", "27%", "3%", "0%"),
  Recomendado = c("10-15%", "30-40%", "30-40%", "15-20%", "5-10%"),
  Status = c("✓", "⚠ Muitos", "✓", "⚠ Poucos", "⚠ Ausente")
)
writeData(wb, "Dificuldade", recomendacoes, startRow = 11, startCol = 1, borders = "all")
addStyle(wb, "Dificuldade", header_style, rows = 11, cols = 1:4)

# ============================================================================
# ABA 6 - CONCLUSÕES E RECOMENDAÇÕES
# ============================================================================
cat("    Criando Conclusões...\n")
addWorksheet(wb, "Conclusoes", gridLines = FALSE)

writeData(wb, "Conclusoes", "CONCLUSÕES E RECOMENDAÇÕES", startRow = 1, startCol = 1)
addStyle(wb, "Conclusoes", titulo_style, rows = 1, cols = 1)

# Pontos fortes
writeData(wb, "Conclusoes", "PONTOS FORTES DO SIMULADO", startRow = 3, startCol = 1)
addStyle(wb, "Conclusoes", subtitulo_style, rows = 3, cols = 1)

pontos_fortes <- data.frame(
  Item = 1:5,
  Descricao = c(
    "Mediana de acertos idêntica ao ENAMED oficial (59)",
    "Maior variabilidade de escores (DP 13.9 vs 10.0)",
    "Boa discriminação média dos itens (r = 0.268)",
    "37% dos itens com alta discriminação (≥0.30)",
    "Média de acertos próxima ao ENAMED (58.2 vs 59.3)"
  )
)
writeData(wb, "Conclusoes", pontos_fortes, startRow = 4, startCol = 1, borders = "all")
for (r in 5:9) {
  addStyle(wb, "Conclusoes", verde_style, rows = r, cols = 1:2, stack = TRUE, gridExpand = TRUE)
}

# Oportunidades
writeData(wb, "Conclusoes", "OPORTUNIDADES DE MELHORIA", startRow = 11, startCol = 1)
addStyle(wb, "Conclusoes", subtitulo_style, rows = 11, cols = 1)

oportunidades <- data.frame(
  Item = 1:4,
  Descricao = c(
    "17 itens com baixa discriminação (<0.20) - revisar ou substituir",
    "Falta de itens muito difíceis (0%) - incluir mais itens desafiadores",
    "Poucos itens difíceis (3%) - aumentar para 15-20%",
    "Muitos itens fáceis (58%) - reduzir para 30-40%"
  )
)
writeData(wb, "Conclusoes", oportunidades, startRow = 12, startCol = 1, borders = "all")
for (r in 13:16) {
  addStyle(wb, "Conclusoes", amarelo_style, rows = r, cols = 1:2, stack = TRUE, gridExpand = TRUE)
}

# Recomendações prioritárias
writeData(wb, "Conclusoes", "RECOMENDAÇÕES PRIORITÁRIAS", startRow = 18, startCol = 1)
addStyle(wb, "Conclusoes", subtitulo_style, rows = 18, cols = 1)

recomendacoes <- data.frame(
  Prioridade = c("ALTA", "ALTA", "MÉDIA", "MÉDIA", "BAIXA"),
  Acao = c(
    "Revisar os 17 itens com r < 0.20 (especialmente Q3, Q10, Q15)",
    "Incluir mais itens difíceis (atualmente apenas 3%)",
    "Manter itens com r > 0.30 (37 itens excelentes)",
    "Reduzir proporção de itens fáceis de 58% para ~35%",
    "Aumentar amostra de candidatos para >1000"
  )
)
writeData(wb, "Conclusoes", recomendacoes, startRow = 19, startCol = 1, borders = "all")
addStyle(wb, "Conclusoes", header_style, rows = 19, cols = 1:2)

# Cores por prioridade
for (i in 1:nrow(recomendacoes)) {
  if (recomendacoes$Prioridade[i] == "ALTA") {
    addStyle(wb, "Conclusoes", vermelho_style, rows = 19 + i, cols = 1, stack = TRUE)
  } else if (recomendacoes$Prioridade[i] == "MÉDIA") {
    addStyle(wb, "Conclusoes", amarelo_style, rows = 19 + i, cols = 1, stack = TRUE)
  } else {
    addStyle(wb, "Conclusoes", verde_style, rows = 19 + i, cols = 1, stack = TRUE)
  }
}

# ============================================================================
# AJUSTAR LARGURAS
# ============================================================================
setColWidths(wb, "Dashboard", cols = 1, widths = 30)
setColWidths(wb, "Dashboard", cols = 2:4, widths = 20)
setColWidths(wb, "Comparacao_Detalhada", cols = 1, widths = 25)
setColWidths(wb, "Comparacao_Detalhada", cols = 2:3, widths = 18)
setColWidths(wb, "Qualidade_Itens", cols = 1, widths = 35)
setColWidths(wb, "Qualidade_Itens", cols = 2:5, widths = 15)
setColWidths(wb, "Dificuldade", cols = 1:4, widths = 20)
setColWidths(wb, "Conclusoes", cols = 1, widths = 12)
setColWidths(wb, "Conclusoes", cols = 2, widths = 70)

# ============================================================================
# SALVAR
# ============================================================================
cat("[3/3] Salvando Excel...\n")

saveWorkbook(wb, "output/COMPARACAO_ENAMED_COMPLETO.xlsx", overwrite = TRUE)

cat("\n============================================================\n")
cat("  EXCEL COMPARATIVO GERADO COM SUCESSO!\n")
cat("============================================================\n")
cat("  Arquivo: output/COMPARACAO_ENAMED_COMPLETO.xlsx\n")
cat("\n  Abas criadas:\n")
cat("    1. Dashboard - Visão geral comparativa\n")
cat("    2. Comparacao_Detalhada - Tabela completa\n")
cat("    3. Percentis - Análise de percentis\n")
cat("    4. Qualidade_Itens - Análise detalhada dos itens\n")
cat("    5. Dificuldade - Distribuição de dificuldade\n")
cat("    6. Conclusoes - Recomendações finais\n")
cat("============================================================\n")
