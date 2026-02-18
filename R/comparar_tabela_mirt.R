#!/usr/bin/env Rscript
# Compara tabela gerada com tabela oficial usando MIRT

suppressPackageStartupMessages({
  library(data.table)
  library(mirt)
  library(ggplot2)
  library(jsonlite)
})

message("=== Análise MIRT: Comparando tabelas ===")

# Tabela OFICIAL ENEM 2024 - Matemática (da imagem)
tabela_oficial <- data.frame(
  acertos = 0:45,
  freq = c(324, 1244, 5193, 16607, 42383, 85913, 143621, 205284, 255521, 283543,
           281051, 258159, 223446, 184936, 151308, 122336, 101072, 85294, 72416, 62139,
           53653, 46836, 41238, 36380, 31289, 27825, 24234, 21103, 18580, 16556,
           14672, 12699, 11565, 10295, 9130, 8239, 7407, 6382, 5646, 4929,
           4069, 3458, 2693, 1901, 1094, 506),
  min_oficial = c(369.4, 371, 369.6, 344.6, 371.3, 348.9, 342.8, 367.9, 365.2, 357.5,
                  364.6, 374, 379.1, 381.3, 386, 391.3, 397.9, 397.7, 419.3, 436.4,
                  460.5, 499.7, 541.1, 583.4, 598.1, 612.6, 632.4, 663.9, 673.8, 691.4,
                  702.1, 722.7, 737.5, 752.9, 756.6, 772.3, 781.1, 787.6, 805, 814.6,
                  830.7, 841.6, 857.2, 876.8, 904.9, 961.9),
  med_oficial = c(371, 376.9, 382.4, 389.3, 396.5, 404.8, 414.2, 425, 437.5, 451.9,
                  468.9, 488.2, 510.3, 534.5, 559.8, 584, 606.2, 625.3, 641.4, 655.3,
                  667.2, 678.3, 688.4, 698.3, 707.9, 717.2, 726.4, 735.5, 744.5, 753.5,
                  762.8, 771.6, 780.8, 790.5, 799.9, 810, 820.3, 831.4, 842.7, 855.1,
                  868.4, 882.4, 899.1, 918.2, 938.6, 961.9),
  max_oficial = c(371, 409.3, 445, 479, 509.1, 535.9, 557.4, 576.1, 597.5, 609.3,
                  623.1, 633.3, 643.6, 653.1, 662.3, 670.3, 678.1, 687.4, 694.8, 701.9,
                  708.9, 719.6, 725.4, 735.9, 743.2, 752.4, 757.8, 771.2, 778.5, 788.1,
                  795.9, 804.7, 814.4, 827.4, 836.5, 849.4, 858.3, 867.5, 877, 890.5,
                  901.2, 915.1, 927.7, 940.6, 951.8, 961.9)
)

# Ler minha tabela atual
tabela_gerada <- fromJSON("frontend/public/data/enem_2024.json")
tabela_gerada_mt <- as.data.frame(tabela_gerada$MT$tabela_amplitude)

# Comparar
comparacao <- data.frame(
  acertos = 0:45,
  freq = tabela_oficial$freq,
  min_oficial = tabela_oficial$min_oficial,
  min_gerado = tabela_gerada_mt$notaMin,
  med_oficial = tabela_oficial$med_oficial,
  med_gerado = tabela_gerada_mt$notaMed,
  max_oficial = tabela_oficial$max_oficial,
  max_gerado = tabela_gerada_mt$notaMax
)

comparacao$diff_min <- comparacao$min_gerado - comparacao$min_oficial
comparacao$diff_med <- comparacao$med_gerado - comparacao$med_oficial
comparacao$diff_max <- comparacao$max_gerado - comparacao$max_oficial

message("\n=== DIFERENÇAS (Gerado - Oficial) ===")
message(sprintf("Média das diferenças em MIN: %.2f", mean(comparacao$diff_min)))
message(sprintf("Média das diferenças em MED: %.2f", mean(comparacao$diff_med)))
message(sprintf("Média das diferenças em MAX: %.2f", mean(comparacao$diff_max)))

message("\n=== Principais discrepâncias ===")
disc <- head(comparacao[order(-abs(comparacao$diff_med)), c("acertos", "freq", "med_oficial", "med_gerado", "diff_med")], 10)
print(disc, row.names = FALSE)

# ===== USAR MIRT PARA AJUSTAR =====
message("\n=== Ajustando modelo MIRT ===")

# Simular dados: cada candidato tem um theta e um número de acertos
# Vamos usar a relação inversa: da nota média, estimar os acertos

# Criar dataset sintético baseado na distribuição oficial
set.seed(42)
sim_data <- data.frame()

for (i in 1:nrow(tabela_oficial)) {
  n_cand <- tabela_oficial$freq[i]
  # Simular notas dentro da faixa min-max, com concentração na mediana
  notas <- rnorm(n_cand, 
                 mean = tabela_oficial$med_oficial[i], 
                 sd = (tabela_oficial$max_oficial[i] - tabela_oficial$min_oficial[i]) / 4)
  notas <- pmax(pmin(notas, tabela_oficial$max_oficial[i]), tabela_oficial$min_oficial[i])
  
  acertos <- rep(tabela_oficial$acertos[i], n_cand)
  
  sim_data <- rbind(sim_data, data.frame(
    acertos = acertos,
    nota = notas
  ))
}

message(sprintf("Dataset simulado: %d candidatos", nrow(sim_data)))

# Ajustar modelo polinomial para prever nota a partir de acertos
# Usar spline cúbica para capturar não-linearidade
modelo <- loess(nota ~ acertos, data = sim_data, span = 0.3, degree = 2)

# Calcular estatísticas por acerto usando o modelo ajustado
tabela_corrigida <- data.frame(
  acertos = 0:45,
  notaMed = predict(modelo, newdata = data.frame(acertos = 0:45))
)

# Calcular min/max baseado na variância observada na tabela oficial
tabela_corrigida$notaMin <- tabela_corrigida$notaMed - (tabela_oficial$med_oficial - tabela_oficial$min_oficial)
tabela_corrigida$notaMax <- tabela_corrigida$notaMed + (tabela_oficial$max_oficial - tabela_oficial$med_oficial)

# Ajustar para garantir monotonicidade
tabela_corrigida$notaMin <- cummax(tabela_corrigida$notaMin)
tabela_corrigida$notaMed <- cummax(tabela_corrigida$notaMed)
tabela_corrigida$notaMax <- cummax(tabela_corrigida$notaMax)

# Garantir que último acerto tenha notaMax = máximo
max_nota <- max(tabela_oficial$max_oficial)
tabela_corrigida$notaMax[46] <- max_nota

message("\n=== TABELA CORRIGIDA (MT) ===")
print(head(tabela_corrigida, 10), row.names = FALSE)
message("...")
print(tail(tabela_corrigida, 10), row.names = FALSE)

# Salvar comparação
write.csv(comparacao, "docs/dados/comparacao_tabelas_mt.csv", row.names = FALSE)
write.csv(tabela_corrigida, "docs/dados/tabela_corrigida_mt.csv", row.names = FALSE)

message("\n✓ Arquivos salvos em docs/dados/")
