# Resumo dos Modelos TRI por Avaliação

## ENAMED - Exame Nacional de Avaliação da Formação Médica

### Modelo: Rasch 1PL + Método Angoff Modificado

```
P(acerto | θ, b) = exp(θ - b) / (1 + exp(θ - b))
```

**Características:**
- **Apenas parâmetro b** (dificuldade) - discriminação fixa em 1
- **100 itens** de múltipla escolha (4 alternativas)
- **Combinação única**: TRI para estimar proficiências + Angoff para definir pontos de corte
- **Estatísticas de ajuste**: INFIT e OUTFIT (padrão Rasch)

**Arquivos de referência:**
- `docs/ENAMED/DADOS/microdados2025_parametros_itens.txt`
- `docs/ENAMED/1. LEIA-ME/Manual do usuário_Enamed_2025.pdf`

**Implementação R:**
```r
mirt(dados, 1, itemtype = "Rasch")
```

---

## ENEM - Exame Nacional do Ensino Médio

### Modelo: 3PL (Três Parâmetros Logísticos)

```
P(acerto | θ, a, b, c) = c + (1-c) / (1 + exp(-a(θ-b)))
```

**Características:**
- **Parâmetros**: a (discriminação), b (dificuldade), c (acerto casual)
- **180 itens** (45 por área), 5 alternativas
- **Priori para c**: Beta(4,16) → E[c] = 0.20

**Implementação R:**
```r
mirt(dados, modelo, itemtype = "3PL",
     PRIOR = (1-45, g, beta, 4, 16))
```

---

## SAEB - Sistema de Avaliação da Educação Básica

### Modelo: 3PL + Equalização via Itens Comuns

**Características:**
- **Múltiplos cadernos** com itens âncora em comum
- **Equalização** entre cadernos e anos usando `multipleGroup()`
- **Pontos de quadratura**: Aumentam com número de grupos (K × 40)

**Implementação R:**
```r
multipleGroup(dados, modelo, group = grupos,
              quadpts = K * 40,
              technical = list(NCYCLES = K * 500))
```

---

## Itens Politômicos (GRADED)

### Modelos: GRM, GPCM, RSM

**Usado em:**
- Questionários de percepção
- Escalas Likert
- Avaliações dissertativas

**Implementação R:**
```r
mirt(dados, 1, itemtype = "graded")  # GRM
mirt(dados, 1, itemtype = "gpcm")    # GPCM
```

---

## Tabela Comparativa

| Característica | ENAMED | ENEM | SAEB | GRADED |
|----------------|--------|------|------|--------|
| **Modelo** | Rasch 1PL | 3PL | 3PL | GRM/GPCM |
| **Parâmetros** | b | a, b, c | a, b, c | a, b's |
| **Nº Itens** | 100 | 180 | Variável | Variável |
| **Alternativas** | 4 | 5 | 4-5 | N/A |
| **Tipo** | Dicotômico | Dicotômico | Dicotômico | Politômico |
| **Equalização** | Não | Não | Sim (itens comuns) | N/A |
| **Método Angoff** | Sim | Não | Não | Não |

---

## Estrutura de Documentação

```
R/
├── SKILL.md                    # Guia geral do pacote mirt
├── SKILL_TRI_CONTEXTOS.md      # Especificações por exame
├── INEP_MIRT_RESUMO.md         # Resumo INEP equalização
└── api/
    └── plumber.R               # API para calibração

docs/
├── ENAMED/                     # Documentação ENAMED 2025
│   ├── 1. LEIA-ME/
│   │   ├── Manual do usuário_Enamed_2025.pdf
│   │   └── Dicionário...
│   └── DADOS/
│       └── microdados2025_parametros_itens.txt
└── RESUMO_MODELOS_TRI.md       # Este arquivo
```

---

## Referências Rápidas

### Comandos R por Contexto

```r
# ENAMED (Rasch)
mirt(dados, 1, itemtype = "Rasch")

# ENEM (3PL)
mirt(dados, 1, itemtype = "3PL")

# SAEB (Equalização)
multipleGroup(dados, modelo, group = grupos)

# Itens Politômicos
mirt(dados, 1, itemtype = "graded")
```

### Verificação de Ajuste

```r
# Rasch (ENAMED)
itemfit(modelo)  # INFIT/OUTFIT

# 3PL (ENEM/SAEB)
M2(modelo)       # Ajuste global
itemfit(modelo)  # Ajuste por item
```

### Extração de Parâmetros

```r
coef(modelo, IRTpars = TRUE, simplify = TRUE)
fscores(modelo, method = "EAP")
```
