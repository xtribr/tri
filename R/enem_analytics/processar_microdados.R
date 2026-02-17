#!/usr/bin/env Rscript
# Processador de Microdados ENEM
# Gera tabelas de amplitude (MIN/MED/MAX) e estatísticas por escola

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(data.table)
  library(jsonlite)
  library(parallel)
})

#' Processa arquivo de resultados ENEM e gera estatísticas
#' @param arquivo_csv Caminho para RESULTADOS_YYYY.csv
#' @param ano Ano do ENEM
#' @return Lista com estatísticas e tabelas
processar_enem <- function(arquivo_csv, ano) {
  
  message(sprintf("Processando ENEM %d...", ano))
  message(sprintf("Arquivo: %s", arquivo_csv))
  
  # Ler dados (arquivo grande, usar fread)
  message("Lendo CSV...")
  dados <- fread(arquivo_csv, sep = ";", encoding = "Latin-1", 
                 showProgress = TRUE, nThread = detectCores() - 1)
  
  message(sprintf("Total de registros: %s", format(nrow(dados), big.mark = ".")))
  
  # Áreas de conhecimento
  areas <- list(
    CH = list(nota_col = "NU_NOTA_CH", presenca_col = "TP_PRESENCA_CH", n_itens = 45),
    CN = list(nota_col = "NU_NOTA_CN", presenca_col = "TP_PRESENCA_CN", n_itens = 45),
    LC = list(nota_col = "NU_NOTA_LC", presenca_col = "TP_PRESENCA_LC", n_itens = 50),
    MT = list(nota_col = "NU_NOTA_MT", presenca_col = "TP_PRESENCA_MT", n_itens = 45)
  )
  
  resultados <- list()
  
  for (area_cod in names(areas)) {
    area_info <- areas[[area_cod]]
    message(sprintf("\nProcessando área: %s", area_cod))
    
    # Filtrar presentes e com nota válida
    area_dados <- dados %>%
      filter(.data[[area_info$presenca_col]] == 1,
             !is.na(.data[[area_info$nota_col]]),
             .data[[area_info$nota_col]] > 0) %>%
      select(
        NU_SEQUENCIAL,
        CO_ESCOLA,
        NOTA = all_of(area_info$nota_col),
        TP_DEPENDENCIA_ADM_ESC,
        TP_LOCALIZACAO_ESC,
        CO_MUNICIPIO_ESC,
        SG_UF_ESC
      )
    
    n_presentes <- nrow(area_dados)
    message(sprintf("  Presentes válidos: %s", format(n_presentes, big.mark = ".")))
    
    # Gerar tabela de amplitude (percentis)
    tabela_amplitude <- gerar_tabela_amplitude(area_dados$NOTA, area_info$n_itens)
    
    # Estatísticas descritivas
    stats_descritivas <- list(
      n_presentes = n_presentes,
      n_faltantes = nrow(dados) - n_presentes,
      media = mean(area_dados$NOTA, na.rm = TRUE),
      mediana = median(area_dados$NOTA, na.rm = TRUE),
      dp = sd(area_dados$NOTA, na.rm = TRUE),
      min = min(area_dados$NOTA, na.rm = TRUE),
      max = max(area_dados$NOTA, na.rm = TRUE),
      p10 = quantile(area_dados$NOTA, 0.10, na.rm = TRUE),
      p25 = quantile(area_dados$NOTA, 0.25, na.rm = TRUE),
      p75 = quantile(area_dados$NOTA, 0.75, na.rm = TRUE),
      p90 = quantile(area_dados$NOTA, 0.90, na.rm = TRUE)
    )
    
    # Estatísticas por escola (apenas escolas com >10 alunos)
    stats_escolas <- area_dados %>%
      filter(!is.na(CO_ESCOLA), CO_ESCOLA > 0) %>%
      group_by(CO_ESCOLA, TP_DEPENDENCIA_ADM_ESC, TP_LOCALIZACAO_ESC) %>%
      summarise(
        n_alunos = n(),
        media_nota = mean(NOTA, na.rm = TRUE),
        mediana_nota = median(NOTA, na.rm = TRUE),
        dp_nota = sd(NOTA, na.rm = TRUE),
        min_nota = min(NOTA, na.rm = TRUE),
        max_nota = max(NOTA, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      filter(n_alunos >= 10) %>%
      arrange(desc(media_nota))
    
    message(sprintf("  Escolas analisadas: %d", nrow(stats_escolas)))
    
    # Estatísticas por UF
    stats_uf <- area_dados %>%
      filter(!is.na(SG_UF_ESC)) %>%
      group_by(SG_UF_ESC) %>%
      summarise(
        n_alunos = n(),
        media = mean(NOTA, na.rm = TRUE),
        mediana = median(NOTA, na.rm = TRUE),
        dp = sd(NOTA, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      arrange(desc(media))
    
    resultados[[area_cod]] <- list(
      ano = ano,
      area = area_cod,
      n_itens = area_info$n_itens,
      estatisticas = stats_descritivas,
      tabela_amplitude = tabela_amplitude,
      escolas = stats_escolas,
      por_uf = stats_uf
    )
  }
  
  # Metadados gerais
  resultados$metadata <- list(
    ano = ano,
    data_processamento = Sys.time(),
    total_inscritos = nrow(dados),
    arquivo_fonte = basename(arquivo_csv),
    areas_processadas = names(areas)
  )
  
  message("\n✓ Processamento concluído!")
  return(resultados)
}

#' Gera tabela de amplitude (MIN/MED/MAX) por número de acertos
#' @param notas Vetor de notas
#' @param n_itens Número de itens na prova
#' @return Data frame com tabela de conversão
gerar_tabela_amplitude <- function(notas, n_itens) {
  
  # Ordenar notas
  notas_ordenadas <- sort(notas)
  n <- length(notas_ordenadas)
  
  # Criar tabela para cada possível número de acertos
  # Como não temos os acertos individuais, estimamos pela distribuição das notas
  tabela <- data.frame(
    acertos = 0:n_itens,
    stringsAsFactors = FALSE
  )
  
  # Calcular percentis para cada "faixa" de acertos
  # Assumindo distribuição uniforme dos acertos
  for (i in 0:n_itens) {
    # Percentil inferior (estimativa para acertos = i)
    p_low <- i / n_itens
    # Percentil superior
    p_high <- (i + 1) / n_itens
    
    # Índices na distribuição ordenada
    idx_min <- max(1, floor(p_low * n))
    idx_max <- min(n, ceiling(p_high * n))
    idx_med <- round(((idx_min + idx_max) / 2))
    
    if (idx_min <= n && idx_max <= n && idx_min > 0) {
      tabela$notaMin[i + 1] <- round(notas_ordenadas[idx_min], 1)
      tabela$notaMed[i + 1] <- round(notas_ordenadas[idx_med], 1)
      tabela$notaMax[i + 1] <- round(notas_ordenadas[idx_max], 1)
    } else {
      tabela$notaMin[i + 1] <- round(min(notas), 1)
      tabela$notaMax[i + 1] <- round(max(notas), 1)
      tabela$notaMed[i + 1] <- round(median(notas), 1)
    }
  }
  
  # Garantir monotonicidade
  for (i in 2:nrow(tabela)) {
    tabela$notaMin[i] <- max(tabela$notaMin[i], tabela$notaMin[i-1])
    tabela$notaMed[i] <- max(tabela$notaMed[i], tabela$notaMed[i-1])
    tabela$notaMax[i] <- max(tabela$notaMax[i], tabela$notaMax[i-1])
  }
  
  return(tabela)
}

#' Salva resultados em JSON
#' @param resultados Lista de resultados
#' @param output_dir Diretório de saída
salvar_resultados <- function(resultados, output_dir = "output/enem") {
  
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  ano <- resultados$metadata$ano
  
  # Salvar JSON completo
  arquivo_json <- file.path(output_dir, sprintf("enem_%d_completo.json", ano))
  write_json(resultados, arquivo_json, pretty = TRUE, auto_unbox = TRUE)
  message(sprintf("\nJSON salvo: %s", arquivo_json))
  
  # Salvar CSVs por área
  for (area in c("CH", "CN", "LC", "MT")) {
    if (!is.null(resultados[[area]])) {
      # Tabela de amplitude
      csv_amplitude <- file.path(output_dir, sprintf("tabela_%s_%d.csv", area, ano))
      write.csv(resultados[[area]]$tabela_amplitude, csv_amplitude, row.names = FALSE)
      
      # Estatísticas por escola
      csv_escolas <- file.path(output_dir, sprintf("escolas_%s_%d.csv", area, ano))
      write.csv(resultados[[area]]$escolas, csv_escolas, row.names = FALSE)
      
      message(sprintf("CSV %s salvo: %s", area, csv_amplitude))
    }
  }
  
  # Salvar metadados
  csv_meta <- file.path(output_dir, sprintf("metadata_%d.csv", ano))
  meta_df <- data.frame(
    metrica = names(resultados$metadata),
    valor = as.character(resultados$metadata),
    stringsAsFactors = FALSE
  )
  write.csv(meta_df, csv_meta, row.names = FALSE)
}

#' Compara dois anos de ENEM
#' @param resultados_ano1 Resultados do ano 1
#' @param resultados_ano2 Resultados do ano 2
#' @return Lista com comparações
comparar_anos <- function(resultados_ano1, resultados_ano2) {
  
  ano1 <- resultados_ano1$metadata$ano
  ano2 <- resultados_ano2$metadata$ano
  
  message(sprintf("\nComparando ENEM %d vs %d...", ano1, ano2))
  
  comparacoes <- list()
  
  for (area in c("CH", "CN", "LC", "MT")) {
    if (!is.null(resultados_ano1[[area]]) && !is.null(resultados_ano2[[area]])) {
      
      stats1 <- resultados_ano1[[area]]$estatisticas
      stats2 <- resultados_ano2[[area]]$estatisticas
      
      comparacao <- list(
        area = area,
        anos = c(ano1, ano2),
        delta_media = stats2$media - stats1$media,
        delta_mediana = stats2$mediana - stats1$mediana,
        delta_dp = stats2$dp - stats1$dp,
        variacao_percentual_media = ((stats2$media - stats1$media) / stats1$media) * 100,
        stats_ano1 = stats1,
        stats_ano2 = stats2
      )
      
      message(sprintf("  %s: Variação média = %+.2f pontos (%+.2f%%)",
                      area, comparacao$delta_media, comparacao$variacao_percentual_media))
      
      comparacoes[[area]] <- comparacao
    }
  }
  
  return(comparacoes)
}

# === EXECUÇÃO PRINCIPAL ===

if (!interactive()) {
  # Processar ENEM 2024
  arquivo <- "microdados/RESULTADOS_2024.csv"
  
  if (file.exists(arquivo)) {
    resultados_2024 <- processar_enem(arquivo, 2024)
    salvar_resultados(resultados_2024)
    
    # Mostrar resumo
    message("\n=== RESUMO ENEM 2024 ===")
    for (area in c("CH", "CN", "LC", "MT")) {
      stats <- resultados_2024[[area]]$estatisticas
      message(sprintf("%s: Média=%.1f | DP=%.1f | N=%s",
                      area, stats$media, stats$dp, 
                      format(stats$n_presentes, big.mark = ".")))
    }
  } else {
    message("Arquivo não encontrado: ", arquivo)
  }
}
