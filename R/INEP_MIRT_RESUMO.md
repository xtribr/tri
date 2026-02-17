# Resumo: Especificações INEP para Equalização MIRT

## Documento Oficial
- **Título:** Especificações/Configurações para a Equalização no MIRT
- **Órgão:** INEP - Instituto Nacional de Estudos e Pesquisas Educacionais Anísio Teixeira
- **Comissão:** Comissão de Assessoramento em Estatística e Psicometria
- **Portarias:** 722/2019 e 441/2023

---

## Conceitos Fundamentais

### 1. Tipos de Equalização

#### Equalização via População
- Usada quando um único grupo é submetido a provas distintas
- Todos os itens são calibrados conjuntamente
- Garante mesma métrica automaticamente

#### Equalização via Itens Comuns
- Usada quando grupos diferentes respondem provas parcialmente distintas
- Itens comuns servem de "âncora" entre grupos
- Permite comparar proficiências em escala única

### 2. Seis Situações de Equalização

```
Caso 1: 1 grupo, 1 prova (caso mais simples)
Caso 2: 1 grupo dividido, 2 provas totalmente distintas
Caso 3: 1 grupo dividido, 2 provas parcialmente distintas (itens comuns)
Caso 4: 2 grupos, 1 prova
Caso 5: 2 grupos, 2 provas totalmente distintas (não equalizável)
Caso 6: 2 grupos, 2 provas parcialmente distintas (mais comum na prática)
```

---

## Configurações Técnicas Recomendadas

### 1. Calibração Básica

```r
mod <- mirt(
  Dados,
  1,
  itemtype = "3PL",
  TOL = 1e-6,           # Tolerância padrão
  quadpts = 40,         # Pontos de quadratura
  technical = list(NCYCLES = 500)
)
```

### 2. Equalização com Múltiplos Grupos

**Regra crucial:** Aumentar pontos de quadratura e ciclos EM proporcionalmente ao número de grupos (K)

```r
mod <- multipleGroup(
  Dados,
  modelo,
  itemtype = "3PL",
  group = Grupos,
  TOL = 1e-6,
  quadpts = K * 40,           # K = número de grupos
  technical = list(NCYCLES = K * 500)
)
```

### 3. Prioris Recomendadas

#### Para Discriminação (a)
- Distribuição: Log-normal (`lnorm`)
- Parâmetros: média = 1, desvio = exp(0.5)
- Justificativa: a > 0 sempre

#### Para Dificuldade (b)
- Distribuição: Normal (`norm`)
- Parâmetros: média = 0, desvio = 2
- Justificativa: b pode assumir qualquer valor real

#### Para Acerto Casual (c) - ENEM
- Distribuição: Beta(`beta`, 4, 16) ou Normal(`norm`, -1.386, 0.5)
- Valor esperado: 0.2 (para 5 alternativas)
- Justificativa: 4/(4+16) = 1/5 = 0.2

---

## Diferenças Importantes: mirt vs BILOG-MG

| Característica | mirt | BILOG-MG |
|----------------|------|----------|
| **Efeito Shrinkage** | Menor | Maior |
| **Tempo computacional** | Maior | Menor |
| **Fixação de parâmetros** | Matriz `pars` com `est = FALSE` | Prioris com desvio-padrão muito pequeno (10⁻³ ou 10⁻⁴) |
| **Formato de parâmetros** | Slope-intercept (a, d) | IRT padrão (a, b, c) |
| **Conversão b → d** | d = -a × b | - |

---

## Procedimento de Fixação de Parâmetros no mirt

### Passo 1: Obter matriz de parâmetros
```r
PRM <- mirt(data, 1, itemtype = "3PL", pars = 'values')
```

### Passo 2: Identificar linhas dos itens a fixar
- Estrutura da matriz: 3 linhas por item (a1, d, g)
- Item 1: linhas 1, 2, 3
- Item i: linhas 4i-3, 4i-2, 4i-1

### Passo 3: Converter b para intercepto
```r
d <- -a * b  # Fórmula de conversão
```

### Passo 4: Atualizar matriz
```r
pars$value[linha] <- valor_fixo
pars$est[linha] <- FALSE  # Não estimar este parâmetro
```

### Passo 5: Calibrar com parâmetros fixos
```r
mod_fixo <- mirt(data, 1, itemtype = "3PL", pars = pars)
```

---

## Sintaxe de Modelo no mirt

### Especificação Básica
```r
modelo <- mirt.model('
  F = 1-45                    # Itens 1 a 45 carregam no fator F
  CONSTRAINB = (1-20, a1),    # Itens 1-20 têm discriminação comum
               (1-20, d),     # Itens 1-20 têm dificuldade comum
               (1-20, g)      # Itens 1-20 têm acerto casual comum
  PRIOR = (1-45, a1, lnorm, -0.6550, 1.1445),
          (1-45, g, norm, -1.386, 0.5)
')
```

### Invariância entre Grupos
```r
invariance <- c(names(Dados), 'slopes', 'intercepts', 'free_var', 'free_means')
```

---

## Modelo 5PL (Extensão)

Função de resposta ao item:
```
P(Uij = 1 | θj, ai, bi, ci, γi, δi) = ci + (γi - ci) / [1 + δi × exp(-ai × D × (θj - bi))]^(1/δi)
```

Onde:
- **γi (gamma)**: Probabilidade de pessoas de alta proficiência errarem (limite superior < 1)
- **δi (delta)**: Controla assimetria da curva característica do item
- Quando γi = δi = 1: reduz-se ao modelo 3PL

---

## Cuidados na Implementação

### 1. Convergência
- Sempre verificar se o modelo convergiu
- Se não convergiu: aumentar `NCYCLES` ou ajustar `TOL`
- Verificar: `extract.mirt(mod, 'converged')`

### 2. Identificabilidade
- Fixar média = 0 e variância = 1 de um grupo (referência)
- Grupos adicionais têm média e variância livres

### 3. Escolha de Itens Comuns
- Devem cobrir toda a faixa de dificuldade
- Mínimo recomendado: 10-20% dos itens ou 20-30 itens âncora
- Devem ter boa qualidade psicométrica

### 4. Verificação da Equalização
- Comparar parâmetros dos itens âncora entre grupos
- Verificar se estatísticas de ajuste são adequadas
- Analisar correlação entre proficiências estimadas

---

## Exemplo Prático: Saeb Ensino Médio

```r
# Contexto: 2 cadernos de 13 itens cada, total 26 itens respondidos
# Banco de itens: 91 itens no total

# Formato compacto: vetor de respostas com 26 posições + indicador de caderno
# Formato aberto: vetor de respostas com 91 posições (NA para itens não respondidos)

library(mirt)

# Definir modelo com itens comuns entre cadernos
modelo_saeb <- mirt.model('
  F = 1-91
  CONSTRAINB = (1-15, a1), (1-15, d), (1-15, g)  # 15 itens âncora
  PRIOR = (1-91, a1, lnorm, -0.6550, 1.1445),
          (1-91, g, norm, -1.386, 0.5)
')

# Configurar invariância
invariance <- c(names(dados)[1:91], 'slopes', 'intercepts', 'free_var', 'free_means')

# Equalizar (exemplo com 2 grupos/estados)
K <- 2
mod_saeb <- multipleGroup(
  dados[, 1:91],
  modelo_saeb,
  itemtype = "3PL",
  group = dados$estado,
  invariance = invariance,
  TOL = 1e-6,
  quadpts = K * 40,           # 80 pontos
  technical = list(NCYCLES = K * 500)  # 1000 ciclos
)

# Resultados na escala comum
parametros <- coef(mod_saeb, IRTpars = TRUE, simplify = TRUE)
proficiencias <- fscores(mod_saeb, method = "EAP")
```

---

## Referências Bibliográficas do Documento

1. Andrade, D. F., Tavares, H. R., & Valle, R. C. (2000). Teoria da Resposta ao Item: Conceitos e Aplicações.
2. Chalmers, R. P. (2012). mirt: A Multidimensional Item Response Theory Package for the R Environment.
3. Rasch, G. (1960). Probabilistic Models for Some Intelligence and Attainment Tests.
4. Lord, F. M., & Novick, M. R. (1968). Statistical Theories of Mental Test Scores.
5. Samejima, F. (1969). Estimation of latent ability using a response pattern of graded scores.
6. Muraki, E. (1992). A generalized partial credit model.
7. Andrich, D. (1978). A rating formulation for ordered response categories.
8. Bock, R. D. (1972). Estimating item parameters and latent ability when responses are scored in two or more nominal categories.
9. Maydeu-Olivares, A. (2006). Item response theory data analysis using Stata.
10. Roberts, J. S., Donoghue, J. R., & Laughlin, J. E. (2000). A general item response theory model for unfolding unidimensional polytomous responses.
11. Tutz, G. (1990). Sequential item response models with an ordered response.
12. Embretson, S. E. (1980). Multicomponent latent trait models for ability tests.
13. Suh, Y., & Bolt, D. M. (2010). Nested logit models for multiple-choice item response data.
14. Winsberg, S., Thissen, D., & Wainer, H. (1984). Fitting item characteristic curves with spline functions.
15. Falk, C. F., & Cai, L. (2016). Maximum marginal likelihood estimation of a monotonic polynomial IRT model.

---

## Notas Finais

> "O uso de itens comuns entre provas distintas aplicadas a populações distintas permite que todos os parâmetros estejam na mesma escala ao final dos processos de estimação, possibilitando comparações e a construção de 'escalas do conhecimento' interpretáveis."
> — INEP, 2023

> "A equalização no R precisa de cuidados adicionais quando comparada à equalização no BILOG-MG. Por outro lado, há efeitos tipo SHRINKAGE que são menores no mirt."
> — INEP, 2023
