#!/usr/bin/env Rscript
# Gerador de Insights Automáticos para ENEM
# Analisa dados e gera sugestões acionáveis

library(dplyr)
library(jsonlite)

#' Gera insights comparativos entre anos
#' @param comparacoes Resultado da função comparar_anos()
#' @return Lista de insights categorizados
gerar_insights_comparativos <- function(comparacoes) {
  
  insights <- list(
    tendencias = list(),
    alertas = list(),
    oportunidades = list(),
    recomendacoes = list()
  )
  
  for (area in names(comparacoes)) {
    comp <- comparacoes[[area]]
    
    # Tendências
    if (abs(comp$variacao_percentual_media) > 5) {
      tipo <- ifelse(comp$variacao_percentual_media > 0, "alta", "queda")
      insights$tendencias <- append(insights$tendencias, list(
        list(
          area = area,
          tipo = tipo,
          mensagem = sprintf("ENEM %s: %s significativa de %.1f%% na média (%s → %s)", 
                            area, ifelse(tipo == "alta", "ALTA", "QUEDA"),
                            abs(comp$variacao_percentual_media),
                            format(comp$stats_ano1$n_presentes, big.mark = "."),
                            format(comp$stats_ano2$n_presentes, big.mark = ".")),
          magnitude = abs(comp$variacao_percentual_media),
          impacto = ifelse(abs(comp$variacao_percentual_media) > 10, "ALTO", "MÉDIO")
        )
      ))
    }
    
    # Alertas
    if (comp$stats_ano2$dp > comp$stats_ano1$dp * 1.15) {
      insights$alertas <- append(insights$alertas, list(
        list(
          area = area,
          tipo = "desigualdade",
          mensagem = sprintf("ENEM %s: Aumento da desigualdade (DP +%.1f%%). Prova mais heterogênea.",
                            area, ((comp$stats_ano2$dp / comp$stats_ano1$dp) - 1) * 100),
          severidade = "ALTA"
        )
      ))
    }
    
    if (comp$stats_ano2$p10 < comp$stats_ano1$p10 * 0.95) {
      insights$alertas <- append(insights$alertas, list(
        list(
          area = area,
          tipo = "piso",
          mensagem = sprintf("ENEM %s: Piso de desempenho caiu (P10: %.0f → %.0f). Risco de exclusão.",
                            area, comp$stats_ano1$p10, comp$stats_ano2$p10),
          severidade = "MÉDIA"
        )
      ))
    }
    
    # Oportunidades
    if (comp$stats_ano2$p90 > comp$stats_ano1$p90 * 1.05) {
      insights$oportunidades <- append(insights$oportunidades, list(
        list(
          area = area,
          tipo = "excelencia",
          mensagem = sprintf("ENEM %s: Teto de desempenho elevado (P90: %.0f → %.0f). Maior diferenciação no topo.",
                            area, comp$stats_ano1$p90, comp$stats_ano2$p90),
          potencial = "ALTO"
        )
      ))
    }
  }
  
  # Recomendações gerais
  insights$recomendacoes <- gerar_recomendacoes(insights)
  
  return(insights)
}

#' Gera recomendações baseadas nos insights
#' @param insights Lista de insights
gerar_recomendacoes <- function(insights) {
  recs <- list()
  
  # Recomendação sobre tendências
  if (length(insights$tendencias) > 0) {
    tendencias_altas <- Filter(function(x) x$impacto == "ALTO", insights$tendencias)
    if (length(tendencias_altas) > 0) {
      recs <- append(recs, list(
        list(
          categoria = "Ação Imediata",
          titulo = "Investigar variações significativas",
          descricao = "Detectadas alterações >10% na média de uma ou mais áreas. Recomenda-se análise de: (1) mudanças no perfil dos candidatos, (2) alterações na matriz curricular, (3) possível efeito de novidade ou fadiga.",
          prioridade = 1,
          acoes = c("Analisar perfil socioeconômico", "Verificar matriz da prova", "Comparar com dados de anos anteriores")
        )
      ))
    }
  }
  
  # Recomendação sobre desigualdade
  if (length(insights$alertas) > 0) {
    recs <- append(recs, list(
      list(
        categoria = "Equidade",
        titulo = "Monitorar desigualdade de desempenho",
        descricao = "Aumento na variabilidade das notas sugere crescente distância entre melhores e piores desempenhos. Considerar políticas de nivelamento.",
        prioridade = 2,
        acoes = c("Mapear escolas com maior queda", "Identificar conteúdos críticos", "Propor intervenções pedagógicas")
      )
    ))
  }
  
  # Recomendação padrão
  recs <- append(recs, list(
    list(
      categoria = "Melhoria Contínua",
      titulo = "Atualizar tabelas de referência",
      descricao = "Manter tabelas MIN/MED/MAX atualizadas permite melhor precisão nas projeções e comparações entre anos.",
      prioridade = 3,
      acoes = c("Atualizar presets do sistema", "Documentar mudanças", "Comunicar stakeholders")
    )
  ))
  
  # Ordenar por prioridade
  recs <- recs[order(sapply(recs, function(x) x$prioridade))]
  
  return(recs)
}

#' Analisa desempenho por tipo de escola
#' @param resultados Resultados do processamento
#' @return Insights sobre escolas
analisar_escolas <- function(resultados) {
  
  insights_escolas <- list()
  
  for (area in c("CH", "CN", "LC", "MT")) {
    if (is.null(resultados[[area]])) next
    
    escolas <- resultados[[area]]$escolas
    
    # Agrupar por tipo de dependência administrativa
    # 1 = Federal, 2 = Estadual, 3 = Municipal, 4 = Privada
    por_tipo <- escolas %>%
      mutate(tipo_escola = case_when(
        TP_DEPENDENCIA_ADM_ESC == 1 ~ "Federal",
        TP_DEPENDENCIA_ADM_ESC == 2 ~ "Estadual",
        TP_DEPENDENCIA_ADM_ESC == 3 ~ "Municipal",
        TP_DEPENDENCIA_ADM_ESC == 4 ~ "Privada",
        TRUE ~ "Não informado"
      )) %>%
      group_by(tipo_escola) %>%
      summarise(
        n_escolas = n(),
        media_geral = mean(media_nota, na.rm = TRUE),
        mediana_geral = median(media_nota, na.rm = TRUE),
        dp_entre_escolas = sd(media_nota, na.rm = TRUE),
        n_alunos_total = sum(n_alunos),
        .groups = "drop"
      )
    
    # Encontrar melhores escolas por tipo
    top_escolas <- escolas %>%
      group_by(TP_DEPENDENCIA_ADM_ESC) %>%
      slice_max(order_by = media_nota, n = 5) %>%
      ungroup()
    
    insights_escolas[[area]] <- list(
      por_tipo = por_tipo,
      top_escolas = top_escolas,
      ranking_uf = resultados[[area]]$por_uf
    )
  }
  
  return(insights_escolas)
}

#' Gera relatório completo em Markdown
gerar_relatorio <- function(resultados, comparacoes = NULL, insights = NULL, 
                           output_file = "output/enem/relatorio_analise.md") {
  
  dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)
  
  sink(output_file)
  
  cat("# Relatório de Análise ENEM\n\n")
  cat(sprintf("**Ano de referência:** %d\n\n", resultados$metadata$ano))
  cat(sprintf("**Data de processamento:** %s\n\n", Sys.time()))
  cat(sprintf("**Total de inscritos:** %s\n\n", 
              format(resultados$metadata$total_inscritos, big.mark = ".")))
  
  # Resumo por área
  cat("## Resumo por Área\n\n")
  cat("| Área | Média | DP | P25 | Mediana | P75 | Presentes |\n")
  cat("|------|-------|-----|-----|---------|-----|-----------|\n")
  
  for (area in c("CH", "CN", "LC", "MT")) {
    if (is.null(resultados[[area]])) next
    s <- resultados[[area]]$estatisticas
    cat(sprintf("| %s | %.1f | %.1f | %.1f | %.1f | %.1f | %s |\n",
                area, s$media, s$dp, s$p25, s$mediana, s$p75,
                format(s$n_presentes, big.mark = ".")))
  }
  
  # Insights
  if (!is.null(insights)) {
    cat("\n## Insights Gerados\n\n")
    
    if (length(insights$tendencias) > 0) {
      cat("### Tendências Detectadas\n\n")
      for (t in insights$tendencias) {
        cat(sprintf("- **%s** (%s): %s\n", t$area, t$impacto, t$mensagem))
      }
      cat("\n")
    }
    
    if (length(insights$alertas) > 0) {
      cat("### Alertas\n\n")
      for (a in insights$alertas) {
        cat(sprintf("- **%s** [%s]: %s\n", a$area, a$severidade, a$mensagem))
      }
      cat("\n")
    }
    
    if (length(insights$recomendacoes) > 0) {
      cat("### Recomendações\n\n")
      for (r in insights$recomendacoes) {
        cat(sprintf("#### %d. %s (%s)\n\n", r$prioridade, r$titulo, r$categoria))
        cat(sprintf("%s\n\n", r$descricao))
        cat("**Ações sugeridas:**\n")
        for (acao in r$acoes) {
          cat(sprintf("- %s\n", acao))
        }
        cat("\n")
      }
    }
  }
  
  # Comparações
  if (!is.null(comparacoes)) {
    cat("\n## Comparação com Ano Anterior\n\n")
    for (area in names(comparacoes)) {
      c <- comparacoes[[area]]
      cat(sprintf("### %s: %d vs %d\n\n", area, c$anos[1], c$anos[2]))
      cat(sprintf("- Variação na média: %+.2f pontos (%+.2f%%)\n", 
                  c$delta_media, c$variacao_percentual_media))
      cat(sprintf("- Variação na mediana: %+.2f pontos\n", c$delta_mediana))
      cat("\n")
    }
  }
  
  sink()
  
  message(sprintf("\nRelatório salvo: %s", output_file))
}

# === EXEMPLO DE USO ===
if (FALSE) {
  # Carregar resultados processados
  resultados_2024 <- fromJSON("output/enem/enem_2024_completo.json")
  resultados_2023 <- fromJSON("output/enem/enem_2023_completo.json")
  
  # Comparar anos
  comparacoes <- comparar_anos(resultados_2023, resultados_2024)
  
  # Gerar insights
  insights <- gerar_insights_comparativos(comparacoes)
  
  # Analisar escolas
  escolas <- analisar_escolas(resultados_2024)
  
  # Gerar relatório
  gerar_relatorio(resultados_2024, comparacoes, insights)
}
