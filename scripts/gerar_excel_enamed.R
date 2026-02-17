#!/usr/bin/env Rscript
# Gera relatório Excel completo da correção ENAMED

suppressPackageStartupMessages({
  library(openxlsx)
  library(dplyr)
})

cat("============================================================\n")
cat("  GERANDO EXCEL ENAMED - RELATÓRIO COMPLETO\n")
cat("============================================================\n\n")

# ============================================================================
# 1. LER DADOS
# ============================================================================
cat("[1/4] Lendo dados gerados...\n")

# Resultados dos candidatos
resultados <- read.csv2("output/correcao_enamed/resultado_candidatos.csv", 
                        stringsAsFactors = FALSE)

# Parâmetros dos itens
itens_tri <- read.csv2("output/correcao_enamed/parametros_itens_tri.csv",
                       stringsAsFactors = FALSE)

# Estatísticas TCT
tct <- read.csv2("output/correcao_enamed/estatisticas_tct.csv",
                 stringsAsFactors = FALSE)

cat(sprintf("    ✓ %d candidatos carregados\n", nrow(resultados)))
cat(sprintf("    ✓ %d itens carregados\n", nrow(itens_tri)))

# ============================================================================
# 2. CRIAR WORKBOOK COM ESTILOS
# ============================================================================
cat("\n[2/4] Criando estrutura do Excel...\n")

wb <- createWorkbook()

# Estilos
titulo_style <- createStyle(fontSize = 16, fontColour = "#1F4E78", 
                            textDecoration = "bold")
subtitulo_style <- createStyle(fontSize = 12, fontColour = "#1F4E78",
                               textDecoration = "bold")
header_style <- createStyle(fontSize = 11, fontColour = "white", 
                            fgFill = "#4472C4", textDecoration = "bold",
                            halign = "center", valign = "center")
num_style <- createStyle(halign = "right", numFmt = "0.00")
percent_style <- createStyle(halign = "right", numFmt = "0.0%")
int_style <- createStyle(halign = "center")
aprovado_style <- createStyle(fgFill = "#C6EFCE", fontColour = "#006100")
reprovado_style <- createStyle(fgFill = "#FFC7CE", fontColour = "#9C0006")
limite_style <- createStyle(fgFill = "#FFEB9C", fontColour = "#9C5700")

# ============================================================================
# 3. ABA 1 - RESULTADOS DOS CANDIDATOS
# ============================================================================
cat("    Criando aba: Resultados dos Candidatos...\n")

addWorksheet(wb, "Resultados", gridLines = FALSE)

# Título
writeData(wb, "Resultados", "RESULTADOS DA CORREÇÃO ENAMED", startRow = 1, startCol = 1)
addStyle(wb, "Resultados", titulo_style, rows = 1, cols = 1)

# Data da análise
writeData(wb, "Resultados", paste("Data:", format(Sys.time(), "%d/%m/%Y %H:%M")), 
          startRow = 2, startCol = 1)

# Resumo estatístico
writeData(wb, "Resultados", "Resumo Estatístico", startRow = 4, startCol = 1)
addStyle(wb, "Resultados", subtitulo_style, rows = 4, cols = 1)

resumo_stats <- data.frame(
  Metrica = c("Total de Candidatos", "Nota Média", "Mediana", "Desvio Padrão",
              "Mínimo", "Máximo", "Aprovados (≥70)", "Limite (60-69)", "Reprovados (<60)"),
  Valor = c(nrow(resultados),
            round(mean(resultados$nota_enamed_estimada), 2),
            round(median(resultados$nota_enamed_estimada), 2),
            round(sd(resultados$nota_enamed_estimada), 2),
            round(min(resultados$nota_enamed_estimada), 1),
            round(max(resultados$nota_enamed_estimada), 1),
            paste0(sum(resultados$classificacao == "APROVADO"), " (", 
                   round(100*sum(resultados$classificacao == "APROVADO")/nrow(resultados), 1), "%)"),
            paste0(sum(resultados$classificacao == "LIMITE"), " (", 
                   round(100*sum(resultados$classificacao == "LIMITE")/nrow(resultados), 1), "%)"),
            paste0(sum(resultados$classificacao == "REPROVADO"), " (", 
                   round(100*sum(resultados$classificacao == "REPROVADO")/nrow(resultados), 1), "%)"))
)

writeData(wb, "Resultados", resumo_stats, startRow = 5, startCol = 1, borders = "all")
addStyle(wb, "Resultados", header_style, rows = 5, cols = 1:2)

# Dados completos
writeData(wb, "Resultados", "Dados Completos dos Candidatos", startRow = 16, startCol = 1)
addStyle(wb, "Resultados", subtitulo_style, rows = 16, cols = 1)

# Preparar dados para exibição
resultados_fmt <- resultados %>%
  mutate(
    Rank = rank(-nota_enamed_estimada, ties.method = "min"),
    acertos = as.integer(acertos),
    percentual_bruto = as.numeric(percentual_bruto),
    theta = round(as.numeric(gsub(",", ".", theta)), 4),
    se_theta = round(as.numeric(gsub(",", ".", se_theta)), 4),
    nota_enamed_estimada = round(as.numeric(gsub(",", ".", nota_enamed_estimada)), 1),
    ic_inferior_95 = round(as.numeric(gsub(",", ".", ic_inferior_95)), 4),
    ic_superior_95 = round(as.numeric(gsub(",", ".", ic_superior_95)), 4)
  ) %>%
  select(Rank, nome, email, acertos, percentual_bruto, theta, se_theta, 
         nota_enamed_estimada, ic_inferior_95, ic_superior_95, classificacao) %>%
  arrange(Rank)

writeData(wb, "Resultados", resultados_fmt, startRow = 17, startCol = 1, borders = "all")
addStyle(wb, "Resultados", header_style, rows = 17, cols = 1:11)

# Aplicar estilos condicionais
for (i in 1:nrow(resultados_fmt)) {
  row <- 17 + i
  classif <- resultados_fmt$classificacao[i]
  style <- switch(classif,
                  "APROVADO" = aprovado_style,
                  "REPROVADO" = reprovado_style,
                  "LIMITE" = limite_style)
  if (!is.null(style)) {
    addStyle(wb, "Resultados", style, rows = row, cols = 11, stack = TRUE)
  }
}

# Formatar colunas numéricas
addStyle(wb, "Resultados", num_style, rows = 18:(17+nrow(resultados_fmt)), cols = 6:10, stack = TRUE, gridExpand = TRUE)

# Ajustar larguras
setColWidths(wb, "Resultados", cols = 1, widths = 8)
setColWidths(wb, "Resultados", cols = 2, widths = 35)
setColWidths(wb, "Resultados", cols = 3, widths = 35)
setColWidths(wb, "Resultados", cols = 4:11, widths = 15)

# Congelar painel
freezePane(wb, "Resultados", firstActiveRow = 18)

# ============================================================================
# 4. ABA 2 - ANÁLISE DOS ITENS (TRI)
# ============================================================================
cat("    Criando aba: Análise TRI dos Itens...\n")

addWorksheet(wb, "Itens_TRI", gridLines = FALSE)

# Título
writeData(wb, "Itens_TRI", "PARÂMETROS TRI - MODELO RASCH 1PL", startRow = 1, startCol = 1)
addStyle(wb, "Itens_TRI", titulo_style, rows = 1, cols = 1)

# Dados dos itens
itens_fmt <- itens_tri %>%
  mutate(
    b = round(as.numeric(gsub(",", ".", b)), 4),
    dificuldade_texto = case_when(
      b < -1.5 ~ "Muito Fácil",
      b < -0.5 ~ "Fácil",
      b < 0.5 ~ "Médio",
      b < 1.5 ~ "Difícil",
      TRUE ~ "Muito Difícil"
    )
  ) %>%
  select(item, b, dificuldade_texto, everything())

writeData(wb, "Itens_TRI", itens_fmt, startRow = 3, startCol = 1, borders = "all")
addStyle(wb, "Itens_TRI", header_style, rows = 3, cols = 1:ncol(itens_fmt))

# Estatísticas de dificuldade
writeData(wb, "Itens_TRI", "Distribuição da Dificuldade", startRow = 3, startCol = 12)
addStyle(wb, "Itens_TRI", subtitulo_style, rows = 3, cols = 12)

dist_dif <- itens_fmt %>%
  count(dificuldade_texto) %>%
  mutate(Pct = round(100 * n / sum(n), 1))

writeData(wb, "Itens_TRI", dist_dif, startRow = 4, startCol = 12, borders = "all")

# Estatísticas descritivas dos parâmetros
writeData(wb, "Itens_TRI", "Estatísticas dos Parâmetros", startRow = 9, startCol = 12)
addStyle(wb, "Itens_TRI", subtitulo_style, rows = 9, cols = 12)

stats_b <- data.frame(
  Estatística = c("Média", "Mediana", "DP", "Mínimo", "Máximo"),
  Valor = c(round(mean(itens_fmt$b), 4),
            round(median(itens_fmt$b), 4),
            round(sd(itens_fmt$b), 4),
            round(min(itens_fmt$b), 4),
            round(max(itens_fmt$b), 4))
)
writeData(wb, "Itens_TRI", stats_b, startRow = 10, startCol = 12, borders = "all")

# Ajustar larguras
setColWidths(wb, "Itens_TRI", cols = 1, widths = 10)
setColWidths(wb, "Itens_TRI", cols = 2:ncol(itens_fmt), widths = 15)

# ============================================================================
# 5. ABA 3 - ANÁLISE TCT
# ============================================================================
cat("    Criando aba: Análise TCT...\n")

addWorksheet(wb, "Analise_TCT", gridLines = FALSE)

# Título
writeData(wb, "Analise_TCT", "ANÁLISE TCT (Teoria Clássica dos Testes)", startRow = 1, startCol = 1)
addStyle(wb, "Analise_TCT", titulo_style, rows = 1, cols = 1)

# Dados TCT
tct_fmt <- tct %>%
  mutate(
    taxa_acerto = round(as.numeric(gsub(",", ".", taxa_acerto)), 4),
    dificuldade = round(as.numeric(gsub(",", ".", dificuldade)), 4),
    r_biserial = round(as.numeric(gsub(",", ".", r_biserial)), 4)
  )

writeData(wb, "Analise_TCT", tct_fmt, startRow = 3, startCol = 1, borders = "all")
addStyle(wb, "Analise_TCT", header_style, rows = 3, cols = 1:ncol(tct_fmt))

# Destacar itens com problema
for (i in 1:nrow(tct_fmt)) {
  if (tct_fmt$status[i] != "OK") {
    addStyle(wb, "Analise_TCT", reprovado_style, rows = 3 + i, cols = 1:ncol(tct_fmt), stack = TRUE)
  }
}

# Resumo de itens problemáticos
writeData(wb, "Analise_TCT", "Itens para Revisar", startRow = 3, startCol = 10)
addStyle(wb, "Analise_TCT", subtitulo_style, rows = 3, cols = 10)

itens_problema <- tct_fmt %>% filter(status != "OK")
if (nrow(itens_problema) > 0) {
  writeData(wb, "Analise_TCT", itens_problema %>% select(item, posicao, r_biserial, status), 
            startRow = 4, startCol = 10, borders = "all")
} else {
  writeData(wb, "Analise_TCT", "Nenhum item problemático identificado", 
            startRow = 4, startCol = 10)
}

# Ajustar larguras
setColWidths(wb, "Analise_TCT", cols = 1:ncol(tct_fmt), widths = 18)

# ============================================================================
# 6. ABA 4 - DASHBOARD DE ANÁLISE
# ============================================================================
cat("    Criando aba: Dashboard de Análise...\n")

addWorksheet(wb, "Dashboard", gridLines = FALSE)

# Título principal
writeData(wb, "Dashboard", "DASHBOARD DE ANÁLISE - ENAMED", startRow = 1, startCol = 1)
addStyle(wb, "Dashboard", titulo_style, rows = 1, cols = 1)

# KPIs em destaque
writeData(wb, "Dashboard", "Indicadores Principais", startRow = 3, startCol = 1)
addStyle(wb, "Dashboard", subtitulo_style, rows = 3, cols = 1)

kpis <- data.frame(
  Indicador = c("Total Candidatos", "Nota Média", "Taxa Aprovação", "Itens Problemáticos", "Theta Médio"),
  Valor = c(nrow(resultados),
            paste0(round(mean(resultados$nota_enamed_estimada), 1)),
            paste0(round(100*sum(resultados$classificacao == "APROVADO")/nrow(resultados), 1), "%"),
            sum(tct_fmt$status != "OK"),
            paste0(round(mean(resultados$theta), 3)))
)
writeData(wb, "Dashboard", kpis, startRow = 4, startCol = 1, borders = "all")
addStyle(wb, "Dashboard", header_style, rows = 4, cols = 1:2)

# Ranking Top 20
writeData(wb, "Dashboard", "Top 20 Candidatos", startRow = 3, startCol = 5)
addStyle(wb, "Dashboard", subtitulo_style, rows = 3, cols = 5)

top20 <- resultados_fmt %>% 
  filter(Rank <= 20) %>%
  select(Rank, nome, acertos, nota_enamed_estimada)
writeData(wb, "Dashboard", top20, startRow = 4, startCol = 5, borders = "all")
addStyle(wb, "Dashboard", header_style, rows = 4, cols = 5:8)

# Distribuição de classificação
writeData(wb, "Dashboard", "Distribuição por Classificação", startRow = 3, startCol = 10)
addStyle(wb, "Dashboard", subtitulo_style, rows = 3, cols = 10)

classif_dist <- resultados_fmt %>%
  count(classificacao) %>%
  mutate(Pct = round(100 * n / sum(n), 1))
writeData(wb, "Dashboard", classif_dist, startRow = 4, startCol = 10, borders = "all")

# Inserir gráficos (imagens)
if (file.exists("output/correcao_enamed/distribuicao_notas.png")) {
  cat("    Inserindo gráficos...\n")
  insertImage(wb, "Dashboard", "output/correcao_enamed/distribuicao_notas.png",
              startRow = 26, startCol = 1, width = 10, height = 6)
}

if (file.exists("output/correcao_enamed/dificuldade_itens.png")) {
  insertImage(wb, "Dashboard", "output/correcao_enamed/dificuldade_itens.png",
              startRow = 26, startCol = 8, width = 12, height = 3)
}

# Ajustar larguras
setColWidths(wb, "Dashboard", cols = 1:2, widths = 20)
setColWidths(wb, "Dashboard", cols = 3:4, widths = 15)
setColWidths(wb, "Dashboard", cols = 5, widths = 8)
setColWidths(wb, "Dashboard", cols = 6, widths = 30)
setColWidths(wb, "Dashboard", cols = 7:8, widths = 12)

# ============================================================================
# 7. ABA 5 - DISTRIBUIÇÃO DE NOTAS (DADOS PARA GRÁFICO)
# ============================================================================
cat("    Criando aba: Dados para Gráficos...\n")

addWorksheet(wb, "Dados_Graficos", gridLines = FALSE)

# Faixas de nota para histograma
faixas <- cut(resultados$nota_enamed_estimada, breaks = seq(0, 100, by = 5), 
              include.lowest = TRUE)
dist_faixas <- as.data.frame(table(faixas))
colnames(dist_faixas) <- c("Faixa_Nota", "Frequencia")

writeData(wb, "Dados_Graficos", "Distribuição por Faixas", startRow = 1, startCol = 1)
writeData(wb, "Dados_Graficos", dist_faixas, startRow = 2, startCol = 1, borders = "all")
addStyle(wb, "Dados_Graficos", header_style, rows = 2, cols = 1:2)

# Nota: Para criar gráficos nativos do Excel, selecione os dados na aba
# Dados_Graficos e insira um gráfico de colunas manualmente
writeData(wb, "Dados_Graficos", 
          "Dica: Selecione os dados acima e insira um gráfico de colunas no Excel",
          startRow = 2, startCol = 5)

# ============================================================================
# 8. SALVAR ARQUIVO
# ============================================================================
cat("\n[3/4] Salvando arquivo Excel...\n")

output_file <- "output/RELATORIO_ENAMED_COMPLETO.xlsx"
saveWorkbook(wb, output_file, overwrite = TRUE)

cat(sprintf("    ✓ Arquivo salvo: %s\n", output_file))

# ============================================================================
# 9. RESUMO FINAL
# ============================================================================
cat("\n[4/4] Resumo do relatório:\n")
cat("------------------------------------------------------------\n")
cat(sprintf("  Total de candidatos:  %d\n", nrow(resultados)))
cat(sprintf("  Nota média:           %.2f\n", mean(resultados$nota_enamed_estimada)))
cat(sprintf("  Taxa de aprovação:    %.1f%%\n", 
            100*sum(resultados$classificacao == "APROVADO")/nrow(resultados)))
cat(sprintf("  Itens problemáticos:  %d\n", sum(tct_fmt$status != "OK")))
cat("\n")
cat("  Abas criadas:\n")
cat("    1. Resultados      - Notas de todos os candidatos\n")
cat("    2. Itens_TRI       - Parâmetros dos 100 itens\n")
cat("    3. Analise_TCT     - Estatísticas TCT detalhadas\n")
cat("    4. Dashboard       - Resumo com gráficos\n")
cat("    5. Dados_Graficos  - Dados para análise\n")
cat("------------------------------------------------------------\n")
cat("  Relatório concluído com sucesso!\n")
cat("============================================================\n")
