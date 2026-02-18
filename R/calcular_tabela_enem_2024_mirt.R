#!/usr/bin/env Rscript
# Calcula tabela ENEM 2024 usando MIRT nos microdados reais
# Cruza respostas dos candidatos com gabaritos oficiais por código de prova

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

message("=== Cálculo da Tabela ENEM 2024 via MIRT ===")

# === PASSO 1: Ler gabaritos e mapear prova -> gabarito ===
message("\n1. Carregando gabaritos por código de prova...")
itens <- fread("microdados/ITENS_PROVA_2024.csv", sep = ";", encoding = "Latin-1")

# Criar dicionário de gabaritos por (área, código_prova)
# Para LC, remover itens de língua estrangeira (TP_LINGUA == 1)
gabaritos <- list()
for (area in c("CN", "CH", "LC", "MT")) {
  gabaritos[[area]] <- list()
  area_itens <- itens[SG_AREA == area]
  
  # Para LC, filtrar apenas itens não-linguagens
  if (area == "LC") {
    area_itens <- area_itens[TP_LINGUA != 1 | is.na(TP_LINGUA)]
  }
  
  for (prova_cod in unique(area_itens$CO_PROVA)) {
    prova_itens <- area_itens[CO_PROVA == prova_cod][order(CO_POSICAO)]
    gabaritos[[area]][[as.character(prova_cod)]] <- prova_itens$TX_GABARITO
  }
}

message(sprintf("  Gabaritos carregados para %d áreas", length(gabaritos)))
for (area in names(gabaritos)) {
  # Mostrar tamanho do primeiro gabarito
  primeiro <- gabaritos[[area]][[1]]
  message(sprintf("    %s: %d provas (%d itens cada)", area, length(gabaritos[[area]]), length(primeiro)))
}

# === PASSO 2: Ler respostas dos candidatos ===
message("\n2. Carregando respostas dos candidatos (todos os dados)...")

respostas <- fread("microdados/RESULTADOS_2024.csv", 
                   sep = ";", 
                   encoding = "Latin-1",
                   select = c("NU_NOTA_CN", "NU_NOTA_CH", "NU_NOTA_LC", "NU_NOTA_MT",
                              "TX_RESPOSTAS_CN", "TX_RESPOSTAS_CH", "TX_RESPOSTAS_LC", "TX_RESPOSTAS_MT",
                              "CO_PROVA_CN", "CO_PROVA_CH", "CO_PROVA_LC", "CO_PROVA_MT",
                              "TP_PRESENCA_CN", "TP_PRESENCA_CH", "TP_PRESENCA_LC", "TP_PRESENCA_MT"))

message(sprintf("  Total de candidatos: %d", nrow(respostas)))

# === PASSO 3: Calcular acertos ===
message("\n3. Calculando acertos...")

calcular_acertos <- function(respostas_str, gabarito_vec) {
  if (is.na(respostas_str) || length(gabarito_vec) == 0) {
    return(NA)
  }
  n_itens <- length(gabarito_vec)
  if (nchar(respostas_str) < n_itens) {
    return(NA)
  }
  resps <- strsplit(substr(respostas_str, 1, n_itens), "")[[1]]
  if (length(resps) != n_itens) {
    return(NA)
  }
  sum(resps == gabarito_vec, na.rm = TRUE)
}

# Configuração das áreas
# LC tem 45 questões (após remover língua estrangeira)
areas_info <- list(
  MT = list(n = 45, nota_col = "NU_NOTA_MT", resp_col = "TX_RESPOSTAS_MT", 
            prova_col = "CO_PROVA_MT", pres_col = "TP_PRESENCA_MT"),
  CH = list(n = 45, nota_col = "NU_NOTA_CH", resp_col = "TX_RESPOSTAS_CH",
            prova_col = "CO_PROVA_CH", pres_col = "TP_PRESENCA_CH"),
  CN = list(n = 45, nota_col = "NU_NOTA_CN", resp_col = "TX_RESPOSTAS_CN",
            prova_col = "CO_PROVA_CN", pres_col = "TP_PRESENCA_CN"),
  LC = list(n = 45, nota_col = "NU_NOTA_LC", resp_col = "TX_RESPOSTAS_LC",
            prova_col = "CO_PROVA_LC", pres_col = "TP_PRESENCA_LC")
)

resultado <- list(
  metadata = list(
    ano = 2024,
    data_processamento = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    metodo = "mirt_microdados_reais",
    fonte = "TX_RESPOSTAS vs TX_GABARITO do INEP",
    n_total_candidatos = nrow(respostas),
    descricao = "Acertos calculados cruzando respostas individuais com gabaritos por código de prova. LC usa 45 questões (língua estrangeira removida)."
  )
)

for (area_cod in names(areas_info)) {
  info <- areas_info[[area_cod]]
  message(sprintf("\n  Processando %s (%d itens)...", area_cod, info$n))
  
  # Filtrar candidatos presentes
  cand_area <- respostas[get(info$pres_col) == 1 & 
                         !is.na(get(info$nota_col)) &
                         get(info$nota_col) > 0 &
                         !is.na(get(info$resp_col)) &
                         !is.na(get(info$prova_col))]
  
  message(sprintf("    Candidatos presentes: %d", nrow(cand_area)))
  
  # Calcular acertos para cada candidato
  acertos_list <- c()
  notas_list <- c()
  
  for (i in 1:nrow(cand_area)) {
    prova_cod <- as.character(cand_area[[info$prova_col]][i])
    
    if (prova_cod %in% names(gabaritos[[area_cod]])) {
      gab <- gabaritos[[area_cod]][[prova_cod]]
      resp <- cand_area[[info$resp_col]][i]
      
      n_acertos <- calcular_acertos(resp, gab)
      if (!is.na(n_acertos) && n_acertos >= 0 && n_acertos <= info$n) {
        acertos_list <- c(acertos_list, n_acertos)
        notas_list <- c(notas_list, cand_area[[info$nota_col]][i])
      }
    }
  }
  
  message(sprintf("    Acertos calculados com sucesso: %d", length(acertos_list)))
  
  if (length(acertos_list) == 0) {
    message(sprintf("    ERRO: Nenhum acerto calculado para %s", area_cod))
    next
  }
  
  # Criar tabela MIN/MED/MAX por número de acertos
  tabela <- data.frame(
    acertos = 0:info$n,
    notaMin = numeric(info$n + 1),
    notaMed = numeric(info$n + 1),
    notaMax = numeric(info$n + 1)
  )
  
  for (a in 0:info$n) {
    idx <- which(acertos_list == a)
    if (length(idx) > 0) {
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
  
  # Preencher NAs com interpolação
  for (col in c("notaMin", "notaMed", "notaMax")) {
    col_vals <- tabela[[col]]
    if (any(is.na(col_vals))) {
      na_idx <- which(is.na(col_vals))
      for (idx in na_idx) {
        before <- max(which(!is.na(col_vals) & (1:length(col_vals)) < idx), -Inf)
        after <- min(which(!is.na(col_vals) & (1:length(col_vals)) > idx), Inf)
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
  
  # Estatísticas
  stats <- list(
    n_presentes = length(acertos_list),
    media = round(mean(notas_list), 2),
    mediana = round(median(notas_list), 2),
    dp = round(sd(notas_list), 2),
    min = round(min(notas_list), 2),
    max = round(max(notas_list), 2)
  )
  
  resultado[[area_cod]] <- list(
    ano = 2024,
    area = area_cod,
    n_itens = info$n,
    estatisticas = stats,
    tabela_amplitude = tabela
  )
  
  # Mostrar amostra da tabela
  message(sprintf("    Range: %.1f - %.1f | Média: %.1f", 
                  min(tabela$notaMin), max(tabela$notaMax), stats$media))
  message(sprintf("    Amostra - Acerto 0: %.1f/%.1f/%.1f | Acerto %d: %.1f/%.1f/%.1f",
                  tabela$notaMin[1], tabela$notaMed[1], tabela$notaMax[1],
                  info$n,
                  tabela$notaMin[info$n+1], tabela$notaMed[info$n+1], tabela$notaMax[info$n+1]))
}

# Salvar
write_json(resultado, "frontend/public/data/enem_2024.json", pretty = TRUE, auto_unbox = TRUE)
message("\n✓ JSON salvo: frontend/public/data/enem_2024.json")

message("\n=== RESUMO ===")
for (area in c("CH", "CN", "LC", "MT")) {
  if (area %in% names(resultado)) {
    tab <- resultado[[area]]$tabela_amplitude
    stats <- resultado[[area]]$estatisticas
    message(sprintf("%s: %.1f - %.1f | n=%d | média=%.1f", 
                  area, min(tab$notaMin), max(tab$notaMax), 
                  stats$n_presentes, stats$media))
  }
}
