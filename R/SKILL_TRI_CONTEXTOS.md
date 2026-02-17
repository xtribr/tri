# Skill TRI por Contexto de Avaliação

## Visão Geral

Esta skill detalha as especificações técnicas da TRI (Teoria de Resposta ao Item) para diferentes contextos de avaliação no Brasil, baseada na documentação oficial do INEP e nas especificações dos exames ENAMED, ENEM, SAEB e avaliações com itens politômicos (GRADED).

---

## 1. ENAMED - Exame Nacional de Avaliação da Formação Médica

### 1.1 Características Gerais

| Aspecto | Especificação |
|---------|---------------|
| **Modelo TRI** | Rasch 1PL (apenas parâmetro b - dificuldade) |
| **Combinação** | TRI + Método Angoff Modificado |
| **Nº de itens** | 100 questões objetivas de múltipla escolha |
| **Alternativas** | 4 alternativas por item |
| **Áreas avaliadas** | Clínica Médica, Cirurgia Geral, Pediatria, Ginecologia e Obstetrícia, Medicina da Família e Comunidade, Saúde Coletiva, Saúde Mental |
| **Públicos** | Concluintes de Medicina (Enade) + Demais participantes (Enare) |
| **Aplicação** | Anual, a partir de 2025 |

### 1.2 Estrutura dos Parâmetros dos Itens

```
NU_ITEM_PROVA_1: Número do item na prova 1 (1-100)
NU_ITEM_PROVA_2: Número do item na prova 2 (1-100)
ITEM_MANTIDO:    1 = Sim, 0 = Não (se foi mantido no cálculo)
PARAMETRO_B:     Parâmetro de dificuldade (b) - escala logit
COR_BISSERIAL:   Correlação bisserial do item
INFIT:           Estatística de ajuste INFIT (Rasch)
OUTFIT:          Estatística de ajuste OUTFIT (Rasch)
```

### 1.3 Modelo Rasch 1PL no ENAMED

A função característica do item é:

```
P(Uij = 1 | θj, bi) = exp(θj - bi) / (1 + exp(θj - bi))
```

Onde:
- **θj**: Proficiência do examinando j
- **bi**: Dificuldade do item i
- **a = 1**: Discriminação fixa (característica do modelo Rasch)

### 1.4 Implementação no R/mirt

```r
library(mirt)

# Calibração Rasch 1PL para ENAMED
mod_enamed <- mirt(
  dados_respostas,      # Matriz binária (0/1) de respostas
  model = 1,            # Unidimensional
  itemtype = "Rasch",   # Modelo Rasch (a=1)
  TOL = 1e-6,
  quadpts = 40,
  technical = list(NCYCLES = 500)
)

# Extrair parâmetros b
coef(mod_enamed, IRTpars = TRUE, simplify = TRUE)

# Estimar proficiências (EAP)
theta <- fscores(mod_enamed, method = "EAP")
```

### 1.5 Combinação TRI + Angoff Modificado

O ENAMED utiliza uma abordagem híbrida:

1. **TRI**: Estima proficiências na escala logit
2. **Angoff Modificado**: Define pontos de corte baseados em julgamento de especialistas
3. **Transformação**: Converte escala TRI para escala percentual (0-100)

```r
# Exemplo de transformação logit -> percentual
# (fórmula específica do INEP)
transformar_nota <- function(theta, b_ancoras, angoff_ancoras) {
  # Usar regressão entre parâmetros b e valores Angoff
  # para estabelecer correspondência
  modelo <- lm(angoff_ancoras ~ b_ancoras)
  nota_percentual <- predict(modelo, newdata = data.frame(b_ancoras = theta))
  return(pmin(pmax(nota_percentual, 0), 100))
}
```

### 1.6 Critérios de Ajuste dos Itens (Rasch)

| Estatística | Limite Aceitável | Interpretação |
|-------------|------------------|---------------|
| **INFIT** | 0.7 - 1.3 | Ajuste do item ao modelo |
| **OUTFIT** | 0.7 - 1.3 | Ajuste sem itens extremos |
| **Correlação Bisserial** | > 0.20 | Discriminação mínima |

```r
# Verificar ajuste dos itens
ajuste <- itemfit(mod_enamed)
print(ajuste)

# Itens com problemas
itens_problematicos <- ajuste[ajuste$outfit > 1.3 | ajuste$outfit < 0.7, ]
```

---

## 2. ENEM - Exame Nacional do Ensino Médio

### 2.1 Características Gerais

| Aspecto | Especificação |
|---------|---------------|
| **Modelo TRI** | 3PL (Três Parâmetros Logísticos) |
| **Nº de itens** | 180 questões (45 por área) |
| **Alternativas** | 5 alternativas por item |
| **Áreas** | Linguagens, Matemática, Ciências da Natureza, Ciências Humanas |
| **Tipo de item** | Dicotômico (0/1) |

### 2.2 Modelo 3PL no ENEM

```
P(Uij = 1 | θj, ai, bi, ci) = ci + (1 - ci) / (1 + exp(-ai * (θj - bi)))
```

Parâmetros:
- **ai**: Discriminação (slope)
- **bi**: Dificuldade (location)
- **ci**: Acerto casual (guessing) - teórico: 0.20 (5 alternativas)

### 2.3 Prioris Recomendadas (INEP)

```r
modelo_enem <- mirt.model('
  F = 1-45
  PRIOR = (1-45, a1, lnorm, -0.6550, 1.1445),   # Discriminação
          (1-45, g, beta, 4, 16)                  # Acerto casual: Beta(4,16) → E=0.2
')
```

### 2.4 Implementação no R/mirt

```r
# Calibração 3PL para ENEM
mod_enem <- mirt(
  dados_enem,
  modelo_enem,
  itemtype = "3PL",
  TOL = 1e-6,
  quadpts = 40,
  technical = list(NCYCLES = 500)
)

# Extrair parâmetros IRT
coef(mod_enem, IRTpars = TRUE, simplify = TRUE)
```

---

## 3. SAEB - Sistema de Avaliação da Educação Básica

### 3.1 Características Gerais

| Aspecto | Especificação |
|---------|---------------|
| **Modelo TRI** | 3PL (dichotômicos) + GRADED (politômicos) |
| **Níveis** | Alfabetização, 5º ano, 9º ano (EF); 3ª série (EM) |
| **Áreas** | Língua Portuguesa, Matemática, Ciências (EF II) |
| **Formato** | Cadernos rotativos com itens comuns (âncoras) |

### 3.2 Equalização no SAEB

O SAEB usa **equalização via itens comuns** entre cadernos e anos:

```r
# Modelo para equalização SAEB
modelo_saeb <- mirt.model('
  F = 1-91
  CONSTRAINB = (1-20, a1), (1-20, d), (1-20, g)  # Itens âncora
  PRIOR = (1-91, a1, lnorm, -0.6550, 1.1445),
          (1-91, g, norm, -1.386, 0.5)
')

# Configurar invariância
invariance <- c(names(dados), 'slopes', 'intercepts', 'free_var', 'free_means')

# Equalização com múltiplos grupos (ex: estados)
K <- length(unique(dados$grupo))

mod_saeb <- multipleGroup(
  dados,
  modelo_saeb,
  itemtype = "3PL",
  group = dados$grupo,
  invariance = invariance,
  TOL = 1e-6,
  quadpts = K * 40,           # Proporcional ao nº de grupos
  technical = list(NCYCLES = K * 500)
)
```

### 3.3 Cuidados Específicos SAEB

1. **Número de pontos de quadratura**: Aumentar com número de grupos
2. **Ciclos EM**: Aumentar proporcionalmente
3. **Tempo computacional**: Significativamente maior que BILOG-MG
4. **Efeito shrinkage**: Menor no mirt que no BILOG-MG

---

## 4. GRADED EXAMS - Itens Politômicos

### 4.1 Modelos para Itens Politômicos

| Modelo | Uso | Características |
|--------|-----|-----------------|
| **GRM** (Graded Response Model) | Escalas Likert ordenadas | Samejima (1969) |
| **GPCM** (Generalized Partial Credit) | Créditos parciais | Muraki (1992) |
| **RSM** (Rating Scale Model) | Escalas de avaliação | Andrich (1978) |

### 4.2 Modelo GRM (Graded Response Model)

Para item com k categorias (0, 1, ..., k-1):

```
P(Uij ≥ k | θj) = exp(ak * (θj - bk)) / (1 + exp(ak * (θj - bk)))

P(Uij = k | θj) = P(Uij ≥ k) - P(Uij ≥ k+1)
```

### 4.3 Implementação no R/mirt

```r
# Dados com itens dicotômicos e politômicos
# Ex: 10 itens 3PL + 5 itens GRADED

item_types <- c(rep("3PL", 10), rep("graded", 5))

mod_misto <- mirt(
  dados,
  1,
  itemtype = item_types,
  TOL = 1e-6,
  quadpts = 40
)

# Extrair parâmetros
coef(mod_misto, simplify = TRUE)
```

### 4.4 Modelo GPCM (Generalized Partial Credit)

```r
# GPCM para itens com diferentes números de categorias
item_types <- c("3PL", "gpcm", "3PL", "graded", "gpcm")

mod_gpcm <- mirt(
  dados,
  1,
  itemtype = item_types
)
```

---

## 5. Comparação entre Contextos

### 5.1 Modelos por Exame

| Exame | Modelo | Parâmetros | Itens | Alternativas |
|-------|--------|------------|-------|--------------|
| **ENAMED** | Rasch 1PL | b | 100 | 4 |
| **ENEM** | 3PL | a, b, c | 180 | 5 |
| **SAEB** | 3PL + GRADED | a, b, c | Variável | 4-5 |
| **Provas Dissertativas** | GRADED/GPCM | a, b's | Variável | N/A |

### 5.2 Prioris por Contexto

| Contexto | Discriminação (a) | Acerto Casual (c) |
|----------|-------------------|-------------------|
| ENAMED | Não aplicável (a=1) | Não estimado |
| ENEM | Lognormal(-0.655, 1.1445) | Beta(4,16) ou Normal(-1.386, 0.5) |
| SAEB | Lognormal(-0.655, 1.1445) | Normal(-1.386, 0.5) |

### 5.3 Estatísticas de Ajuste

| Contexto | Estatística | Limite | Uso |
|----------|-------------|--------|-----|
| ENAMED | INFIT | 0.7 - 1.3 | Ajuste Rasch |
| ENAMED | OUTFIT | 0.7 - 1.3 | Ajuste Rasch |
| ENEM/SAEB | M2 | p > 0.05 | Ajuste global |
| ENEM/SAEB | S-X2 | p > 0.05 | Ajuste por item |

---

## 6. Funções Utilitárias por Contexto

### 6.1 Função para ENAMED (Rasch + Angoff)

```r
analisar_enamed <- function(dados_respostas, param_angoff) {
  library(mirt)
  
  # Calibração Rasch
  mod <- mirt(dados_respostas, 1, itemtype = "Rasch")
  
  # Extrair parâmetros b
  params <- coef(mod, IRTpars = TRUE, simplify = TRUE)$items
  
  # Estatísticas de ajuste
  fit <- itemfit(mod)
  
  # Estimar proficiências
  theta <- fscores(mod, method = "EAP")
  
  # Verificar itens problemáticos
  itens_problema <- fit[fit$outfit > 1.3 | fit$outfit < 0.7, ]
  
  list(
    modelo = mod,
    parametros = params,
    ajuste = fit,
    theta = theta,
    itens_problematicos = itens_problema
  )
}
```

### 6.2 Função para ENEM/SAEB (3PL)

```r
analisar_3pl <- function(dados, n_grupos = 1) {
  library(mirt)
  
  if (n_grupos == 1) {
    # Calibração simples
    mod <- mirt(
      dados,
      1,
      itemtype = "3PL",
      TOL = 1e-6,
      quadpts = 40,
      technical = list(NCYCLES = 500)
    )
  } else {
    # Equalização múltiplos grupos
    modelo <- mirt.model('
      F = 1-45
      PRIOR = (1-45, a1, lnorm, -0.6550, 1.1445),
              (1-45, g, norm, -1.386, 0.5)
    ')
    
    invariance <- c(names(dados), 'slopes', 'intercepts', 'free_var', 'free_means')
    
    mod <- multipleGroup(
      dados,
      modelo,
      itemtype = "3PL",
      group = dados$grupo,
      invariance = invariance,
      TOL = 1e-6,
      quadpts = n_grupos * 40,
      technical = list(NCYCLES = n_grupos * 500)
    )
  }
  
  # Estatísticas de ajuste
  fit_global <- M2(mod)
  fit_itens <- itemfit(mod)
  
  list(
    modelo = mod,
    ajuste_global = fit_global,
    ajuste_itens = fit_itens,
    parametros = coef(mod, IRTpars = TRUE, simplify = TRUE)
  )
}
```

### 6.3 Função para Itens Politômicos

```r
analisar_graded <- function(dados, tipos_itens) {
  library(mirt)
  
  # tipos_itens: vetor com "3PL", "graded", "gpcm", etc.
  
  mod <- mirt(
    dados,
    1,
    itemtype = tipos_itens,
    TOL = 1e-6,
    quadpts = 40
  )
  
  # Curvas características
  plot(mod, type = 'trace')
  plot(mod, type = 'info')
  
  # Estatísticas de ajuste
  fit <- itemfit(mod)
  
  list(
    modelo = mod,
    ajuste = fit,
    parametros = coef(mod, simplify = TRUE)
  )
}
```

---

## 7. Referências

### Documentos Oficiais INEP

1. **ENAMED**: Manual do Usuário - Microdados do Enamed 2025 (Portaria MEC nº 330/2025)
2. **ENEM**: Notas Técnicas de Metodologia de Escores
3. **SAEB**: Especificações/Configurações para a Equalização no MIRT (Portaria 441/2023)
4. **INEP**: Especificações de Modelos de TRI (vários anos)

### Bibliografia Técnica

- Andrade, D. F., Tavares, H. R., & Valle, R. C. (2000). *Teoria da Resposta ao Item: Conceitos e Aplicações*.
- Chalmers, R. P. (2012). mirt: A Multidimensional Item Response Theory Package for the R Environment.
- Samejima, F. (1969). Estimation of latent ability using a response pattern of graded scores.
- Muraki, E. (1992). A generalized partial credit model.
- Andrich, D. (1978). A rating formulation for ordered response categories.

---

## 8. Resumo de Comandos por Contexto

| Contexto | Comando Principal | Tipo de Item |
|----------|-------------------|--------------|
| ENAMED | `mirt(dados, 1, itemtype = "Rasch")` | Dicotômico |
| ENEM | `mirt(dados, modelo, itemtype = "3PL")` | Dicotômico |
| SAEB Equalização | `multipleGroup(dados, modelo, group = grupos)` | Dicotômico |
| Itens Politômicos | `mirt(dados, 1, itemtype = "graded")` | Politômico |
| Modelo Misto | `mirt(dados, 1, itemtype = c("3PL", "graded"))` | Misto |
