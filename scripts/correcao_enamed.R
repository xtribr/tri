#!/usr/bin/env Rscript
# Correção Estilo ENAMED - Simulado Aplicação Real
# Modelo: Rasch 1PL + Estatísticas de Ajuste

suppressPackageStartupMessages({
  library(mirt)
  library(dplyr)
  library(ggplot2)
})

cat("=" ,rep("=", 70), "\n", sep="")
cat("  CORREÇÃO ESTILO ENAMED - SIMULADO APLICAÇÃO REAL\n")
cat("=" ,rep("=", 70), "\n\n", sep="")

# ============================================================================
# 1. LEITURA DOS DADOS
# ============================================================================

cat("[1/6] Lendo dados da aplicação...\n")

# Ler com codificação correta para nomes com acentos
dados_brutos <- read.csv2(
  "aplicacao.csv",
  header = TRUE,
  stringsAsFactors = FALSE,
  fileEncoding = "latin1"  # ou "ISO-8859-1"
)

cat(sprintf("    ✓ Total de candidatos: %d\n", nrow(dados_brutos)))
cat(sprintf("    ✓ Total de colunas: %d\n", ncol(dados_brutos)))
cat(sprintf("    ✓ Colunas identificadas: %s\n", 
            paste(colnames(dados_brutos)[1:5], collapse=", ")))

# Extrair informações dos candidatos
info_candidatos <- dados_brutos[, c("nome", "email")]

# Extrair apenas as respostas (Q1 a Q100)
colunas_questoes <- grep("^Q[0-9]+$", colnames(dados_brutos), value = TRUE)
respostas <- dados_brutos[, colunas_questoes]

# Converter para matriz numérica
respostas <- as.matrix(respostas)
mode(respostas) <- "numeric"

cat(sprintf("    ✓ Matriz de respostas: %d x %d\n\n", 
            nrow(respostas), ncol(respostas)))

# ============================================================================
# 2. ANÁLISE DESCRITIVA PRELIMINAR
# ============================================================================

cat("[2/6] Análise descritiva...\n")

# Estatísticas básicas
n_candidatos <- nrow(respostas)
n_itens <- ncol(respostas)
scores <- rowSums(respostas, na.rm = TRUE)
taxa_acerto <- colMeans(respostas, na.rm = TRUE)

cat(sprintf("    Estatísticas da Prova:\n"))
cat(sprintf("    - Score médio: %.2f (%.2f%%)\n", mean(scores), mean(scores)/n_itens*100))
cat(sprintf("    - Score DP: %.2f\n", sd(scores)))
cat(sprintf("    - Score mínimo: %d (%.1f%%)\n", min(scores), min(scores)/n_itens*100))
cat(sprintf("    - Score máximo: %d (%.1f%%)\n", max(scores), max(scores)/n_itens*100))
cat(sprintf("    - Mediana: %.1f\n\n", median(scores)))

# Análise TCT (Teoria Clássica dos Testes)
cat("    Análise TCT por item:\n")

# Correlação bisserial ponto-produto-momento
r_biserial <- sapply(1:n_itens, function(i) {
  cor(respostas[,i], scores - respostas[,i], use = "complete.obs")
})

tct_stats <- data.frame(
  item = colnames(respostas),
  posicao = 1:n_itens,
  taxa_acerto = round(taxa_acerto, 4),
  dificuldade = round(1 - taxa_acerto, 4),
  r_biserial = round(r_biserial, 4),
  stringsAsFactors = FALSE
)

# Classificação de itens
tct_stats$categoria_dificuldade <- cut(
  tct_stats$dificuldade,
  breaks = c(0, 0.25, 0.50, 0.75, 1),
  labels = c("Muito Fácil", "Fácil", "Médio", "Difícil"),
  include.lowest = TRUE
)

tct_stats$status <- ifelse(
  tct_stats$r_biserial < 0.15,
  "REVISAR (baixa discriminação)",
  ifelse(
    tct_stats$dificuldade < 0.1 | tct_stats$dificuldade > 0.9,
    "REVISAR (dificuldade extrema)",
    "OK"
  )
)

cat(sprintf("    - Itens Muito Fáceis: %d\n", sum(tct_stats$categoria_dificuldade == "Muito Fácil")))
cat(sprintf("    - Itens Fáceis: %d\n", sum(tct_stats$categoria_dificuldade == "Fácil", na.rm=TRUE)))
cat(sprintf("    - Itens Médios: %d\n", sum(tct_stats$categoria_dificuldade == "Médio", na.rm=TRUE)))
cat(sprintf("    - Itens Difíceis: %d\n", sum(tct_stats$categoria_dificuldade == "Difícil", na.rm=TRUE)))
cat(sprintf("    - Itens com problema: %d\n\n", sum(tct_stats$status != "OK")))

# ============================================================================
# 3. CALIBRAÇÃO RASCH 1PL (ESTILO ENAMED)
# ============================================================================

cat("[3/6] Calibração TRI - Modelo Rasch 1PL...\n")

# Modelo Rasch 1PL (apenas parâmetro b)
mod_rasch <- mirt(
  respostas,
  model = 1,
  itemtype = "Rasch",
  verbose = FALSE,
  TOL = 1e-6,
  quadpts = 40
)

cat(sprintf("    ✓ Modelo calibrado\n"))
cat(sprintf("    ✓ Log-likelihood: %.2f\n", mod_rasch@Fit$logLik))
cat(sprintf("    ✓ AIC: %.2f\n", mod_rasch@Fit$AIC))
cat(sprintf("    ✓ BIC: %.2f\n\n", mod_rasch@Fit$BIC))

# Extrair parâmetros
params_tri <- coef(mod_rasch, IRTpars = TRUE, simplify = TRUE)$items

# Data frame de parâmetros
parametros_itens <- data.frame(
  item = rownames(params_tri),
  a = 1,  # Fixo no Rasch
  b = round(params_tri[, 2], 4),  # Dificuldade
  c = 0,  # Não estimado no Rasch
  stringsAsFactors = FALSE
)

# Estatísticas de ajuste (simplificado para Rasch)
cat("    Calculando estatísticas de ajuste...\n")

# Para Rasch, usar estatísticas básicas de itemfit
tryCatch({
  item_fit <- itemfit(mod_rasch)
  
  # Extrair p-valor do S-X2 (ajuste do item)
  if ("p" %in% names(item_fit)) {
    parametros_itens$p_valor_ajuste <- round(item_fit$p, 4)
  } else {
    parametros_itens$p_valor_ajuste <- NA
  }
  
  # INFIT/OUTFIT se disponíveis
  if ("infit" %in% names(item_fit)) {
    parametros_itens$infit <- round(item_fit$infit, 4)
    parametros_itens$outfit <- round(item_fit$outfit, 4)
  } else {
    # Calcular estatísticas alternativas
    parametros_itens$infit <- NA
    parametros_itens$outfit <- NA
  }
  
}, error = function(e) {
  parametros_itens$p_valor_ajuste <<- NA
  parametros_itens$infit <<- NA
  parametros_itens$outfit <<- NA
})

# Classificação de ajuste (limites ENAMED)
parametros_itens$ajuste_status <- ifelse(
  !is.na(parametros_itens$infit) & !is.na(parametros_itens$outfit) &
  parametros_itens$infit >= 0.7 & parametros_itens$infit <= 1.3 &
  parametros_itens$outfit >= 0.7 & parametros_itens$outfit <= 1.3,
  "MANTIDO",
  ifelse(
    !is.na(parametros_itens$infit) & (parametros_itens$infit < 0.5 | parametros_itens$infit > 1.5),
    "EXCLUIR",
    ifelse(is.na(parametros_itens$infit), "NAO_AVALIADO", "REVISAR")
  )
)

cat(sprintf("    - Itens MANTIDOS: %d\n", sum(parametros_itens$ajuste_status == "MANTIDO")))
cat(sprintf("    - Itens para REVISAR: %d\n", sum(parametros_itens$ajuste_status == "REVISAR")))
cat(sprintf("    - Itens para EXCLUIR: %d\n\n", sum(parametros_itens$ajuste_status == "EXCLUIR")))

# ============================================================================
# 4. ESTIMAÇÃO DE ESCORES (THETA) - MÉTODO EAP
# ============================================================================

cat("[4/6] Estimando proficiências (theta) via EAP...\n")

# EAP (Expected A Posteriori) - método oficial ENEM/ENAMED
theta_eap <- fscores(mod_rasch, method = "EAP", full.scores = TRUE, full.scores.SE = TRUE)

# Verificar estrutura do retorno
theta_eap <- as.data.frame(theta_eap)
theta_values <- theta_eap[, 1]
se_values <- if (ncol(theta_eap) >= 2) theta_eap[, 2] else rep(NA, length(theta_values))

cat(sprintf("    ✓ Proficiências estimadas\n"))
cat(sprintf("    - Theta médio: %.3f (teórico: 0)\n", mean(theta_values)))
cat(sprintf("    - Theta DP: %.3f (teórico: 1)\n", sd(theta_values)))
cat(sprintf("    - SE médio: %.3f\n", mean(se_values)))
cat(sprintf("    - Precisão média: %.2f\n\n", mean(1/(se_values^2))))

# ============================================================================
# 5. TRANSFORMAÇÃO PARA ESCALA ENAMED
# ============================================================================

cat("[5/6] Transformando para escala ENAMED...\n")

# Transformação theta → Percentual (estilo ENAMED)
# Fórmula: Nota = 50 + 10 * theta (aproximação)
# Ou usar equipercentil baseado nos dados

# Método 1: Transformação linear
transformar_linear <- function(theta, media_desejada = 60, dp_desejada = 15) {
  nota <- media_desejada + (theta * dp_desejada)
  return(pmin(pmax(nota, 0), 100))
}

# Método 2: Equipercentil (mais fiel ao ENAMED)
# Mapeia os percentis do theta para percentis da escala alvo
transformar_equipercentil <- function(theta, score_bruto, max_score = 100) {
  # Percentil do candidato no theta
  percentil_theta <- ecdf(theta)(theta)
  
  # Percentil correspondente no score bruto
  percentil_score <- ecdf(score_bruto)(score_bruto)
  
  # Nota final combina ambos (ponderação)
  nota_hibrida <- 0.6 * (percentil_theta * 100) + 0.4 * (score_bruto / max_score * 100)
  
  return(round(nota_hibrida, 1))
}

# Aplicar transformações
nota_linear <- transformar_linear(theta_values)
nota_hibrida <- transformar_equipercentil(theta_values, scores, n_itens)

# ============================================================================
# 6. RELATÓRIO FINAL
# ============================================================================

cat("[6/6] Gerando relatório de correção...\n\n")

# Data frame final dos candidatos
resultado_final <- data.frame(
  nome = info_candidatos$nome,
  email = info_candidatos$email,
  acertos = scores,
  percentual_bruto = round(scores / n_itens * 100, 1),
  theta = round(theta_values, 4),
  se_theta = round(se_values, 4),
  nota_enamed_estimada = round(nota_hibrida, 1),
  ic_inferior_95 = round(theta_values - 1.96 * se_values, 4),
  ic_superior_95 = round(theta_values + 1.96 * se_values, 4),
  classificacao = case_when(
    nota_hibrida >= 70 ~ "APROVADO",
    nota_hibrida >= 60 ~ "LIMITE",
    TRUE ~ "REPROVADO"
  ),
  stringsAsFactors = FALSE
)

# Estatísticas finais
cat(rep("-", 70), "\n", sep="")
cat("RESULTADOS DA CORREÇÃO\n")
cat(rep("-", 70), "\n\n", sep="")

cat("Estatísticas Globais:\n")
cat(sprintf("  - Candidatos avaliados: %d\n", n_candidatos))
cat(sprintf("  - Nota média (ENAMED): %.2f\n", mean(resultado_final$nota_enamed_estimada)))
cat(sprintf("  - Nota mediana: %.2f\n", median(resultado_final$nota_enamed_estimada)))
cat(sprintf("  - DP das notas: %.2f\n", sd(resultado_final$nota_enamed_estimada)))
cat(sprintf("  - Aprovados (≥70): %d (%.1f%%)\n", 
            sum(resultado_final$classificacao == "APROVADO"),
            sum(resultado_final$classificacao == "APROVADO") / n_candidatos * 100))
cat(sprintf("  - Limite (60-69): %d (%.1f%%)\n",
            sum(resultado_final$classificacao == "LIMITE"),
            sum(resultado_final$classificacao == "LIMITE") / n_candidatos * 100))
cat(sprintf("  - Reprovados (<60): %d (%.1f%%)\n\n",
            sum(resultado_final$classificacao == "REPROVADO"),
            sum(resultado_final$classificacao == "REPROVADO") / n_candidatos * 100))

# Top 10
cat("Top 10 Candidatos:\n")
top10 <- head(resultado_final[order(-resultado_final$nota_enamed_estimada), ], 10)
for (i in 1:10) {
  cat(sprintf("  %2d. %-30s | Acertos: %2d | Nota: %5.1f | Theta: %6.3f\n",
              i, 
              substr(top10$nome[i], 1, 30),
              top10$acertos[i],
              top10$nota_enamed_estimada[i],
              top10$theta[i]))
}

# ============================================================================
# 7. SALVAR RESULTADOS
# ============================================================================

cat("\n")
cat("Salvando arquivos de saída...\n")

# Criar diretório de saída se não existir
dir.create("output/correcao_enamed", showWarnings = FALSE, recursive = TRUE)

# Salvar resultados dos candidatos
write.csv2(resultado_final, 
           "output/correcao_enamed/resultado_candidatos.csv",
           row.names = FALSE,
           fileEncoding = "UTF-8")

cat("    ✓ output/correcao_enamed/resultado_candidatos.csv\n")

# Salvar parâmetros dos itens
write.csv2(parametros_itens,
           "output/correcao_enamed/parametros_itens_tri.csv",
           row.names = FALSE,
           fileEncoding = "UTF-8")

cat("    ✓ output/correcao_enamed/parametros_itens_tri.csv\n")

# Salvar estatísticas TCT
write.csv2(tct_stats,
           "output/correcao_enamed/estatisticas_tct.csv",
           row.names = FALSE,
           fileEncoding = "UTF-8")

cat("    ✓ output/correcao_enamed/estatisticas_tct.csv\n")

# Salvar modelo RDS
saveRDS(mod_rasch, "output/correcao_enamed/modelo_rasch.rds")
cat("    ✓ output/correcao_enamed/modelo_rasch.rds\n")

# ============================================================================
# 8. GRÁFICOS (se ggplot2 disponível)
# ============================================================================

tryCatch({
  # Distribuição das notas
  p1 <- ggplot(resultado_final, aes(x = nota_enamed_estimada, fill = classificacao)) +
    geom_histogram(bins = 20, alpha = 0.7) +
    geom_vline(xintercept = 60, linetype = "dashed", color = "red") +
    geom_vline(xintercept = 70, linetype = "dashed", color = "darkgreen") +
    labs(title = "Distribuição das Notas - Estilo ENAMED",
         subtitle = sprintf("Média: %.1f | Mediana: %.1f | DP: %.1f",
                           mean(resultado_final$nota_enamed_estimada),
                           median(resultado_final$nota_enamed_estimada),
                           sd(resultado_final$nota_enamed_estimada)),
         x = "Nota ENAMED",
         y = "Frequência",
         fill = "Classificação") +
    theme_minimal()
  
  ggsave("output/correcao_enamed/distribuicao_notas.png", p1, width = 10, height = 6)
  cat("    ✓ output/correcao_enamed/distribuicao_notas.png\n")
  
  # Mapa de calor dos itens
  p2 <- ggplot(parametros_itens, aes(x = posicao, y = 1, fill = b)) +
    geom_tile() +
    scale_fill_gradient2(low = "green", mid = "yellow", high = "red", midpoint = 0) +
    labs(title = "Dificuldade dos Itens (parâmetro b)",
         x = "Item",
         y = "",
         fill = "b") +
    theme_minimal() +
    theme(axis.text.y = element_blank())
  
  ggsave("output/correcao_enamed/dificuldade_itens.png", p2, width = 12, height = 3)
  cat("    ✓ output/correcao_enamed/dificuldade_itens.png\n")
  
}, error = function(e) {
  cat("    (Gráficos não gerados - ggplot2 não disponível)\n")
})

# ============================================================================
# RESUMO FINAL
# ============================================================================

cat("\n")
cat(rep("=", 70), "\n", sep="")
cat("CORREÇÃO CONCLUÍDA COM SUCESSO!\n")
cat(rep("=", 70), "\n\n", sep="")

cat("Arquivos gerados em: output/correcao_enamed/\n\n")

cat("Principais resultados:\n")
cat(sprintf("  • Nota média da turma: %.1f\n", mean(resultado_final$nota_enamed_estimada)))
cat(sprintf("  • Taxa de aprovação: %.1f%%\n", 
            sum(resultado_final$classificacao == "APROVADO") / n_candidatos * 100))
cat(sprintf("  • Itens problemáticos identificados: %d\n", 
            sum(parametros_itens$ajuste_status != "MANTIDO")))
cat(sprintf("  • Precisão média da medição: %.2f\n\n", mean(1/(se_values^2))))

cat("Para análise detalhada, abra os arquivos CSV gerados.\n")
cat("Modelo Rasch salvo em: output/correcao_enamed/modelo_rasch.rds\n\n")
