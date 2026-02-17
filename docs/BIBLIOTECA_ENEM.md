# Biblioteca de Artigos - ENEM e TRI

## 📚 Artigos sobre ENEM e Teoria de Resposta ao Item

Esta biblioteca contém artigos científicos relevantes para o estudo do ENEM, com foco em Teoria de Resposta ao Item (TRI), calibração de itens e análise psicométrica.

---

## 🎯 Alta Relevância (Análise Direta do ENEM)

### 1. Como os escores do ENEM são atribuídos pela TRI?
**Arquivo:** `92067.pdf`  
**Autores:** Ricardo Primi, Airton A. Cicchetto (Universidade São Francisco)

**Resumo:** Artigo técnico explicativo sobre como o modelo de TRI de 3 parâmetros atribui notas aos alunos no ENEM. Caracteriza o efeito do modelo na atribuição de escores.

**Pontos-chave:**
- Explicação didática do funcionamento da TRI no ENEM
- Modelo 3PL aplicado ao contexto do ENEM
- Efeitos do modelo na atribuição de notas

**Aplicação prática:**
```r
# Reproduzir análise similar
mod_enem <- mirt(dados, 1, itemtype = "3PL")
theta <- fscores(mod_enem, method = "EAP")
```

---

### 2. Análise da estrutura interna do ENEM com foco em Ciências Naturais
**Arquivo:** `91989.pdf`  
**Autores:** Rodrigo Travitzki, Ricardo Primi (Universidade São Francisco)

**Resumo:** Investiga aspectos da validade das provas do ENEM (estrutura interna), com especial atenção à área de Ciências Naturais. Análise dos microdados de 2014 e 2015.

**Pontos-chave:**
- Estrutura interna das provas do ENEM
- Análise fatorial e dimensionalidade
- Ciências Naturais como caso de estudo

---

### 3. Análise do Exame Nacional do Ensino Médio via Teoria Clássica dos Testes e Teoria de Resposta ao Item
**Arquivo:** `93552.pdf`  
**Autores:** Leandro Araujo de Sousa, Levi Mendes Franklin, José Airton de Freitas Pontes Junior, Nicolino Trompieri Filho

**Resumo:** Comparação entre análise via Teoria Clássica dos Testes (TCT) e Teoria de Resposta ao Item (TRI) no contexto do ENEM.

**Pontos-chave:**
- Comparação TCT vs TRI
- Vantagens e limitações de cada abordagem
- Aplicação prática aos dados do ENEM

**Aplicação prática:**
```r
# Comparar TCT e TRI
tct_stats <- classicalTest(dados)
tri_mod <- mirt(dados, 1, itemtype = "3PL")
```

---

### 4. Efeito de posição na dificuldade dos itens do Enem
**Arquivo:** `93979.pdf`  
**Autores:** Levi Mendes Franklin, Leandro Araujo de Sousa, José Airton de F. Pontes Junior, Nicolino Trompieri Filho

**Resumo:** Análise do efeito da posição dos itens na dificuldade percebida no ENEM. Investiga se itens em posições diferentes apresentam comportamento diferente.

**Pontos-chave:**
- Item Position Effect (efeito de posição)
- Impacto na dificuldade dos itens
- Implicações para equating

---

### 5. É possível calibrar os itens do Enem sem pré-teste?
**Arquivo:** `artigo pre-teste.pdf`  
**Autores:** Alexandre Jaloto (Inep), Alexandre José de Souza Peres (UFMS), Ana Carolina Zuanazzi (IAS)

**Resumo:** Investiga a possibilidade de calibrar itens do ENEM sem a necessidade de pré-teste tradicional. Discussão fundamental sobre metodologia de calibração.

**Pontos-chave:**
- Calibração sem pré-teste
- Viabilidade técnica e prática
- Implicações para banco de itens

---

### 6. Análise do impacto da dificuldade dos cadernos na proficiência dos alunos através da Modelagem Rasch Multifacetas
**Arquivo:** `93859.pdf`  
**Autores:** Wellington Silva, Neimar S Fernandes, Joaquim S Neto, Alicia Bonamino (CAEd/UFJF, UNB, PUC-Rio)

**Resumo:** Análise do efeito da dificuldade dos cadernos na proficiência usando Rasch multifacetas. Relevante para entender o equating entre cadernos do ENEM.

**Pontos-chave:**
- Rasch multifacetas
- Efeito dos cadernos na proficiência
- Equating entre formas

---

## 🔬 Metodologia e Inovação

### 7. TRI Profundo: uma aplicação de métodos de redes neurais profundas à Teoria de Resposta ao Item
**Arquivo:** `939130.pdf`  
**Autores:** Lucas de Moraes Bastos (Universidade de Brasília)

**Resumo:** Introduz um novo método de estimação em TRI baseado em Redes Neurais Artificiais (RNA) aplicado ao ENEM. Abordagem inovadora usando deep learning.

**Pontos-chave:**
- Deep Learning aplicado à TRI
- Redes Neurais para estimação de parâmetros
- Comparação com métodos tradicionais

---

### 8. Interdisciplinaridade no Enem: um estudo de caso das Ciências Humanas a partir do Processamento de Linguagem Natural
**Arquivo:** `PLN e o ENEM.pdf`  
**Autores:** Ester Pereira Neves de Macedo, Flávia Ghignone Braga Ribeiro (Inep)

**Resumo:** Estudo de interdisciplinaridade no ENEM usando Processamento de Linguagem Natural (PLN) em Ciências Humanas.

**Pontos-chave:**
- PLN aplicado a itens do ENEM
- Análise de interdisciplinaridade
- Ciências Humanas como caso de estudo

---

### 9. Dashboard Interativo para Análise Educacional Utilizando R e Shiny
**Arquivo:** `961166.pdf`  
**Autores:** Carlos Eduardo Rodrigues Dos Santos et al. (USP)

**Resumo:** Desenvolvimento de dashboard interativo para análise educacional usando R e Shiny. Pode ser adaptado para análise de dados do ENEM.

**Pontos-chave:**
- Dashboards interativos
- R e Shiny para educação
- Visualização de dados psicométricos

---

### 10. Ensemble de LLMs: Aliando a eficiência da IA com a expertise humana na avaliação de redações
**Arquivo:** `963377.pdf`  
**Autores:** Hugo Kenji Pereira Harada et al. (Adaptativa/UFPA)

**Resumo:** Explora o uso de ensemble de Large Language Models (LLMs) na avaliação de redações. Relevante para a correção da redação do ENEM.

**Pontos-chave:**
- LLMs na avaliação de redações
- IA + expertise humana
- Componente de redação do ENEM

---

## 📖 Fundamentos e Estratégias

### 11. Psicometria: fundamentos matemáticos da Teoria Clássica dos Testes
**Arquivo:** `primi.pdf`  
**Autores:** Ricardo Primi (Universidade São Francisco)

**Resumo:** Texto fundamental revisando a base teórica da psicometria. Apresenta fundamentos matemáticos da Teoria Clássica dos Testes, análise fatorial e modelo linear.

**Pontos-chave:**
- Fundamentos matemáticos da psicometria
- TCT como base para TRI
- Análise fatorial

**Por que ler:** Essencial para entender as bases teóricas antes de estudar TRI aplicada ao ENEM.

---

### 12. O que a TRI não nos conta? O que os itens excluídos pela TRI dizem sobre o ensino de Matemática?
**Arquivo:** `pre teste itens excluidos.pdf`  
**Autores:** Rodrigo de Souza Bortolucci et al. (Fundação VUNESP)

**Resumo:** Análise pedagógica de itens excluídos pela TRI no contexto do ensino de Matemática. Discussão crítica sobre validade dos itens.

**Pontos-chave:**
- Análise de itens excluídos
- Perspectiva pedagógica vs estatística
- Validação de itens

---

### 13. How and Why Students Use Self-Regulated Learning Strategies
**Arquivo:** `how and why std learning strategies.pdf`  
**Autores:** Vários autores (Frontiers in Psychology)

**Resumo:** Estudo sobre como e por que estudantes usam estratégias de auto-regulação da aprendizagem.

**Pontos-chave:**
- Auto-regulação da aprendizagem
- Estratégias de estudo
- Preparação para exames

---

### 14. How do Students Regulate Their Use of Multiple Choice Practice Tests?
**Arquivo:** `how do students regulate their use os multiple choice.pdf`  
**Autores:** Sabrina Badali, Katherine A. Rawson, John Dunlosky (Educational Psychology Review, 2023)

**Resumo:** Estudo experimental sobre como estudantes regulam o uso de testes de múltipla escolha para prática.

**Pontos-chave:**
- Testes de múltipla escolha como prática
- Estratégias de estudo efetivas
- Formato do ENEM

---

## 📊 Resumo por Categoria

| Categoria | Artigos | Arquivos |
|-----------|---------|----------|
| **TRI/ENEM Técnico** | 6 | 92067, 91989, 93552, 93979, artigo pre-teste, 93859 |
| **Inovação Metodológica** | 4 | 939130, PLN e o ENEM, 961166, 963377 |
| **Fundamentos/Estratégias** | 4 | primi, pre teste itens excluidos, how and why, how do students |

---

## 🎓 Roteiro de Estudo Sugerido

### Para Iniciantes em TRI/ENEM:
1. **primi.pdf** - Fundamentos teóricos
2. **92067.pdf** - Como a TRI funciona no ENEM
3. **93552.pdf** - Comparação TCT vs TRI

### Para Análise Avançada:
4. **91989.pdf** - Estrutura interna do ENEM
5. **93979.pdf** - Efeito de posição
6. **artigo pre-teste.pdf** - Calibração sem pré-teste

### Para Metodologias Inovadoras:
7. **939130.pdf** - Deep learning na TRI
8. **PLN e o ENEM.pdf** - Processamento de linguagem natural

---

## 🔗 Referências Cruzadas

- **Ricardo Primi** aparece em múltiplos artigos (92067, 91989, primi) - referência principal em TRI no Brasil
- **Levi Mendes Franklin** - especialista em efeitos de posição e estrutura de provas
- **Alexandre Jaloto (Inep)** - perspectiva institucional do INEP

---

## 💡 Aplicações Práticas no Projeto

### Calibração de Itens (simulado ENAMED):
```r
# Baseado em 92067.pdf e artigo pre-teste.pdf
mod <- mirt(dados, 1, itemtype = "3PL")
coef(mod, IRTpars = TRUE)
```

### Análise de Efeito de Posição:
```r
# Baseado em 93979.pdf
# Incluir posição do item como covariável
modelo_posicao <- mirt(dados, 1, itemtype = "3PL", 
                       covdata = data.frame(posicao = 1:ncol(dados)))
```

### Dashboard de Resultados:
```r
# Baseado em 961166.pdf
library(shiny)
# Criar dashboard interativo para análise dos resultados
```

---

## 📁 Localização dos Arquivos

Todos os arquivos estão em: `/Volumes/Kingston 1/apps/TRI/docs/`

```
docs/
├── 91989.pdf
├── 92067.pdf
├── 93552.pdf
├── 93859.pdf
├── 939130.pdf
├── 93979.pdf
├── 961166.pdf
├── 963377.pdf
├── PLN e o ENEM.pdf
├── artigo pre-teste.pdf
├── how and why std learning strategies.pdf
├── how do students regulate their use os multiple choice.pdf
├── pre teste itens excluidos.pdf
├── primi.pdf
└── BIBLIOTECA_ENEM.md (este arquivo)
```

---

**Última atualização:** 2026-02-17  
**Total de artigos catalogados:** 14
