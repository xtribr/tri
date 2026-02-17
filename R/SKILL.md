# Skill TRI - Teoria de Resposta ao Item com R/mirt

## Visão Geral

Esta skill contém boas práticas e especificações técnicas para análise psicométrica usando TRI (Teoria de Resposta ao Item) com o pacote R `mirt`, baseadas nas especificações oficiais do INEP (Instituto Nacional de Estudos e Pesquisas Educacionais Anísio Teixeira).

## Documentação por Contexto

Para informações específicas sobre cada tipo de avaliação, consulte:

- **`SKILL_TRI_CONTEXTOS.md`**: Especificações detalhadas para:
  - **ENAMED**: Modelo Rasch 1PL + Método Angoff Modificado
  - **ENEM**: Modelo 3PL com prioris específicas
  - **SAEB**: Equalização via itens comuns com múltiplos grupos
  - **GRADED EXAMS**: Itens politômicos (GRM, GPCM)

### Resumo Rápido por Exame

| Exame | Modelo TRI | Nº Itens | Tipo | Alternativas |
|-------|------------|----------|------|--------------|
| **ENAMED** | Rasch 1PL | 100 | Dicotômico | 4 |
| **ENEM** | 3PL | 180 | Dicotômico | 5 |
| **SAEB** | 3PL + GRADED | Variável | Misto | 4-5 |
| **Provas Dissertativas** | GRADED/GPCM | Variável | Politômico | N/A |

## Fonte Oficial

**Documento:** Especificações/Configurações para a Equalização no MIRT  
**Autor:** Comissão de Assessoramento em Estatística e Psicometria do INEP  
**Portaria:** Nº 722 de 30 de agosto de 2019 / Portaria 441 de 25 de setembro de 2023  
**Referência:** Plano de Trabalho Complementar ao Plano CGMEB 1211853

---

## 1. Instalação e Carregamento do mirt

```r
# Instalação e carregamento automático
if(!require(mirt)) {
  install.packages("mirt")
  library(mirt)
}
```

---

## 2. Comando Básico de Calibração

### 2.1 Calibração Simples (Um Grupo, Uma Prova)

```r
mod <- mirt(
  Dados,           # Base de dados (matriz de respostas)
  1,               # Número de dimensões (1 = unidimensional)
  itemtype = "3PL", # Tipo de item: "Rasch", "2PL", "3PL", "4PL"
  TOL = 1e-6,      # Tolerância para convergência
  quadpts = 40,    # Pontos de quadratura para aproximar N(0,1)
  technical = list(NCYCLES = 500)  # Número máximo de ciclos EM
)
```

### 2.2 Tipos de Item Suportados

| Tipo | Descrição | Uso |
|------|-----------|-----|
| `Rasch` | Modelo de Rasch (a=1, variância livre) | Dados dicotômicos, restrição máxima |
| `2PL` | 2 parâmetros (a, b) | Dados dicotômicos padrão |
| `3PL` | 3 parâmetros (a, b, c) | Múltipla escolha com acerto casual |
| `4PL` | 4 parâmetros (a, b, c, γ) | Inclui parâmetro de assimetria |
| `graded` | Modelo de resposta graduada | Itens politômicos (Likert) |
| `gpcm` | Generalized Partial Credit Model | Itens politômicos sem ordenação |
| `nominal` | Modelo de resposta nominal | Categorias nominais |

**Exemplo com múltiplos tipos:**
```r
itemtype = c("3PL", "3PL", "graded", "2PL", "graded")
```

---

## 3. Configurações de Equalização

### 3.1 Situações de Equalização (6 Casos)

1. **Um único grupo, uma única prova** - Caso mais simples
2. **Um grupo dividido, duas provas totalmente distintas** - Equalização via população
3. **Um grupo dividido, duas provas parcialmente distintas** - Itens comuns
4. **Dois grupos, uma única prova** - Calibração conjunta
5. **Dois grupos, duas provas totalmente distintas** - Não equalizável sem âncoras
6. **Dois grupos, duas provas parcialmente distintas** - Equalização via itens comuns (mais comum)

### 3.2 Equalização com Múltiplos Grupos

```r
# Definir modelo com restrições
modelo <- mirt.model('
  F = 1-45
  CONSTRAINB = (1-20, a1), (1-20, d), (1-20, g)  # Itens 1-20 comuns
  PRIOR = (1-40, a1, lnorm, -0.6550, 1.1445),    # Priori para discriminação
          (1-40, g, norm, -1.386, 0.5)             # Priori para acerto casual
')

# Configurar invariância
invariance <- c(names(Dados), 'slopes', 'intercepts', 'free_var', 'free_means')

# Executar equalização
mod <- multipleGroup(
  Dados,
  modelo,
  itemtype = "3PL",
  group = Grupos,        # Vetor indicando grupo de cada respondente
  invariance = invariance,
  TOL = 1e-6,
  quadpts = K * 40,      # K = número de grupos
  technical = list(NCYCLES = K * 500)
)
```

**Importante:** O número de pontos de quadratura e ciclos EM deve aumentar proporcionalmente ao número de grupos.

---

## 4. Prioris para Controle de Parâmetros

### 4.1 Sintaxe de Prioris no mirt

```r
modelo <- mirt.model('
  F = 1-45
  PRIOR = (1-45, g, beta, 4, 16)  # c ~ Beta(4,16), E[c] = 4/(4+16) = 0.2
')
```

### 4.2 Distribuições de Priori Comuns

| Parâmetro | Distribuição | Parâmetros | Interpretação |
|-----------|--------------|------------|---------------|
| `a` (discriminação) | `lnorm` | média, desvio-padrão | Log-normal: a > 0 |
| `b` (dificuldade) | `norm` | média, desvio-padrão | Normal: b ∈ ℝ |
| `c` (acerto casual) | `beta` | α, β | Beta: c ∈ [0,1] |
| `c` (alternativa) | `norm` | média, desvio-padrão | Aproximação normal |

**Exemplo ENEM (5 alternativas):**
```r
# c ~ Beta(4, 16) → E[c] = 0.2
PRIOR = (1-45, g, beta, 4, 16)

# Ou aproximação normal: c ~ N(-1.386, 0.5) em logit
PRIOR = (1-45, g, norm, -1.386, 0.5)
```

---

## 5. Fixação de Parâmetros (Itens Âncoras)

### 5.1 Obter Matriz de Parâmetros

```r
# Extrair estrutura de parâmetros
PRM <- mirt(data, 1, itemtype = "3PL", pars = 'values')
```

A matriz `PRM` contém colunas:
- `item`: Número do item
- `name`: Nome do parâmetro (a1, d, g)
- `est`: TRUE/FALSE (estimar ou fixar)
- `value`: Valor inicial/fixo
- `prior_1`, `prior_2`: Parâmetros da priori

### 5.2 Fixar Parâmetros Específicos

```r
# Exemplo: Fixar parâmetros dos itens 1, 5 e 10
itens_fixar <- c(1, 5, 10)
valores_fixos <- data.frame(
  item = c(1, 5, 10),
  a = c(1.2, 0.8, 1.5),
  b = c(-0.5, 0.3, -1.2),
  c = c(0.15, 0.20, 0.10)
)

# Obter matriz de parâmetros
pars <- mirt(data, 1, itemtype = "3PL", pars = 'values')

# Converter b para intercepto (d = -a*b)
valores_fixos$d <- -valores_fixos$a * valores_fixos$b

# Atualizar matriz
for (i in 1:nrow(valores_fixos)) {
  item_num <- valores_fixos$item[i]
  
  # Linhas do item na matriz (a1, d, g)
  lin_a <- which(pars$item == item_num & pars$name == "a1")
  lin_d <- which(pars$item == item_num & pars$name == "d")
  lin_g <- which(pars$item == item_num & pars$name == "g")
  
  # Fixar valores
  pars$value[lin_a] <- valores_fixos$a[i]
  pars$est[lin_a] <- FALSE
  
  pars$value[lin_d] <- valores_fixos$d[i]
  pars$est[lin_d] <- FALSE
  
  pars$value[lin_g] <- valores_fixos$c[i]
  pars$est[lin_g] <- FALSE
}

# Calibrar com parâmetros fixos
mod_fixo <- mirt(data, 1, itemtype = "3PL", pars = pars)
```

---

## 6. Extração de Resultados

### 6.1 Parâmetros dos Itens

```r
# Parâmetros no formato IRT (a, b, c)
coef(mod, IRTpars = TRUE, simplify = TRUE)

# Parâmetros no formato slope-intercept (a, d)
coef(mod, simplify = TRUE)
```

### 6.2 Estatísticas de Ajuste

```r
# Resumo do modelo
summary(mod)

# Estatísticas de ajuste
M2(mod)  # Estatística M2 para ajuste global

# Informação dos itens
iteminfo <- iteminfo(mod)
plot(iteminfo)
```

### 6.3 Scoring (Estimação de Proficiências)

```r
# EAP (Expected A Posteriori) - Padrão
theta_eap <- fscores(mod, method = "EAP")

# MAP (Maximum A Posteriori)
theta_map <- fscores(mod, method = "MAP")

# ML (Maximum Likelihood)
theta_ml <- fscores(mod, method = "ML")

# WLE (Weighted Likelihood Estimation)
theta_wle <- fscores(mod, method = "WLE")

# Com escore pattern (para dados agregados)
theta <- fscores(mod, method = "EAP", full.scores = FALSE)
```

---

## 7. Função Completa para Calibração com Parâmetros Fixos

```r
Estima_Fixos <- function(data, prm, kPL = 3) {
  # prm: data.frame com colunas (item, a, b, c)
  
  cat("\nEstimativas de parâmetros a serem fixadas:\n")
  print(prm)
  cat("\n")
  
  # Converter b para intercepto (d = -a*b)
  prm[, 3] <- -prm[, 2] * prm[, 3]
  
  PL <- paste0(kPL, "PL")
  pars <- mirt(data, 1, itemtype = PL, pars = 'values')
  
  It <- ncol(data)
  FIXED <- prm[, 1]
  k <- 1
  
  for (i in 1:It) {
    ip <- 4 * i - 3
    
    if (i %in% FIXED) {
      # Fixar parâmetros
      lin.a <- prm[k, 1] * 4 - 3
      pars$value[lin.a] <- prm[k, 2]
      pars$est[lin.a] <- FALSE
      
      lin.b <- prm[k, 1] * 4 - 2
      pars$value[lin.b] <- prm[k, 3]
      pars$est[lin.b] <- FALSE
      
      lin.c <- prm[k, 1] * 4 - 1
      pars$value[lin.c] <- prm[k, 4]
      pars$est[lin.c] <- FALSE
      
      k <- k + 1
    } else {
      # Definir prioris para itens livres
      # Discriminação: log-normal (mesmo do BILOG-MG)
      pars[ip, 10] <- "lnorm"
      pars[ip, 11:12] <- c(1, exp(0.5))
      
      # Dificuldade: normal (mesmo do BILOG-MG)
      pars[ip + 1, 10] <- "norm"
      pars[ip + 1, 11:12] <- c(0, 2)
      
      # Acerto casual: normal aproximando Beta(5,17)
      pars[ip + 2, 10] <- "norm"
      pars[ip + 2, 11:12] <- c(-1, 0.33)
    }
  }
  
  # Calibrar
  pars.f <- mirt(data, 1, itemtype = PL, pars = pars)
  
  # Extrair parâmetros
  zeta <- coef(pars.f, IRTpars = TRUE, simplify = TRUE)$items[, 1:kPL]
  colnames(zeta) <- c("a", "b", "c", "u")[1:kPL]
  
  cat("\nEstimativas dos parâmetros dos itens:\n")
  print(round(zeta, 3))
  
  return(zeta)
}
```

---

## 8. Considerações Importantes

### 8.1 Diferenças mirt vs BILOG-MG

| Aspecto | mirt | BILOG-MG |
|---------|------|----------|
| Efeito shrinkage | Menor | Maior |
| Tempo computacional | Maior | Menor |
| Fixação de parâmetros | Via matriz `pars` | Via prioris com SD pequeno |
| Formato de saída | Slope-intercept | IRT padrão |

### 8.2 Cuidados na Equalização

1. **Pontos de quadratura:** Aumentar com número de grupos (`quadpts = K * 40`)
2. **Ciclos EM:** Aumentar com número de grupos (`NCYCLES = K * 500`)
3. **Convergência:** Verificar `TOL` e mensagens de warning
4. **Identificabilidade:** Sempre fixar média e variância de um grupo (referência)

### 8.3 Verificação de Convergência

```r
# Verificar convergência
mod <- mirt(...)
extract.mirt(mod, 'converged')  # Deve retornar TRUE

# Se não convergiu, aumentar NCYCLES ou ajustar TOL
```

---

## 9. Referências

- Andrade, D. F., Tavares, H. R., & Valle, R. C. (2000). *Teoria da Resposta ao Item: Conceitos e Aplicações*. SINAPE.
- Chalmers, R. P. (2012). mirt: A Multidimensional Item Response Theory Package for the R Environment. *Journal of Statistical Software*, 48(6), 1-29.
- INEP. (2023). *Especificações/Configurações para a Equalização no MIRT*. Portaria 441/2023.
- Lord, F. M., & Novick, M. R. (1968). *Statistical Theories of Mental Test Scores*. Addison-Wesley.
- Samejima, F. (1969). Estimation of latent ability using a response pattern of graded scores. *Psychometrika*, 34(1), 1-97.

---

## 10. Exemplo Completo: Equalização Saeb

```r
library(mirt)

# Dados: matriz com respostas e coluna 'grupo'
# Itens 1-20: comuns entre grupos
# Itens 21-45: únicos de cada grupo

# Definir modelo com itens comuns
modelo_saeb <- mirt.model('
  F = 1-45
  CONSTRAINB = (1-20, a1), (1-20, d), (1-20, g)
  PRIOR = (1-45, a1, lnorm, -0.6550, 1.1445),
          (1-45, g, norm, -1.386, 0.5)
')

# Configurar invariância para itens comuns
invariance <- c(names(dados)[1:45], 'slopes', 'intercepts', 'free_var', 'free_means')

# Número de grupos
K <- length(unique(dados$grupo))

# Executar equalização
mod_saeb <- multipleGroup(
  dados[, 1:45],  # Apenas colunas de itens
  modelo_saeb,
  itemtype = "3PL",
  group = dados$grupo,
  invariance = invariance,
  TOL = 1e-6,
  quadpts = K * 40,
  technical = list(NCYCLES = K * 500)
)

# Extrair parâmetros na escala comum
parametros <- coef(mod_saeb, IRTpars = TRUE, simplify = TRUE)
print(parametros$items)

# Estimar proficiências
theta <- fscores(mod_saeb, method = "EAP")
```
