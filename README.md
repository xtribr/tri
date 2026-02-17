# TRI - Sistema de Análise Psicométrica para Exames Educacionais

[![R](https://img.shields.io/badge/R-4.5+-blue.svg)](https://www.r-project.org/)
[![mirt](https://img.shields.io/badge/mirt-1.45+-green.svg)](https://github.com/philchalmers/mirt)
[![License](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

Sistema completo de análise psicométrica utilizando **Teoria de Resposta ao Item (TRI)** para exames educacionais de larga escala. Suporta calibração, estimação de proficiências, equalização e testes adaptativos (CAT).

## 📋 Visão Geral

Este projeto implementa metodologias avançadas de TRI para avaliações educacionais, incluindo modelos Rasch 1PL, 2PL e 3PL, com aplicações específicas para:

- **ENEM** - Exame Nacional do Ensino Médio
- **SAEB** - Sistema de Avaliação da Educação Básica  
- **ENAMED** - Exame Nacional de Avaliação Médica
- **ENARE** - Exame Nacional de Residência Médica

### Características Principais

| Recurso | Descrição |
|---------|-----------|
| **Calibração TRI** | Modelos 1PL, 2PL, 3PL com ajuste automático |
| **Equalização** | Linking entre formas via `multipleGroup()` |
| **CAT** | Testes Adaptativos Computadorizados |
| **Análise TCT** | Teoria Clássica dos Testes como pré-análise |
| **Validação** | Estatísticas de ajuste (INFIT, OUTFIT, S-X2) |
| **API REST** | Interface para integração com sistemas |

## 🚀 Funcionalidades

### 1. Calibração de Itens

```r
# Rasch 1PL (ENAMED/SAEB)
mod_rasch <- mirt(dados, model=1, itemtype="Rasch")

# 2PL (Discriminação variável)
mod_2pl <- mirt(dados, model=1, itemtype="2PL")

# 3PL ENEM (com parâmetro de acaso)
mod_3pl <- mirt(dados, model=1, itemtype="3PL", 
                parprior=list(c=cbind(4, 16)))  # Prior Beta(4,16)
```

### 2. Estimação de Escores

Métodos suportados:
- **EAP** - Expected A Posteriori (recomendado, usado pelo ENEM)
- **MAP** - Maximum A Posteriori
- **ML** - Maximum Likelihood
- **WLE** - Weighted Likelihood Estimation

### 3. Equalização entre Formas

```r
# Linking entre versões A e B da prova
mg_model <- multipleGroup(dados, model=1, group=versao,
                          invariance=c('slopes', 'intercepts'))
```

### 4. CAT (Computerized Adaptive Testing)

API REST para testes adaptativos:
- Seleção por Máxima Informação de Fisher (MFI)
- Critérios de parada configuráveis
- Content balancing (em desenvolvimento)

## 📁 Estrutura do Projeto

```
TRI/
├── 📊 output/                    # Resultados de análises
├── 🔧 scripts/                   # Scripts executáveis
│   ├── correcao_enamed.R         # Correção estilo ENAMED
│   ├── simular_candidatos.R      # Simulação em escala
│   ├── comparar_provas.R         # Análise comparativa
│   └── gerar_relatorios.R        # Relatórios Excel
│
├── 📚 docs/                      # Documentação
│   ├── ENAMED/                   # Especificações ENAMED
│   ├── BIBLIOTECA_ENEM.md        # Referências científicas
│   └── *.pdf                     # Artigos e manuais
│
├── 🔬 R/                         # Código R modular
│   ├── api/                      # APIs Plumber
│   ├── SKILL.md                  # Guia mirt
│   └── SKILL_TRI_CONTEXTOS.md    # Contextos por exame
│
├── 📋 AGENTS.md                  # Documentação completa
└── 📄 README.md                  # Este arquivo
```

## 🛠️ Tecnologias

- **R 4.5+** - Linguagem principal
- **mirt** - Modelos TRI (Item Response Theory)
- **plumber** - API REST
- **openxlsx** - Geração de relatórios Excel
- **dplyr/ggplot2** - Manipulação e visualização

## 📦 Instalação

```r
# Instalar dependências
install.packages(c("mirt", "plumber", "openxlsx", "dplyr", "ggplot2", 
                   "jsonlite", "httr", "gridExtra"))
```

## 🚀 Como Usar

### Correção de Simulado

```r
source("scripts/correcao_enamed.R")
```

**Entrada:** Arquivo CSV com respostas (0=erro, 1=acerto)

**Saída:**
- `output/correcao_enamed/resultado_candidatos.csv` - Notas e thetas
- `output/correcao_enamed/parametros_itens_tri.csv` - Parâmetros calibrados
- `output/RELATORIO_ENAMED_COMPLETO.xlsx` - Relatório Excel

### Simulação em Escala

```r
source("scripts/simular_candidatos.R")
```

Simula candidatos segundo modelo Rasch para validação da prova.

### Comparação entre Provas

```r
source("scripts/comparar_provas.R")
```

Compara estatísticas entre provas ou contra referências oficiais.

### API REST

```r
library(plumber)
pr("R/api/plumber_v2.R") %>% pr_run(port=8000)
```

Acesse a documentação interativa em: `http://localhost:8000/__docs__/`

## 📊 Modelos TRI Suportados

| Modelo | Parâmetros | Uso Típico |
|--------|-----------|------------|
| **Rasch** | b (dificuldade) | ENAMED, SAEB |
| **1PL** | a (fixo), b | Alternativa ao Rasch |
| **2PL** | a, b | Provas com discriminação variável |
| **3PL** | a, b, c | ENEM (com acaso) |
| **GRM** | múltiplos thresholds | Itens politômicos |

## 📈 Estatísticas de Ajuste

O sistema calcula automaticamente:

- **Correlação Bisserial** - Discriminação do item
- **INFIT/OUTFIT** - Ajuste ao modelo Rasch
- **S-X²** - Teste qui-quadrado de ajuste
- **Informação de Fisher** - Precisão da medição

## 📚 Documentação Técnica

- **[AGENTS.md](AGENTS.md)** - Documentação completa do projeto
- **[R/SKILL.md](R/SKILL.md)** - Guia de uso do pacote mirt
- **[R/SKILL_TRI_CONTEXTOS.md](R/SKILL_TRI_CONTEXTOS.md)** - Contextos ENAMED/ENEM/SAEB

### Fontes Oficiais

- **INEP** - Especificações para Equalização no MIRT (Portaria 441/2023)
- **Notas Técnicas ENAMED** - Metodologia oficial de correção
- **Artigos Científicos** - Biblioteca em `docs/BIBLIOTECA_ENEM.md`

## 🔬 Metodologia

### Fluxo de Análise

1. **Pré-análise TCT** - Estatísticas descritivas, taxa de acerto, correlações
2. **Calibração TRI** - Estimação de parâmetros (a, b, c)
3. **Validação** - Estatísticas de ajuste, análise de resíduos
4. **Estimação** - Cálculo de thetas (EAP/MAP/ML)
5. **Transformação** - Conversão para escala percentual ou 0-1000

### Pressupostos do Modelo

- Unidimensionalidade (itens medem um construto único)
- Independência local (itens não correlacionados)
- Monotonicidade (probabilidade cresce com habilidade)

## 🎯 Aplicações

Este sistema é adequado para:

- **Instituições educacionais** - Correção de simulados e avaliações
- **Bancas examinadoras** - Análise de itens e calibração
- **Pesquisadores** - Estudos psicométricos em educação
- **Preparatórios** - Sistemas de correção personalizados

## 📝 Configurações por Contexto

### ENAMED (Rasch 1PL + Angoff)

```r
mirt(dados, 1, itemtype="Rasch")
theta <- fscores(mod, method="EAP")
nota <- 50 + 10 * theta  # Transformação linear
```

### ENEM (3PL com priors)

```r
mirt(dados, 1, itemtype="3PL",
     parprior=list(c=cbind(4, 16)))  # E[c] = 0.20
```

### SAEB (Equalização múltiplos grupos)

```r
multipleGroup(dados, 1, group=ano, 
              invariance=c('slopes', 'intercepts'))
```

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Add nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👨‍💻 Autor

**xtribr** - [GitHub](https://github.com/xtribr)

---

**Nota:** Este é um sistema de código aberto para análise psicométrica. Para uso em produção, recomenda-se validação com especialistas em psicometria.
