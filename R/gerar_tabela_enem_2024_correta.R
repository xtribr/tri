#!/usr/bin/env Rscript
# Gera tabela ENEM 2024 - divide candidatos em faixas por percentil

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

message("=== Gerando Tabela ENEM 2024 ===")

# Configuração das áreas
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
    metodo = "agrupamento_por_percentil",
    observacao = "Notas divididas em 46 faixas (0-45). Como nao temos acertos individuais, usamos percentis das notas como proxy."
  )
)

for (area_cod in names(areas)) {
  area_info <- areas[[area_cod]]
  message(sprintf("\nProcessando %s...", area_cod))
  
  # Ler dados
  cols <- fread("microdados/RESULTADOS_2024.csv", 
                sep = ";", 
                encoding = "Latin-1",
                select = c(area_info$col, area_info$pres))
  
  # Filtrar notas válidas
  notas <- cols[[area_info$col]][cols[[area_info$pres]] == 1 & 
                                   !is.na(cols[[area_info$col]]) & 
                                   cols[[area_info$col]] > 0]
  notas <- sort(notas)
  n <- length(notas)
  
  message(sprintf("  Notas válidas: %s", format(n, big.mark = ".")))
  
  # Criar tabela
  tabela <- data.frame(
    acertos = 0:area_info$n,
    notaMin = numeric(area_info$n + 1),
    notaMed = numeric(area_info$n + 1),
    notaMax = numeric(area_info$n + 1)
  )
  
  # Dividir em 46 grupos iguais (por percentil)
  tamanho_faixa <- n / (area_info$n + 1)
  
  for (i in 0:area_info$n) {
    # Índices desta faixa
    idx_inicio <- max(1, floor(i * tamanho_faixa) + 1)
    idx_fim <- min(n, floor((i + 1) * tamanho_faixa))
    
    # Garantir que a última faixa vai até o fim
    if (i == area_info$n) idx_fim <- n
    
    # Calcular estatísticas da faixa
    faixa <- notas[idx_inicio:idx_fim]
    
    tabela$notaMin[i + 1] <- round(min(faixa), 1)
    tabela$notaMed[i + 1] <- round(median(faixa), 1)
    tabela$notaMax[i + 1] <- round(max(faixa), 1)
  }
  
  # Estatísticas gerais
  stats <- list(
    n_presentes = n,
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
  
  message(sprintf("  Faixa: %.1f a %.1f", min(tabela$notaMin), max(tabela$notaMax)))
}

# Salvar
write_json(resultado, "frontend/public/data/enem_2024.json", pretty = TRUE, auto_unbox = TRUE)
message("\n✓ JSON salvo")

message("\n=== RESUMO ===")
for (area in c("CH", "CN", "LC", "MT")) {
  tabela <- resultado[[area]]$tabela_amplitude
  message(sprintf("%s: %.1f - %.1f | Média: %.1f", 
                area, min(tabela$notaMin), max(tabela$notaMax), resultado[[area]]$estatisticas$media))
}
