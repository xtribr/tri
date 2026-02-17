# Projeto TRI - Análise de Itens do ENAMED/ENARE

## Visão Geral do Projeto

Este projeto contém dados de análise psicométrica utilizando a Teoria de Resposta ao Item (TRI - Item Response Theory) aplicada ao exame ENAMED (Exame Nacional de Avaliação Médica) e ENARE (Exame Nacional de Residência Médica) 2026.

O objetivo principal é realizar a calibração de itens e ancoragem de questões através do método de correspondência entre parâmetros TRI (parâmetro de dificuldade `b` do modelo Rasch 1PL) e valores Angoff (percentual de acerto estimado por especialistas para um médico minimamente competente).

## Estrutura do Projeto

O projeto consiste em três arquivos principais:

### 1. `angoff_ancoras.json`
Arquivo JSON contendo os dados de ancoragem das questões de referência (âncoras).

**Conteúdo:**
- **Metadata:** Informações sobre a fonte dos dados (Nota Técnica 19/2025/CGAFM/DAES-INEP), método de matching, validação estatística
- **Ancoras:** Array com 10 questões de referência mapeadas entre o simulado e o ENAMED oficial

**Campos principais das âncoras:**
- `posicao_simulado`: Posição da questão no simulado
- `questao_enamed`: Número da questão correspondente no ENAMED
- `cod`: Código único da questão
- `bni_provavel`: Identificador do Banco Nacional de Itens (BNI)
- `angoff_provavel`: Valor Angoff estimado (%)
- `b_tri`: Parâmetro de dificuldade TRI (escala logit)
- `taxa_acerto_enamed`: Taxa de acerto real no ENAMED
- `gabarito`: Resposta correta
- `area`, `tema`, `subtema`: Classificação da questão
- `confianca`: Nível de confiança do match (ALTA/ATENCAO)

### 2. `aplicacao.csv`
Dados brutos de respostas de candidatos em formato CSV separado por ponto-e-vírgula (`;`).

**Estrutura:**
- 591 linhas (590 candidatos + cabeçalho)
- 102 colunas: `nome`, `email`, `Q1` a `Q100`
- Codificação: Non-ISO extended-ASCII (possui caracteres especiais em nomes)
- Terminadores de linha: CRLF
- Valores: `0` (erro), `1` (acerto)

### 3. `todos_completos.csv`
Dados de respostas com identificação completa dos itens em formato CSV separado por vírgula (`,`).

**Estrutura:**
- 592 linhas (591 candidatos + cabeçalho)
- 102 colunas: `nome`, `email`, e códigos completos dos itens
- Codificação: UTF-8
- Os cabeçalhos das colunas de questões seguem o padrão: `ENARE-2026-R1-XX-ORIG-OBJ` ou `SPRMED-ENAMED-2026-R1-XX-OBJ`

## Tecnologia e Metodologia

### Modelo Estatístico
- **Modelo TRI:** Rasch 1PL (1 Parameter Logistic)
- **Parâmetro estimado:** `b` (dificuldade do item)
- **Método de Ancoragem:** Match por ranking entre parâmetro `b` e valores Angoff

### Validação Estatística
- Correlação de Pearson entre `b` e Angoff: -0.9546
- Regressão logit: `logit(Angoff/100) = alpha + beta * b`
  - alpha: 0.189903
  - beta: -0.276751
  - R²: 0.923178
- Erro padrão dos resíduos: 0.099031

### Pontos de Corte
- `theta_corte`: -0.4 (escala TRI)
- `nota_corte_enamed`: 60.0 (escala percentual)

## Convenções de Dados

### Nomenclatura de Itens
- Itens ENARE oficiais: `ENARE-2026-R1-XX-ORIG-OBJ`
- Itens SPRMED/ENAMED: `SPRMED-ENAMED-2026-R1-XX-OBJ`

### Áreas Médicas Representadas
- Cirurgia
- Ginecologia e Obstetrícia
- Medicina Preventiva
- Pediatria
- Clínica Médica

### Níveis de Confiança
- **ALTA**: Resíduo dentro do erro padrão (match confiável)
- **ATENCAO**: Resíduo acima do erro padrão (match com incerteza)

## Itens Excluídos
Os seguintes itens do BNI foram excluídos da análise:
```
142966, 143036, 143467, 143570, 147617, 147943, 148054, 148131, 148467, 161803
```

## Uso dos Dados

### Para Análise Psicométrica
1. Calcular estatísticas descritivas por item
2. Estimar parâmetros TRI (se necessário reestimar)
3. Validar consistência com as âncoras existentes
4. Calcular escores de habilidade (theta) dos candidatos

### Para Relatórios
- Comparar desempenho do simulado vs ENAMED oficial
- Analisar consistência das âncoras
- Gerar relatórios por área médica

## Documentação Técnica Adicional

### Skills e Referências

1. **Skill TRI com R/mirt** (`R/SKILL.md`): Guia completo de boas práticas para análise TRI usando o pacote R `mirt`, incluindo:
   - Comandos básicos de calibração e scoring
   - Configurações para equalização com múltiplos grupos
   - Especificação de prioris para controle de parâmetros
   - Procedimentos de fixação de parâmetros (itens âncora)
   - Exemplos práticos de equalização

2. **Skill TRI por Contexto** (`R/SKILL_TRI_CONTEXTOS.md`): Especificações técnicas detalhadas para cada tipo de avaliação:
   - **ENAMED**: Modelo Rasch 1PL combinado com Método Angoff Modificado
   - **ENEM**: Modelo 3PL com prioris específicas (Beta(4,16) para c)
   - **SAEB**: Equalização via itens comuns com múltiplos grupos
   - **GRADED EXAMS**: Modelos para itens politômicos (GRM, GPCM, RSM)
   - Comparação entre contextos e funções utilitárias

3. **Resumo INEP MIRT** (`R/INEP_MIRT_RESUMO.md`): Resumo das especificações oficiais do INEP para equalização, incluindo:
   - 6 situações de equalização
   - Diferenças entre mirt e BILOG-MG
   - Configurações técnicas recomendadas
   - Cuidados na implementação

### Fonte Oficial

As especificações técnicas seguem o documento **"Especificações/Configurações para a Equalização no MIRT"** do INEP (Instituto Nacional de Estudos e Pesquisas Educacionais Anísio Teixeira), Portaria 441/2023, Comissão de Assessoramento em Estatística e Psicometria.

### Biblioteca de Artigos Científicos

A pasta `docs/` contém **14 artigos científicos** sobre ENEM e TRI:

- **`BIBLIOTECA_ENEM.md`**: Catálogo completo dos artigos organizados por relevância
- **`INSIGHTS_ARTIGOS_ENEM.md`**: Principais aprendizados técnicos aplicáveis ao projeto

**Artigos em destaque:**
- "Como os escores do ENEM são atribuídos pela TRI?" (Primi & Cicchetto) - explicação técnica do modelo 3PL
- "Análise da estrutura interna do ENEM" (Travitzki & Primi) - dimensionalidade das provas
- "Efeito de posição na dificuldade dos itens do ENEM" (Franklin et al.) - implicações para equating
- "É possível calibrar os itens do Enem sem pré-teste?" (Jaloto et al.) - metodologia de calibração
- "TRI Profundo: redes neurais aplicadas à TRI" (Bastos) - inovação metodológica

### Sistema TRI v2 para Mentorias

**`PROPOSTAS_MELHORIAS_SISTEMA.md`**: Documento completo com propostas de evolução do sistema para mentorias.

**Principais melhorias implementadas na API v2 (`R/api/plumber_v2.R`):**

1. **Módulo de Calibração Avançada:**
   - Análise TCT preliminar (`POST /tct/analisar`)
   - Calibração com âncoras fixas (equalização)
   - Modelo 3PL_ENEM com prioris Beta(4,16)
   - Estatísticas de ajuste por item

2. **Módulo CAT Robusto:**
   - Sessões persistentes com estados (INICIADO → EM_ANDAMENTO → FINALIZADO)
   - Content balancing (balanceamento por áreas)
   - Múltiplos critérios de parada (precisão, convergência, nº máximo)
   - Transformação para escala 0-1000

3. **Módulo Scoring com Regressão:**
   - Ensemble TRI + Regressão Linear
   - Intervalos de confiança
   - Classificação por nível (BÁSICO/INTERMEDIÁRIO/AVANÇADO)

**Script de teste:** `scripts/testar_api_v2.R`

## Funcionalidades Avançadas do Pacote MIRT

Documentação baseada no repositório oficial: https://github.com/philchalmers/mirt

**Nota:** Não é necessário clonar o repositório - o pacote `mirt` já está instalado via CRAN. O código fonte no GitHub é destinado a desenvolvedores que desejam contribuir com o pacote.

### Funcionalidades de ALTA Prioridade (Implementar Futuramente)

#### 1. `multipleGroup()` - Equalização/Linking
**Uso:** Garantir comparabilidade entre diferentes versões do simulado (A/B) ou entre anos.

**Quando implementar:**
- Quando houver múltiplas formas do simulado com itens embaralhados
- Para comparar resultados entre diferentes aplicações
- Para linking com o ENAMED oficial

**Exemplo:**
```r
mg_model <- multipleGroup(dados, model=1, group=versao, 
                          invariance=c('slopes', 'intercepts'))
```

**Status:** Não implementado | **Prioridade:** ALTA

---

### Funcionalidades de MÉDIA Prioridade (Bom ter)

#### 2. `itemplot()` - Gráficos Avançados
**Uso:** Visualização detalhada das características dos itens.

**Funcionalidades:**
- Curvas Características do Item (ICC) paramétricas e não paramétricas
- Curvas de Informação do Item e do Teste
- Surface plots para modelos multidimensionais
- Gráficos de resíduos para diagnóstico

**Exemplo:**
```r
itemplot(mod_rasch, item=1, type='ICC')  # Curva característica
itemplot(mod_rasch, type='info')          # Informação do teste
```

**Status:** Parcialmente implementado (gráficos básicos em scripts/correcao_enamed.R)

#### 3. `M2()` - Teste de Ajuste Global
**Uso:** Estatística de ajuste do modelo completo (não apenas por item).

**Descrição:**
- Estatística M2 de Maydeu-Olivares & Joe
- Ajuste global do modelo TRI aos dados
- Complementa o `itemfit()` que já usamos para ajuste por item

**Exemplo:**
```r
M2(mod_rasch)  # Teste de ajuste global
```

**Status:** Não implementado | **Prioridade:** MÉDIA

#### 4. Configurações `technical` Otimizadas
**Uso:** Otimizar convergência para grandes amostras (40k+).

**Parâmetros recomendados para grandes amostras:**
```r
mirt(dados, 1, itemtype="Rasch",
     technical = list(
       NCYCLES=2000,      # Aumentar iterações máximas
       TOL=0.0001,        # Tolerância mais rigorosa
       parallel=TRUE,     # Paralelização automática
       QR=TRUE            # Decomposição QR para estabilidade
     ))
```

**Status:** Parcialmente implementado | **Prioridade:** MÉDIA

---

### Funcionalidades Existentes (Já Utilizadas)

| Função | Uso Atual | Status |
|--------|-----------|--------|
| `mirt()` | Calibração Rasch 1PL | ✅ Implementado |
| `fscores()` | Estimação EAP de thetas | ✅ Implementado |
| `itemfit()` | Estatísticas de ajuste (INFIT/OUTFIT) | ✅ Implementado |
| `simdata()` | Simulação de 40k candidatos | ✅ Implementado |
| `coef()` | Extração de parâmetros | ✅ Implementado |
| `residuals()` | Resíduos Q3 (dependência local) | ✅ Parcial |

---

### Modelos Suportados pelo MIRT (Referência)

| Modelo | Tipo | Uso no ENAMED |
|--------|------|---------------|
| Rasch | Dicotômico | ✅ Principal |
| 1PL | Dicotômico | ✅ Equivalente ao Rasch |
| 2PL | Dicotômico | Opcional (se houver discriminação variável) |
| 3PL | Dicotômico | ENEM (com parâmetro de acaso) |
| GRM | Politômico | Possível (itens parcialmente creditados) |
| GPCM | Politômico | Possível (modelo de crédito generalizado) |

---

### Recursos de Documentação do Repositório

**Vignettes disponíveis (acessíveis via `vignette("nome")`):**
- `vignette("mirt")` - Tutorial completo do pacote
- `vignette("multidimensional")` - Modelos multidimensionais
- `vignette("DIF")` - Análise de Differential Item Functioning
- `vignette("PLmixed”)` - Modelos mistos com efeitos aleatórios

**Nota:** Análise DIF (`DIF()`, `lordif()`) foi considerada mas não será implementada no momento a pedido do usuário.

## Notas Técnicas

1. **Diferença de formatos:** Os arquivos CSV usam separadores diferentes (`;` vs `,`) e codificações distintas. Ao processar, verificar a codificação correta para nomes com acentos.

2. **Matching de itens:** O arquivo `angoff_ancoras.json` contém apenas 10 âncoras selecionadas estrategicamente para cobrir diferentes níveis de dificuldade (rankings 30-70).

3. **Fonte dos dados Angoff:** Valores pré-normalização da Nota Técnica 19/2025 (antes da remoção de 2 juízes outliers).

4. **Interpretação do beta:** O coeficiente beta (-0.276751) difere de -1 porque o range do Angoff (julgamento humano) está comprimido comparado à escala TRI.

5. **Equalização:** Para equalização entre diferentes aplicações do simulado ou com o ENAMED oficial, usar a função `multipleGroup()` do pacote mirt com as configurações recomendadas pelo INEP (ver `R/SKILL.md`).

## Backup e Versionamento

**Repositório GitHub:** https://github.com/xtribr/tri.git

### Como fazer backup

```bash
# Backup manual
git add -A
git commit -m "Descrição das alterações"
git push origin main

# Ou usar o script automatizado
./scripts/backup_github.sh
```

### Arquivos versionados

- ✅ Código-fonte (scripts R, APIs)
- ✅ Documentação (AGENTS.md, SKILL.md)
- ✅ Resultados processados (CSV, Excel)
- ✅ Gráficos e visualizações
- ⚠️ Microdados ENAMED (grandes arquivos de texto)
- ❌ Arquivos temporários (.tmp, .log)
- ❌ Modelos .rds grandes (exceto os essenciais)

### Histórico de commits

- **Initial commit** (2026-02-17): Projeto completo com análise de 591 candidatos, simulação 40k e comparação ENAMED
