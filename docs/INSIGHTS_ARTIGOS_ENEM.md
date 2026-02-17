# Insights Técnicos dos Artigos ENEM

## Resumo dos Aprendizados Aplicáveis ao Projeto TRI

---

## 1. Modelo TRI no ENEM (92067.pdf - Primi & Cicchetto)

### Key Takeaway
O ENEM usa **modelo 3PL** com estimação via **EAP (Expected A Posteriori)** para atribuir notas.

### Especificações Técnicas
- **Modelo:** 3PL (a, b, c)
- **Método de scoring:** EAP (não ML ou MAP)
- **Transformação:** Escala logit → Escala ENEM (0-1000 aproximadamente)

### Aplicação no Projeto
```r
# Configuração correta para simular ENEM
mod_enem <- mirt(dados, 1, itemtype = "3PL")

# EAP é o método oficial
theta_eap <- fscores(mod_enem, method = "EAP")

# Transformação para escala ENEM (exemplo)
transformar_escala_enem <- function(theta, media = 500, dp = 100) {
  # Aproximação da escala ENEM
  nota <- media + (theta * dp)
  return(round(pmin(pmax(nota, 0), 1000)))
}
```

---

## 2. Estrutura Interna e Dimensionalidade (91989.pdf)

### Key Takeaway
As provas do ENEM são **essencialmente unidimensionais** dentro de cada área, mas com correlações entre áreas.

### Implicações
- Modelo unidimensional (1 fator) é adequado para análise por área
- Análise multidimensional só é necessária para modelar correlações entre áreas

### Aplicação no Projeto
```r
# Testar dimensionalidade (exemplo com simulado)
library(psych)

# Análise paralela para determinar número de fatores
fa.parallel(dados, fa = "pc")

# Se unidimensional, usar:
mirt(dados, 1, itemtype = "3PL")

# Se multidimensional, usar:
mirt(dados, 2, itemtype = "3PL")  # ou número de fatores identificado
```

---

## 3. TCT vs TRI (93552.pdf)

### Comparação Prática

| Aspecto | TCT | TRI |
|---------|-----|-----|
| Parâmetros | p (proporção), r (correlação) | a, b, c |
| Invariância | Não | Sim (parâmetros invariantes) |
| Precisão | Varia por escore | Informação por θ |
| Banco de itens | Limitado | Robusto |

### Quando usar cada um no projeto
- **TCT:** Análise inicial rápida, estatísticas descritivas
- **TRI:** Calibração final, equating, CAT

```r
# Análise TCT rápida
tct_stats <- classicalTest(dados)

# Análise TRI completa
tri_mod <- mirt(dados, 1, itemtype = "3PL")
```

---

## 4. Efeito de Posição (93979.pdf)

### Key Takeaway
Itens no **final da prova tendem a ser mais difíceis** devido à fadiga.

### Implicações para Equating
- Cadernos diferentes devem considerar posição dos itens
- Itens âncora em posições diferentes podem ter parâmetros ligeiramente diferentes

### Aplicação no Projeto
```r
# Modelo multifacetas considerando posição
library(TAM)  # ou lme4

# Incluir posição como efeito fixo
formula <- ~ item + posicao
mod_facets <- tam.mml(dados, formula = formula)
```

---

## 5. Calibração sem Pré-teste (artigo pre-teste.pdf)

### Key Takeaway
É possível calibrar itens usando **amostras de campo menores** ou **métodos bayesianos**.

### Alternativas ao Pré-teste Tradicional
1. **Calibração online:** Usar respostas de aplicações oficiais
2. **Prioris informativas:** Usar conhecimento especializado
3. **Métodos sequenciais:** Atualizar parâmetros conforme novos dados chegam

### Aplicação no Projeto
```r
# Usar prioris fortes para estabilizar calibração com poucos dados
modelo <- mirt.model('
  F = 1-50
  PRIOR = (1-50, a1, lnorm, 0.5, 0.5),  # Priori informativa para a
          (1-50, d, norm, 0, 1),         # Priori informativa para b
          (1-50, g, beta, 5, 20)         # Priori para c (menor que ENEM)
')

mod <- mirt(dados, modelo, itemtype = "3PL")
```

---

## 6. Deep Learning na TRI (939130.pdf)

### Key Takeaway
Redes neurais podem estimar parâmetros TRI com **precisão comparável ou superior** aos métodos tradicionais, especialmente com grandes volumes de dados.

### Potencial Aplicação
- Estimação em tempo real
- Detecção de padrões complexos nos dados
- Predição de parâmetros para novos itens

### Implementação Conceitual
```r
# Pseudo-código (requer pacotes de deep learning)
library(keras)

# Treinar rede neural para prever θ a partir de padrão de respostas
modelo_nn <- keras_model_sequential() %>%
  layer_dense(units = 128, activation = 'relu', input_shape = c(n_itens)) %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dense(units = 1, activation = 'linear')  # θ estimado

modelo_nn %>% compile(optimizer = 'adam', loss = 'mse')
modelo_nn %>% fit(respostas, theta_conhecido, epochs = 50)
```

---

## 7. PLN para Análise de Itens (PLN e o ENEM.pdf)

### Key Takeaway
Processamento de Linguagem Natural pode identificar **padrões de interdisciplinaridade** nos itens automaticamente.

### Aplicação no Projeto
- Classificação automática de itens por área
- Análise de similaridade entre itens
- Detecção de itens mal classificados

---

## 8. Dashboards Interativos (961166.pdf)

### Key Takeaway
Dashboards em **R Shiny** são ferramentas poderosas para comunicar resultados psicométricos.

### Funcionalidades Sugeridas para Nosso Projeto
1. Visualização de curvas características dos itens
2. Mapa de calor de correlações
3. Estatísticas de ajuste interativas
4. Comparação de proficiências

### Esqueleto de Dashboard
```r
library(shiny)
library(mirt)
library(ggplot2)

ui <- fluidPage(
  titlePanel("Análise TRI - Simulado ENAMED"),
  sidebarLayout(
    sidebarPanel(
      selectInput("item", "Selecionar Item:", choices = 1:ncol(dados))
    ),
    mainPanel(
      plotOutput("icc_plot"),
      tableOutput("item_stats")
    )
  )
)

server <- function(input, output) {
  output$icc_plot <- renderPlot({
    plot(mod, type = 'trace', which.items = input$item)
  })
  
  output$item_stats <- renderTable({
    coef(mod, IRTpars = TRUE, simplify = TRUE)$items[input$item, ]
  })
}

shinyApp(ui, server)
```

---

## 9. Avaliação de Redações com LLMs (963377.pdf)

### Key Takeaway
LLMs (GPT, Claude, etc.) podem ser usados na **avaliação de redações** com correlação alta com avaliadores humanos.

### Relevância
Embora nosso foco seja TRI objetiva, o ENAMED pode incluir componentes de avaliação subjetiva no futuro.

---

## 10. Fundamentos Psicométricos (primi.pdf)

### Key Takeaway
A **Teoria Clássica dos Testes (TCT)** é base necessária para entender a TRI.

### Conceitos Fundamentais
- **Confiabilidade:** Estabilidade das medidas
- **Validade:** Se o teste mede o que deveria medir
- **Análise fatorial:** Estrutura subjacente dos dados

### Fórmulas Importantes
```
# Correlação bisserial (relacionada ao parâmetro a da TRI)
r_biserial = (M_acerto - M_erro) / s * sqrt(p*q)

# Onde:
# M_acerto = média dos que acertaram o item
# M_erro = média dos que erraram
# s = desvio-padrão total
# p = proporção de acertos
# q = 1-p
```

---

## 11. Itens Excluídos pela TRI (pre teste itens excluidos.pdf)

### Key Takeaway
Itens excluídos estatisticamente podem ter **valor pedagógico** e informar sobre lacunas no ensino.

### Implicações
- Não descartar itens problemáticos sem análise qualitativa
- Itens com baixa discriminação podem indicar conteúdo mal ensinado

---

## 12. Estratégias de Estudo (how and why... + how do students...)

### Key Takeaway
Testes de múltipla escolha são **ferramentas efetivas de aprendizagem** quando usados com estratégias de autorregulação.

### Aplicação no Projeto
- Feedback imediato aumenta aprendizagem
- Testes práticos devem simular condições reais
- Espaçamento da prática é mais efetivo que massa

---

## Resumo dos Insights Aplicáveis

| Insight | Implementação no Projeto | Prioridade |
|---------|-------------------------|------------|
| Modelo 3PL com EAP | Usar `fscores(method = "EAP")` | Alta |
| Efeito de posição | Considerar em cadernos rotativos | Média |
| Calibração sem pré-teste | Usar prioris fortes | Média |
| Dashboard interativo | Criar Shiny app | Baixa |
| PLN para análise | Analisar texto dos itens | Baixa |
| TCT como base | Incluir análise TCT inicial | Alta |

---

## Próximos Passos Recomendados

1. **Implementar EAP oficial** no endpoint de scoring da API
2. **Adicionar análise TCT** como etapa preliminar
3. **Testar efeito de posição** nos dados do simulado
4. **Explorar prioris mais informativas** para calibração com poucos dados
5. **Documentar fundamentos teóricos** (TCT → TRI) para usuários

---

**Referências:** Artigos catalogados em `BIBLIOTECA_ENEM.md`
