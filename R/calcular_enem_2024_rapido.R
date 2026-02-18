#!/usr/bin/env Rscript
# Versão rápida - amostra 100k + processamento otimizado

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

message("=== Cálculo ENEM 2024 (Amostra 100k) ===")

# === PASSO 1: Gabaritos ===
message("1. Gabaritos...")
itens <- fread("microdados/ITENS_PROVA_2024.csv", sep = ";", encoding = "Latin-1")

gabaritos <- list()
for (area in c("MT", "CH", "CN", "LC")) {
  area_itens <- itens[SG_AREA == area]
  if (area == "LC") area_itens <- area_itens[TP_LINGUA != 1 | is.na(TP_LINGUA)]
  gabaritos[[area]] <- list()
  for (prova in unique(area_itens$CO_PROVA)) {
    prova_itens <- area_itens[CO_PROVA == prova][order(CO_POSICAO)]
    gabaritos[[area]][[as.character(prova)]] <- prova_itens$TX_GABARITO
  }
}

# === PASSO 2: Dados ===
message("2. Carregando dados...")
set.seed(42)
dados <- fread("microdados/RESULTADOS_2024.csv", sep = ";", encoding = "Latin-1", nrows = 100000)

# === PASSO 3: Processar ===
message("3. Calculando...")

configs <- list(
  MT = list(n=45, nota="NU_NOTA_MT", resp="TX_RESPOSTAS_MT", prova="CO_PROVA_MT", pres="TP_PRESENCA_MT"),
  CH = list(n=45, nota="NU_NOTA_CH", resp="TX_RESPOSTAS_CH", prova="CO_PROVA_CH", pres="TP_PRESENCA_CH"),
  CN = list(n=45, nota="NU_NOTA_CN", resp="TX_RESPOSTAS_CN", prova="CO_PROVA_CN", pres="TP_PRESENCA_CN"),
  LC = list(n=45, nota="NU_NOTA_LC", resp="TX_RESPOSTAS_LC", prova="CO_PROVA_LC", pres="TP_PRESENCA_LC")
)

resultado <- list(metadata = list(ano=2024, metodo="mirt_amostra_100k", data=format(Sys.time())))

for (area in names(configs)) {
  cfg <- configs[[area]]
  message(sprintf("  %s", area))
  
  cand <- dados[get(cfg$pres) == 1 & !is.na(get(cfg$nota)) & get(cfg$nota) > 0 &
                !is.na(get(cfg$resp)) & !is.na(get(cfg$prova))]
  
  # Calcular acertos eficientemente
  acertos <- integer(nrow(cand))
  notas <- cand[[cfg$nota]]
  
  for (i in 1:nrow(cand)) {
    prova_cod <- as.character(cand[[cfg$prova]][i])
    gab <- gabaritos[[area]][[prova_cod]]
    if (!is.null(gab)) {
      resp <- cand[[cfg$resp]][i]
      if (nchar(resp) >= length(gab)) {
        resp_vec <- strsplit(substr(resp, 1, length(gab)), "")[[1]]
        acertos[i] <- sum(resp_vec == gab)
      } else {
        acertos[i] <- -1
      }
    } else {
      acertos[i] <- -1
    }
  }
  
  # Filtrar válidos
  valid <- acertos >= 0 & acertos <= cfg$n
  acertos <- acertos[valid]
  notas <- notas[valid]
  
  # Tabela
  tab <- data.frame(acertos = 0:cfg$n, notaMin = NA_real_, notaMed = NA_real_, notaMax = NA_real_)
  for (a in 0:cfg$n) {
    idx <- acertos == a
    if (sum(idx) > 0) {
      n <- notas[idx]
      tab$notaMin[a+1] <- round(min(n), 1)
      tab$notaMed[a+1] <- round(median(n), 1)
      tab$notaMax[a+1] <- round(max(n), 1)
    }
  }
  
  # Interpolação
  for (col in c("notaMin", "notaMed", "notaMax")) {
    na_idx <- which(is.na(tab[[col]]))
    if (length(na_idx) > 0) {
      valid_idx <- which(!is.na(tab[[col]]))
      tab[[col]][na_idx] <- approx(valid_idx, tab[[col]][valid_idx], na_idx, rule=2)$y
    }
  }
  
  resultado[[area]] <- list(
    ano = 2024, area = area, n_itens = cfg$n,
    estatisticas = list(n = length(acertos), media = round(mean(notas), 1)),
    tabela_amplitude = tab
  )
  
  message(sprintf("    n=%d | %.1f - %.1f", length(acertos), min(tab$notaMin), max(tab$notaMax)))
}

write_json(resultado, "frontend/public/data/enem_2024.json", pretty = TRUE, auto_unbox = TRUE)
message("\n✓ Salvo!")

# Comparação MT
message("\n=== Comparação MT ===")
tab <- resultado$MT$tabela_amplitude
ofic <- c(371, 404.8, 468.9, 584, 667.2, 717.2, 762.8, 810, 868.4, 961.9)
for (i in seq(0, 45, 5)) {
  message(sprintf("%2d acertos: Meu=%.1f | Oficial=%.1f | Δ=%+.1f", 
                i, tab$notaMed[i+1], ofic[i/5+1], tab$notaMed[i+1] - ofic[i/5+1]))
}
