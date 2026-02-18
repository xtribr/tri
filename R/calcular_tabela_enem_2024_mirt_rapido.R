#!/usr/bin/env Rscript
# Versão otimizada - processa em chunks

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

message("=== Cálculo Otimizado da Tabela ENEM 2024 ===")

# === PASSO 1: Ler gabaritos ===
message("\n1. Carregando gabaritos...")
itens <- fread("microdados/ITENS_PROVA_2024.csv", sep = ";", encoding = "Latin-1")

gabaritos <- list()
for (area in c("CN", "CH", "LC", "MT")) {
  gabaritos[[area]] <- list()
  area_itens <- itens[SG_AREA == area]
  if (area == "LC") area_itens <- area_itens[TP_LINGUA != 1 | is.na(TP_LINGUA)]
  
  for (prova_cod in unique(area_itens$CO_PROVA)) {
    prova_itens <- area_itens[CO_PROVA == prova_cod][order(CO_POSICAO)]
    gabaritos[[area]][[as.character(prova_cod)]] <- paste(prova_itens$TX_GABARITO, collapse="")
  }
}

message(sprintf("  Gabaritos: CN=%d, CH=%d, LC=%d, MT=%d", 
                length(gabaritos$CN), length(gabaritos$CH), 
                length(gabaritos$LC), length(gabaritos$MT)))

# === PASSO 2 & 3: Processar em chunks ===
message("\n2. Processando dados em chunks...")

areas_info <- list(
  MT = list(n = 45, col_nota = "NU_NOTA_MT", col_resp = "TX_RESPOSTAS_MT", col_prova = "CO_PROVA_MT", col_pres = "TP_PRESENCA_MT"),
  CH = list(n = 45, col_nota = "NU_NOTA_CH", col_resp = "TX_RESPOSTAS_CH", col_prova = "CO_PROVA_CH", col_pres = "TP_PRESENCA_CH"),
  CN = list(n = 45, col_nota = "NU_NOTA_CN", col_resp = "TX_RESPOSTAS_CN", col_prova = "CO_PROVA_CN", col_pres = "TP_PRESENCA_CN"),
  LC = list(n = 45, col_nota = "NU_NOTA_LC", col_resp = "TX_RESPOSTAS_LC", col_prova = "CO_PROVA_LC", col_pres = "TP_PRESENCA_LC")
)

# Acumuladores
dados_area <- list(MT = list(acertos=c(), notas=c()),
                   CH = list(acertos=c(), notas=c()),
                   CN = list(acertos=c(), notas=c()),
                   LC = list(acertos=c(), notas=c()))

chunk_size <- 500000
chunk_num <- 0

repeat {
  chunk_num <- chunk_num + 1
  skip_rows <- (chunk_num - 1) * chunk_size
  
  message(sprintf("\n  Chunk %d (skip=%d)...", chunk_num, skip_rows))
  
  chunk <- tryCatch({
    fread("microdados/RESULTADOS_2024.csv", sep = ";", encoding = "Latin-1",
          select = c("NU_NOTA_MT", "NU_NOTA_CH", "NU_NOTA_LC", "NU_NOTA_CN",
                     "TX_RESPOSTAS_MT", "TX_RESPOSTAS_CH", "TX_RESPOSTAS_LC", "TX_RESPOSTAS_CN",
                     "CO_PROVA_MT", "CO_PROVA_CH", "CO_PROVA_LC", "CO_PROVA_CN",
                     "TP_PRESENCA_MT", "TP_PRESENCA_CH", "TP_PRESENCA_LC", "TP_PRESENCA_CN"),
          nrows = chunk_size, skip = skip_rows + 1)  # +1 para pular header no skip
  }, error = function(e) NULL)
  
  if (is.null(chunk) || nrow(chunk) == 0) break
  
  # Processar cada área
  for (area in names(areas_info)) {
    info <- areas_info[[area]]
    
    # Filtrar presentes
    cand <- chunk[get(info$col_pres) == 1 & !is.na(get(info$col_nota)) & 
                  get(info$col_nota) > 0 & !is.na(get(info$col_resp)) &
                  !is.na(get(info$col_prova))]
    
    if (nrow(cand) == 0) next
    
    # Vetorizar cálculo de acertos
    for (prova_cod in unique(cand[[info$col_prova]])) {
      prova_str <- as.character(prova_cod)
      if (!(prova_str %in% names(gabaritos[[area]]))) next
      
      gab <- gabaritos[[area]][[prova_str]]
      n_itens <- nchar(gab)
      
      # Candidatos desta prova
      idx <- cand[[info$col_prova]] == prova_cod
      resps <- cand[[info$col_resp]][idx]
      notas <- cand[[info$col_nota]][idx]
      
      # Calcular acertos (vetorizado)
      acertos <- sapply(resps, function(r) {
        if (nchar(r) < n_itens) return(NA)
        resp_vec <- strsplit(substr(r, 1, n_itens), "")[[1]]
        gab_vec <- strsplit(gab, "")[[1]]
        sum(resp_vec == gab_vec, na.rm = TRUE)
      })
      
      # Guardar válidos
      validos <- !is.na(acertos) & acertos >= 0 & acertos <= info$n
      dados_area[[area]]$acertos <- c(dados_area[[area]]$acertos, acertos[validos])
      dados_area[[area]]$notas <- c(dados_area[[area]]$notas, notas[validos])
    }
  }
  
  message(sprintf("    Acumulado: MT=%d, CH=%d, CN=%d, LC=%d",
                  length(dados_area$MT$acertos), length(dados_area$CH$acertos),
                  length(dados_area$CN$acertos), length(dados_area$LC$acertos)))
  
  if (nrow(chunk) < chunk_size) break
}

# === PASSO 4: Gerar tabelas ===
message("\n3. Gerando tabelas finais...")

resultado <- list(
  metadata = list(
    ano = 2024,
    data_processamento = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    metodo = "mirt_microdados_reais_chunked",
    fonte = "TX_RESPOSTAS vs TX_GABARITO do INEP",
    descricao = "Acertos calculados cruzando respostas individuais com gabaritos por código de prova"
  )
)

for (area in names(areas_info)) {
  info <- areas_info[[area]]
  acertos_list <- dados_area[[area]]$acertos
  notas_list <- dados_area[[area]]$notas
  
  message(sprintf("\n  %s: %d candidatos processados", area, length(acertos_list)))
  
  if (length(acertos_list) == 0) next
  
  # Criar tabela
  tabela <- data.frame(
    acertos = 0:info$n,
    notaMin = numeric(info$n + 1),
    notaMed = numeric(info$n + 1),
    notaMax = numeric(info$n + 1)
  )
  
  for (a in 0:info$n) {
    idx <- which(acertos_list == a)
    if (length(idx) > 5) {  # Mínimo 5 candidatos
      notas_a <- notas_list[idx]
      tabela$notaMin[a + 1] <- round(min(notas_a), 1)
      tabela$notaMed[a + 1] <- round(median(notas_a), 1)
      tabela$notaMax[a + 1] <- round(max(notas_a), 1)
    } else {
      tabela$notaMin[a + 1] <- NA
      tabela$notaMed[a + 1] <- NA
      tabela$notaMax[a + 1] <- NA
    }
  }
  
  # Interpolação
  for (col in c("notaMin", "notaMed", "notaMax")) {
    col_vals <- tabela[[col]]
    if (any(is.na(col_vals))) {
      for (idx in which(is.na(col_vals))) {
        before <- suppressWarnings(max(which(!is.na(col_vals) & (1:length(col_vals)) < idx)))
        after <- suppressWarnings(min(which(!is.na(col_vals) & (1:length(col_vals)) > idx)))
        if (is.finite(before) && is.finite(after)) {
          col_vals[idx] <- mean(c(col_vals[before], col_vals[after]), na.rm = TRUE)
        } else if (is.finite(before)) {
          col_vals[idx] <- col_vals[before]
        } else if (is.finite(after)) {
          col_vals[idx] <- col_vals[after]
        }
      }
      tabela[[col]] <- col_vals
    }
  }
  
  stats <- list(
    n_presentes = length(acertos_list),
    media = round(mean(notas_list), 2),
    mediana = round(median(notas_list), 2),
    dp = round(sd(notas_list), 2),
    min = round(min(notas_list), 2),
    max = round(max(notas_list), 2)
  )
  
  resultado[[area]] <- list(
    ano = 2024,
    area = area,
    n_itens = info$n,
    estatisticas = stats,
    tabela_amplitude = tabela
  )
  
  message(sprintf("    Range: %.1f - %.1f | Média: %.1f", 
                  min(tabela$notaMin), max(tabela$notaMax), stats$media))
}

# Salvar
write_json(resultado, "frontend/public/data/enem_2024.json", pretty = TRUE, auto_unbox = TRUE)
message("\n✓ JSON salvo!")

message("\n=== RESUMO FINAL ===")
for (area in c("CH", "CN", "LC", "MT")) {
  if (area %in% names(resultado)) {
    tab <- resultado[[area]]$tabela_amplitude
    stats <- resultado[[area]]$estatisticas
    message(sprintf("%s: %.1f - %.1f | n=%d | média=%.1f", 
                  area, min(tab$notaMin), max(tab$notaMax), 
                  stats$n_presentes, stats$media))
  }
}
