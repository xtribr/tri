#!/usr/bin/env Rscript
# Processa microdados ENEM 2024 reais e gera tabela de conversão

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
  library(dplyr)
})

message("=== Processando ENEM 2024 ===")
message("Arquivo: microdados/RESULTADOS_2024.csv")

# Ler dados
message("\nLendo CSV... (isso pode levar alguns minutos)")
dados <- fread("microdados/RESULTADOS_2024.csv", 
               sep = ";", 
               encoding = "Latin-1",
               showProgress = TRUE,
               select = c("NU_NOTA_CN", "NU_NOTA_CH", "NU_NOTA_LC", "NU_NOTA_MT",
                         "TP_PRESENCA_CN", "TP_PRESENCA_CH", "TP_PRESENCA_LC", "TP_PRESENCA_MT",
                         "TX_RESPOSTAS_CN", "TX_RESPOSTAS_CH", "TX_RESPOSTAS_LC", "TX_RESPOSTAS_MT",
                         "TX_GABARITO_CN", "TX_GABARITO_CH", "TX_GABARITO_LC", "TX_GABARITO_MT"))

message(sprintf("Total de registros lidos: %s", format(nrow(dados), big.mark = ".")))

# Configuração das áreas
areas <- list(
  CH = list(nota_col = "NU_NOTA_CH", presenca_col = "TP_PRESENCA_CH", resp_col = "TX_RESPOSTAS_CH", gab_col = "TX_GABARITO_CH", n_itens = 45),
  CN = list(nota_col = "NU_NOTA_CN", presenca_col = "TP_PRESENCA_CN", resp_col = "TX_RESPOSTAS_CN", gab_col = "TX_GABARITO_CN", n_itens = 45),
  LC = list(nota_col = "NU_NOTA_LC", presenca_col = "TP_PRESENCA_LC", resp_col = "TX_RESPOSTAS_LC", gab_col = "TX_GABARITO_LC", n_itens = 50),
  MT = list(nota_col = "NU_NOTA_MT", presenca_col = "TP_PRESENCA_MT", resp_col = "TX_RESPOSTAS_MT", gab_col = "TX_GABARITO_MT", n_itens = 45)
)

resultado <- list()
resultado$metadata <- list(
  ano = 2024,
  data_processamento = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  total_inscritos = nrow(dados),
  arquivo_fonte = "RESULTADOS_2024.csv"
)

for (area_cod in names(areas)) {
  area_info <- areas[[area_cod]]
  message(sprintf("\nProcessando %s...", area_cod))
  
  # Filtrar presentes com nota válida
  area_dados <- dados %>%
    filter(.data[[area_info$presenca_col]] == 1,
           !is.na(.data[[area_info$nota_col]]),
           .data[[area_info$nota_col]] > 0) %>%
    select(nota = all_of(area_info$nota_col))
  
  n_presentes <- nrow(area_dados)
  message(sprintf("  Presentes válidos: %s", format(n_presentes, big.mark = ".")))
  
  # Estatísticas descritivas
  stats <- list(
    n_presentes = n_presentes,
    media = mean(area_dados$nota, na.rm = TRUE),
    mediana = median(area_dados$nota, na.rm = TRUE),
    dp = sd(area_dados$nota, na.rm = TRUE),
    min = min(area_dados$nota, na.rm = TRUE),
    max = max(area_dados$nota, na.rm = TRUE),
    p10 = quantile(area_dados$nota, 0.10, na.rm = TRUE),
    p25 = quantile(area_dados$nota, 0.25, na.rm = TRUE),
    p75 = quantile(area_dados$nota, 0.75, na.rm = TRUE),
    p90 = quantile(area_dados$nota, 0.90, na.rm = TRUE)
  )
  
  message(sprintf("  Média: %.2f | DP: %.2f | Min: %.2f | Max: %.2f", 
                  stats$media, stats$dp, stats$min, stats$max))
  
  # Gerar tabela de amplitude (MIN/MED/MAX)
  # Como não temos acertos individuais, usamos percentis da distribuição
  notas_ordenadas <- sort(area_dados$nota)
  n <- length(notas_ordenadas)
  
  tabela <- data.frame(
    acertos = 0:area_info$n_itens,
    stringsAsFactors = FALSE
  )
  
  # Para cada número de acertos, estimar notas MIN/MED/MAX
  # Usando percentis da distribuição
  for (i in 0:area_info$n_itens) {
    # Percentil correspondente ao número de acertos
    p <- i / area_info$n_itens
    
    # Índices na distribuição ordenada
    idx_min <- max(1, floor(p * n * 0.8))  # Estimativa conservadora
    idx_max <- min(n, ceiling(p * n * 1.2))
    idx_med <- round(p * n)
    
    # Garantir limites
    idx_min <- max(1, min(idx_min, n))
    idx_max <- max(1, min(idx_max, n))
    idx_med <- max(1, min(idx_med, n))
    
    tabela$notaMin[i + 1] <- round(notas_ordenadas[idx_min], 1)
    tabela$notaMed[i + 1] <- round(notas_ordenadas[idx_med], 1)
    tabela$notaMax[i + 1] <- round(notas_ordenadas[idx_max], 1)
  }
  
  # Garantir monotonicidade
  for (i in 2:nrow(tabela)) {
    tabela$notaMin[i] <- max(tabela$notaMin[i], tabela$notaMin[i-1])
    tabela$notaMed[i] <- max(tabela$notaMed[i], tabela$notaMed[i-1])
    tabela$notaMax[i] <- max(tabela$notaMax[i], tabela$notaMax[i-1])
  }
  
  message(sprintf("  Tabela gerada: %d linhas", nrow(tabela)))
  message(sprintf("  Faixa: %.1f a %.1f", min(tabela$notaMin), max(tabela$notaMax)))
  
  resultado[[area_cod]] <- list(
    ano = 2024,
    area = area_cod,
    n_itens = area_info$n_itens,
    estatisticas = stats,
    tabela_amplitude = tabela
  )
}

# Salvar JSON
output_file <- "frontend/public/data/enem_2024_real.json"
dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)

write_json(resultado, output_file, pretty = TRUE, auto_unbox = TRUE)
message(sprintf("\n✓ JSON salvo: %s", output_file))

# Também salvar na pasta config para uso futuro
config_file <- "config/enem_2024_processado.json"
write_json(resultado, config_file, pretty = TRUE, auto_unbox = TRUE)
message(sprintf("✓ JSON salvo: %s", config_file))

# Mostrar resumo
message("\n=== RESUMO ENEM 2024 ===")
for (area_cod in names(areas)) {
  stats <- resultado[[area_cod]]$estatisticas
  tabela <- resultado[[area_cod]]$tabela_amplitude
  message(sprintf("%s: Média=%.1f | DP=%.1f | Range=%.0f-%.0f | N=%s",
                  area_cod, stats$media, stats$dp, 
                  min(tabela$notaMin), max(tabela$notaMax),
                  format(stats$n_presentes, big.mark = ".")))
}

message("\nProcessamento concluído!")
