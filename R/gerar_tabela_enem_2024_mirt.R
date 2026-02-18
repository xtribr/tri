#!/usr/bin/env Rscript
# Gera tabela de conversão ENEM 2024 usando MIRT
# Calcula percentis reais da distribuição

suppressPackageStartupMessages({
  library(mirt)
  library(data.table)
  library(jsonlite)
  library(dplyr)
})

message("=== Gerando Tabela ENEM 2024 com MIRT ===")

# Ler dados
message("\nLendo microdados...")
dados <- fread("microdados/RESULTADOS_2024.csv", 
               sep = ";", 
               encoding = "Latin-1",
               select = c("NU_NOTA_MT", "TP_PRESENCA_MT"))

# Filtrar presentes com nota válida
notas <- dados$NU_NOTA_MT[dados$TP_PRESENCA_MT == 1 & !is.na(dados$NU_NOTA_MT) & dados$NU_NOTA_MT > 0]
notas <- sort(notas)
n <- length(notas)

message(sprintf("Total de notas válidas: %s", format(n, big.mark = ".")))
message(sprintf("Range: %.1f a %.1f", min(notas), max(notas)))

# Gerar tabela de percentis
# Para cada número de acertos (0-45), encontrar os percentis correspondentes
gerar_tabela_percentil <- function(notas, n_acertos = 45) {
  n <- length(notas)
  tabela <- data.frame(
    acertos = 0:n_acertos,
    notaMin = numeric(n_acertos + 1),
    notaMed = numeric(n_acertos + 1),
    notaMax = numeric(n_acertos + 1)
  )
  
  # Para cada número de acertos
  for (i in 0:n_acertos) {
    # Proporção de acertos
    p <- i / n_acertos
    
    # Índices dos percentis (garantir que sejam válidos)
    idx_med <- max(1, min(n, round(p * n)))
    idx_min <- max(1, min(idx_med, floor(p * n * 0.5)))
    idx_max <- min(n, max(idx_med, ceiling(p * n + (1-p) * n * 0.3)))
    
    # Garantir ordem
    idx_min <- min(idx_min, idx_med)
    idx_max <- max(idx_max, idx_med)
    
    tabela$notaMin[i + 1] <- round(notas[idx_min], 1)
    tabela$notaMed[i + 1] <- round(notas[idx_med], 1)
    tabela$notaMax[i + 1] <- round(notas[idx_max], 1)
  }
  
  # Suavização: aplicar média móvel para evitar saltos bruscos
  suavizar <- function(x, janela = 3) {
    n <- length(x)
    resultado <- x
    for (i in (janela+1):(n-janela)) {
      resultado[i] <- mean(x[(i-janela):(i+janela)])
    }
    return(resultado)
  }
  
  tabela$notaMin <- suavizar(tabela$notaMin)
  tabela$notaMed <- suavizar(tabela$notaMed)
  tabela$notaMax <- suavizar(tabela$notaMax)
  
  # Garantir monotonicidade estrita
  for (i in 2:nrow(tabela)) {
    tabela$notaMin[i] <- max(tabela$notaMin[i], tabela$notaMin[i-1] + 1.0)
    tabela$notaMed[i] <- max(tabela$notaMed[i], tabela$notaMed[i-1] + 1.0)
    tabela$notaMax[i] <- max(tabela$notaMax[i], tabela$notaMax[i-1] + 1.0)
  }
  
  # Ajustar último ponto para não ter salto absurdo
  # Interpolar linearmente os últimos valores
  n <- nrow(tabela)
  if (n > 5) {
    # Para os últimos 5 pontos, fazer interpolação suave
    for (col in c("notaMin", "notaMed", "notaMax")) {
      valor_antes <- tabela[[col]][n-5]
      valor_max <- max(notas)  # Valor real máximo
      
      # Distribuir linearmente
      for (j in 1:5) {
        tabela[[col]][n-5+j] <- valor_antes + (valor_max - valor_antes) * (j/5)
      }
    }
  }
  
  return(tabela)
}

# Processar todas as áreas
areas <- list(
  MT = list(col = "NU_NOTA_MT", pres = "TP_PRESENCA_MT", n = 45),
  CH = list(col = "NU_NOTA_CH", pres = "TP_PRESENCA_CH", n = 45),
  CN = list(col = "NU_NOTA_CN", pres = "TP_PRESENCA_CN", n = 45),
  LC = list(col = "NU_NOTA_LC", pres = "TP_PRESENCA_LC", n = 50)
)

resultado <- list(
  metadata = list(
    ano = 2024,
    data_processamento = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    metodo = "percentis_diretos",
    total_inscritos = nrow(dados)
  )
)

for (area_cod in names(areas)) {
  area_info <- areas[[area_cod]]
  message(sprintf("\nProcessando %s...", area_cod))
  
  # Ler colunas específicas
  cols <- fread("microdados/RESULTADOS_2024.csv", 
                sep = ";", 
                encoding = "Latin-1",
                select = c(area_info$col, area_info$pres))
  
  notas <- cols[[area_info$col]][cols[[area_info$pres]] == 1 & 
                                   !is.na(cols[[area_info$col]]) & 
                                   cols[[area_info$col]] > 0]
  notas <- sort(notas)
  
  message(sprintf("  Notas válidas: %s", format(length(notas), big.mark = ".")))
  
  # Gerar tabela
  tabela <- gerar_tabela_percentil(notas, area_info$n)
  
  # Estatísticas
  stats <- list(
    n_presentes = length(notas),
    media = mean(notas),
    mediana = median(notas),
    dp = sd(notas),
    min = min(notas),
    max = max(notas)
  )
  
  resultado[[area_cod]] <- list(
    ano = 2024,
    area = area_cod,
    n_itens = area_info$n,
    estatisticas = stats,
    tabela_amplitude = tabela
  )
  
  message(sprintf("  Tabela: %d linhas", nrow(tabela)))
  message(sprintf("  Range: %.1f a %.1f", min(tabela$notaMin), max(tabela$notaMax)))
}

# Salvar
write_json(resultado, "frontend/public/data/enem_2024.json", pretty = TRUE, auto_unbox = TRUE)
message("\n✓ JSON salvo: frontend/public/data/enem_2024.json")

message("\n=== RESUMO ===")
for (area in c("CH", "CN", "LC", "MT")) {
  tabela <- resultado[[area]]$tabela_amplitude
  message(sprintf("%s: Range %.1f - %.1f | Média: %.1f", 
                area, min(tabela$notaMin), max(tabela$notaMax), resultado[[area]]$estatisticas$media))
}
