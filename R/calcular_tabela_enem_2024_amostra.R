#!/usr/bin/env Rscript
# Calcula tabela ENEM 2024 usando amostra representativa (1M candidatos)

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

message("=== Cálculo da Tabela ENEM 2024 (Amostra 1M) ===")

# === PASSO 1: Ler gabaritos ===
message("\n1. Carregando gabaritos...")
itens <- fread("microdados/ITENS_PROVA_2024.csv", sep = ";", encoding = "Latin-1")

gabaritos <- list(MT=list(), CH=list(), CN=list(), LC=list())

for (area in names(gabaritos)) {
  area_itens <- itens[SG_AREA == area]
  if (area == "LC") area_itens <- area_itens[TP_LINGUA != 1 | is.na(TP_LINGUA)]
  
  for (prova_cod in unique(area_itens$CO_PROVA)) {
    prova_itens <- area_itens[CO_PROVA == prova_cod][order(CO_POSICAO)]
    gabaritos[[area]][[as.character(prova_cod)]] <- prova_itens$TX_GABARITO
  }
}

for (area in names(gabaritos)) {
  primeiro <- gabaritos[[area]][[1]]
  message(sprintf("  %s: %d provas (%d itens)", area, length(gabaritos[[area]]), length(primeiro)))
}

# === PASSO 2: Ler amostra ===
message("\n2. Carregando amostra de 1M candidatos...")

set.seed(42)
amostra_n <- 1000000

# Ler primeiro para pegar schema
temp <- fread("microdados/RESULTADOS_2024.csv", sep = ";", nrows=10)
total_rows <- 4332944  # Sabemos o total

# Gerar índices aleatórios
sample_idx <- sort(sample(2:total_rows, amostra_n))  # Começa em 2 (pula header)

# Ler dados em chunks e manter apenas os índices desejados
message("  Lendo dados...")
dados_full <- fread("microdados/RESULTADOS_2024.csv", sep = ";", encoding = "Latin-1",
                    select = c("NU_NOTA_MT", "NU_NOTA_CH", "NU_NOTA_LC", "NU_NOTA_CN",
                               "TX_RESPOSTAS_MT", "TX_RESPOSTAS_CH", "TX_RESPOSTAS_LC", "TX_RESPOSTAS_CN",
                               "CO_PROVA_MT", "CO_PROVA_CH", "CO_PROVA_LC", "CO_PROVA_CN",
                               "TP_PRESENCA_MT", "TP_PRESENCA_CH", "TP_PRESENCA_LC", "TP_PRESENCA_CN"))

# Amostrar
dados <- dados_full[sample(.N, amostra_n)]
rm(dados_full)
gc()

message(sprintf("  Amostra: %d candidatos", nrow(dados)))

# === PASSO 3: Processar ===
message("\n3. Calculando acertos...")

areas_config <- list(
  MT = list(n=45, nota="NU_NOTA_MT", resp="TX_RESPOSTAS_MT", prova="CO_PROVA_MT", pres="TP_PRESENCA_MT"),
  CH = list(n=45, nota="NU_NOTA_CH", resp="TX_RESPOSTAS_CH", prova="CO_PROVA_CH", pres="TP_PRESENCA_CH"),
  CN = list(n=45, nota="NU_NOTA_CN", resp="TX_RESPOSTAS_CN", prova="CO_PROVA_CN", pres="TP_PRESENCA_CN"),
  LC = list(n=45, nota="NU_NOTA_LC", resp="TX_RESPOSTAS_LC", prova="CO_PROVA_LC", pres="TP_PRESENCA_LC")
)

resultado <- list(
  metadata = list(
    ano = 2024,
    data_processamento = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    metodo = "mirt_microdados_amostra_1m",
    fonte = "INEP - TX_RESPOSTAS vs TX_GABARITO",
    amostra = amostra_n
  )
)

calc_acertos <- function(resp_str, gab_vec) {
  if (is.na(resp_str) || length(gab_vec) == 0) return(NA)
  n <- length(gab_vec)
  if (nchar(resp_str) < n) return(NA)
  resps <- strsplit(substr(resp_str, 1, n), "")[[1]]
  if (length(resps) != n) return(NA)
  sum(resps == gab_vec, na.rm = TRUE)
}

for (area in names(areas_config)) {
  cfg <- areas_config[[area]]
  message(sprintf("\n  %s...", area))
  
  # Filtrar presentes
  cand <- dados[get(cfg$pres) == 1 & 
                !is.na(get(cfg$nota)) & get(cfg$nota) > 0 &
                !is.na(get(cfg$resp)) &
                !is.na(get(cfg$prova))]
  
  message(sprintf("    Presentes: %d", nrow(cand)))
  
  # Calcular acertos um a um (não é ideal mas funciona para 1M)
  acertos <- c()
  notas <- c()
  
  for (i in 1:nrow(cand)) {
    prova_cod <- as.character(cand[[cfg$prova]][i])
    if (prova_cod %in% names(gabaritos[[area]])) {
      gab <- gabaritos[[area]][[prova_cod]]
      resp <- cand[[cfg$resp]][i]
      n_acert <- calc_acertos(resp, gab)
      if (!is.na(n_acert) && n_acert >= 0 && n_acert <= cfg$n) {
        acertos <- c(acertos, n_acert)
        notas <- c(notas, cand[[cfg$nota]][i])
      }
    }
    
    if (i %% 50000 == 0) message(sprintf("      %d...", i))
  }
  
  message(sprintf("    Calculados: %d", length(acertos)))
  
  # Tabela
  tabela <- data.frame(acertos = 0:cfg$n, notaMin = NA_real_, notaMed = NA_real_, notaMax = NA_real_)
  
  for (a in 0:cfg$n) {
    mask <- acertos == a
    if (sum(mask, na.rm=TRUE) > 0) {
      notas_a <- notas[mask]
      tabela$notaMin[a+1] <- round(min(notas_a), 1)
      tabela$notaMed[a+1] <- round(median(notas_a), 1)
      tabela$notaMax[a+1] <- round(max(notas_a), 1)
    }
  }
  
  # Interpolação
  for (col in c("notaMin", "notaMed", "notaMax")) {
    if (any(is.na(tabela[[col]]))) {
      tabela[[col]] <- approx(0:cfg$n, tabela[[col]], 0:cfg$n, rule=2)$y
    }
  }
  
  stats <- list(
    n_presentes = length(acertos),
    media = round(mean(notas), 2),
    mediana = round(median(notas), 2),
    dp = round(sd(notas), 2),
    min = round(min(notas), 2),
    max = round(max(notas), 2)
  )
  
  resultado[[area]] <- list(ano=2024, area=area, n_itens=cfg$n,
                            estatisticas=stats, tabela_amplitude=tabela)
  
  message(sprintf("    Range: %.1f - %.1f", min(tabela$notaMin), max(tabela$notaMax)))
}

write_json(resultado, "frontend/public/data/enem_2024.json", pretty=TRUE, auto_unbox=TRUE)
message("\n✓ JSON salvo!")

message("\n=== COMPARAÇÃO MT vs OFICIAL ===")
tab_mt <- resultado$MT$tabela_amplitude
oficial <- c(371, 404.8, 468.9, 584, 667.2, 717.2, 762.8, 810, 868.4, 961.9)
for (i in seq(0, 45, 5)) {
  diff <- tab_mt$notaMed[i+1] - oficial[i/5 + 1]
  message(sprintf("Acerto %2d: Calculado=%.1f | Oficial=%.1f | Δ=%+.1f", 
                i, tab_mt$notaMed[i+1], oficial[i/5 + 1], diff))
}
