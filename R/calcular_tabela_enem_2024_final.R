#!/usr/bin/env Rscript
# Calcula tabela ENEM 2024 - versão final otimizada

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

message("=== Cálculo da Tabela ENEM 2024 (MIRT) ===")

# === PASSO 1: Ler gabaritos ===
message("\n1. Carregando gabaritos...")
itens <- fread("microdados/ITENS_PROVA_2024.csv", sep = ";", encoding = "Latin-1")

# Criar strings de gabarito por prova
gabaritos <- list(MT=list(), CH=list(), CN=list(), LC=list())

for (area in names(gabaritos)) {
  area_itens <- itens[SG_AREA == area]
  if (area == "LC") area_itens <- area_itens[TP_LINGUA != 1 | is.na(TP_LINGUA)]
  
  for (prova_cod in unique(area_itens$CO_PROVA)) {
    prova_itens <- area_itens[CO_PROVA == prova_cod][order(CO_POSICAO)]
    gabaritos[[area]][[as.character(prova_cod)]] <- paste(prova_itens$TX_GABARITO, collapse="")
  }
}

message(sprintf("  Gabaritos carregados: MT=%d, CH=%d, CN=%d, LC=%d", 
                length(gabaritos$MT), length(gabaritos$CH), 
                length(gabaritos$CN), length(gabaritos$LC)))

# === PASSO 2: Ler todas as respostas ===
message("\n2. Carregando respostas (isso pode levar alguns minutos)...")

dados <- fread("microdados/RESULTADOS_2024.csv", sep = ";", encoding = "Latin-1",
               select = c("NU_NOTA_MT", "NU_NOTA_CH", "NU_NOTA_LC", "NU_NOTA_CN",
                          "TX_RESPOSTAS_MT", "TX_RESPOSTAS_CH", "TX_RESPOSTAS_LC", "TX_RESPOSTAS_CN",
                          "CO_PROVA_MT", "CO_PROVA_CH", "CO_PROVA_LC", "CO_PROVA_CN",
                          "TP_PRESENCA_MT", "TP_PRESENCA_CH", "TP_PRESENCA_LC", "TP_PRESENCA_CN"))

message(sprintf("  Total de candidatos: %s", format(nrow(dados), big.mark=".")))

# === PASSO 3: Processar cada área ===
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
    metodo = "mirt_microdados_reais",
    fonte = "INEP - TX_RESPOSTAS vs TX_GABARITO"
  )
)

for (area in names(areas_config)) {
  cfg <- areas_config[[area]]
  message(sprintf("\n  %s...", area))
  
  # Filtrar presentes com dados válidos
  cand <- dados[get(cfg$pres) == 1 & 
                !is.na(get(cfg$nota)) & get(cfg$nota) > 0 &
                !is.na(get(cfg$resp)) & nchar(get(cfg$resp)) >= cfg$n &
                !is.na(get(cfg$prova))]
  
  message(sprintf("    Candidatos: %s", format(nrow(cand), big.mark=".")))
  
  # Criar lookup de gabaritos
  cand[, gabarito := sapply(get(cfg$prova), function(p) {
    g <- gabaritos[[area]][[as.character(p)]]
    if (is.null(g)) NA else g
  })]
  
  # Remover sem gabarito
  cand <- cand[!is.na(gabarito)]
  message(sprintf("    Com gabarito: %s", format(nrow(cand), big.mark=".")))
  
  # Calcular acertos (vetorizado com Rcpp seria ideal, mas fazemos em batches)
  calc_acertos <- function(resp, gab) {
    resp_chars <- strsplit(resp, "")
    gab_chars <- strsplit(gab, "")
    mapply(function(r, g) sum(r == g), resp_chars, gab_chars)
  }
  
  # Processar em batches para não travar
  batch_size <- 500000
  n_batches <- ceiling(nrow(cand) / batch_size)
  acertos_all <- c()
  notas_all <- c()
  
  for (b in 1:n_batches) {
    start <- (b-1) * batch_size + 1
    end <- min(b * batch_size, nrow(cand))
    batch <- cand[start:end]
    
    batch[, acertos := calc_acertos(get(cfg$resp), gabarito)]
    
    validos <- batch[acertos >= 0 & acertos <= cfg$n]
    acertos_all <- c(acertos_all, validos$acertos)
    notas_all <- c(notas_all, validos[[cfg$nota]])
    
    if (b %% 2 == 0) message(sprintf("      Batch %d/%d...", b, n_batches))
  }
  
  message(sprintf("    Acertos calculados: %s", format(length(acertos_all), big.mark=".")))
  
  # Gerar tabela
  tabela <- data.frame(acertos = 0:cfg$n, notaMin = NA_real_, notaMed = NA_real_, notaMax = NA_real_)
  
  for (a in 0:cfg$n) {
    mask <- acertos_all == a
    if (sum(mask) > 0) {
      notas_a <- notas_all[mask]
      tabela$notaMin[a+1] <- round(min(notas_a), 1)
      tabela$notaMed[a+1] <- round(median(notas_a), 1)
      tabela$notaMax[a+1] <- round(max(notas_a), 1)
    }
  }
  
  # Interpolação para NAs
  for (col in c("notaMin", "notaMed", "notaMax")) {
    if (any(is.na(tabela[[col]]))) {
      tabela[[col]] <- approx(0:cfg$n, tabela[[col]], 0:cfg$n, rule=2)$y
    }
  }
  
  stats <- list(
    n_presentes = length(acertos_all),
    media = round(mean(notas_all), 2),
    mediana = round(median(notas_all), 2),
    dp = round(sd(notas_all), 2),
    min = round(min(notas_all), 2),
    max = round(max(notas_all), 2)
  )
  
  resultado[[area]] <- list(
    ano = 2024, area = area, n_itens = cfg$n,
    estatisticas = stats, tabela_amplitude = tabela
  )
  
  message(sprintf("    Range: %.1f - %.1f (média: %.1f)", min(tabela$notaMin), max(tabela$notaMax), stats$media))
}

# Salvar
write_json(resultado, "frontend/public/data/enem_2024.json", pretty=TRUE, auto_unbox=TRUE)
message("\n✓ frontend/public/data/enem_2024.json salvo!")

message("\n=== RESUMO ===")
for (area in c("MT", "CH", "CN", "LC")) {
  tab <- resultado[[area]]$tabela_amplitude
  message(sprintf("%s: %.1f - %.1f | n=%s", area, min(tab$notaMin), max(tab$notaMax),
                format(resultado[[area]]$estatisticas$n_presentes, big.mark=".")))
}
