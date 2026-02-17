# Planejamento Frontend - Sistema TRI Dashboard

## 🎯 Visão Geral

Dashboard interativo para análise psicométrica TRI com design **Notion + Apple**, permitindo upload de dados, aplicação de correções específicas por tipo de exame (ENEM, ENAMED, SAEB) e visualização avançada de resultados.

---

## 🏗️ Arquitetura Tecnológica

### Stack Principal
```
Frontend: Next.js 14 (App Router) + React 18 + TypeScript
Estilização: Tailwind CSS + shadcn/ui + Framer Motion
Gráficos: Recharts + D3.js (React wrapper)
Estado: Zustand + React Query (TanStack Query)
Upload: React Dropzone + Papa Parse (CSV/Excel)
Exportação: xlsx.js (Excel) + jsPDF + html2canvas (PDF)
```

### Comunicação Backend
```
API: Plumber (R) - Já existente em R/api/plumber_v2.R
Comunicação: REST API + WebSocket (para processamento longo)
Formato: JSON
```

---

## 📁 Estrutura de Pastas (Next.js 14)

```
tri-dashboard/
├── app/                          # App Router Next.js 14
│   ├── (auth)/                   # Grupo rotas autenticadas
│   │   ├── layout.tsx
│   │   └── dashboard/
│   │       ├── page.tsx          # Dashboard principal
│   │       ├── analise/
│   │       │   └── page.tsx      # Página de análise em andamento
│   │       └── historico/
│   │           └── page.tsx      # Histórico de análises
│   ├── api/                      # API Routes (proxy para R)
│   │   ├── upload/route.ts
│   │   ├── calibrar/route.ts
│   │   ├── status/[id]/route.ts
│   │   └── exportar/route.ts
│   ├── layout.tsx                # Root layout
│   └── page.tsx                  # Landing page
├── components/
│   ├── ui/                       # shadcn/ui components
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── dialog.tsx
│   │   ├── dropdown-menu.tsx
│   │   ├── tabs.tsx
│   │   └── ...
│   ├── layout/                   # Componentes de layout
│   │   ├── Sidebar.tsx           # Navegação lateral estilo Notion
│   │   ├── Header.tsx
│   │   └── Container.tsx
│   ├── upload/                   # Módulo de upload
│   │   ├── FileDropzone.tsx      # Área de drop estilo Apple
│   │   ├── DataPreview.tsx       # Preview dos dados (10 primeiras linhas)
│   │   └── ValidationStatus.tsx  # Status de validação
│   ├── analysis/                 # Módulo de análise
│   │   ├── ExamTypeSelector.tsx  # Seleção ENEM/ENAMED/SAEB/Custom
│   │   ├── AnalysisProgress.tsx  # Barra de progresso
│   │   └── AnalysisConfig.tsx    # Configurações avançadas
│   ├── charts/                   # Visualizações
│   │   ├── ICCChart.tsx          # Curvas Características dos Itens
│   │   ├── ScoreDistribution.tsx # Distribuição de notas
│   │   ├── AbilityHistogram.tsx  # Histograma de thetas
│   │   ├── ItemFitStats.tsx      # Estatísticas de ajuste (cards)
│   │   └── ComparisonTable.tsx   # Tabela comparativa MIN/MED/MAX
│   ├── dashboard/                # Dashboard widgets
│   │   ├── StatCard.tsx          # Cards estilo Apple (glassmorphism)
│   │   ├── QuickActions.tsx      # Ações rápidas
│   │   └── RecentAnalyses.tsx    # Análises recentes
│   └── export/                   # Exportação
│       ├── ExportDialog.tsx
│       └── ReportPreview.tsx
├── hooks/                        # Custom hooks
│   ├── useAnalysis.ts            # Gerenciamento de análise
│   ├── useUpload.ts              # Upload de arquivos
│   ├── useChartData.ts           # Dados para gráficos
│   └── useExport.ts              # Exportação
├── lib/                          # Utilitários
│   ├── utils.ts                  # cn() e helpers
│   ├── api.ts                    # Cliente API
│   ├── colors.ts                 # Paleta de cores
│   └── constants.ts              # Constantes
├── stores/                       # Estado global (Zustand)
│   ├── analysisStore.ts
│   └── uiStore.ts
├── types/                        # TypeScript types
│   ├── analysis.ts
│   ├── exam.ts
│   └── api.ts
├── styles/                       # Estilos globais
│   └── globals.css
└── public/                       # Assets estáticos
    └── images/
```

---

## 🎨 Design System - Notion + Apple

### Paleta de Cores
```css
/* Modo Claro (padrão Apple) */
--background: #ffffff;
--foreground: #1d1d1f;
--card: #f5f5f7;
--card-foreground: #1d1d1f;
--popover: #ffffff;
--popover-foreground: #1d1d1f;
--primary: #0071e3;          /* Apple Blue */
--primary-foreground: #ffffff;
--secondary: #f5f5f7;        /* Apple Gray */
--secondary-foreground: #1d1d1f;
--muted: #f5f5f7;
--muted-foreground: #86868b; /* Apple Gray Text */
--accent: #0071e3;
--accent-foreground: #ffffff;
--destructive: #ff3b30;      /* Apple Red */
--border: #d2d2d7;
--input: #d2d2d7;
--ring: #0071e3;

/* Cores específicas para gráficos */
--chart-blue: #0071e3;
--chart-green: #34c759;
--chart-orange: #ff9500;
--chart-red: #ff3b30;
--chart-purple: #af52de;
--chart-teal: #5ac8fa;
```

### Tipografia
```css
/* SF Pro Display (Apple) - usar Inter como alternativa web */
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;

/* Hierarquia */
--font-h1: 600 48px/1.1 'Inter';
--font-h2: 600 32px/1.2 'Inter';
--font-h3: 600 24px/1.3 'Inter';
--font-body: 400 16px/1.5 'Inter';
--font-small: 400 14px/1.5 'Inter';
--font-mono: 400 14px/1.5 'SF Mono', monospace;
```

### Componentes Visuais

#### 1. Cards (Estilo Apple)
```tsx
// Glassmorphism sutil
<div className="bg-white/80 backdrop-blur-xl rounded-2xl shadow-lg 
                border border-gray-200/50 p-6">
```

#### 2. Sidebar (Estilo Notion)
```tsx
// Lateral minimalista com ícones
<aside className="w-64 bg-gray-50/50 border-r border-gray-200 
                  h-screen fixed left-0 top-0">
```

#### 3. Botões
```tsx
// Primary - Apple style
<button className="bg-blue-600 hover:bg-blue-700 text-white 
                   rounded-full px-6 py-2 font-medium 
                   transition-all duration-200 
                   active:scale-95">

// Secondary - Ghost
<button className="bg-transparent hover:bg-gray-100 
                   text-gray-900 rounded-lg px-4 py-2">
```

---

## 📊 Dashboard - Especificação de Telas

### Tela 1: Upload de Dados

#### Layout
```
┌─────────────────────────────────────────────────────────────┐
│  🏠  TRI Dashboard                                          │
├──────────┬──────────────────────────────────────────────────┤
│          │                                                  │
│  📁      │     Arraste seu arquivo aqui                     │
│  Análises│                                                  │
│          │     ou clique para selecionar                    │
│  📊      │                                                  │
│  Dashboard│    [📄 Arquivo .csv ou .xlsx]                   │
│          │                                                  │
│  ⚙️      │     Formatos aceitos: CSV, XLSX                  │
│  Config  │     Tamanho máximo: 50MB                         │
│          │                                                  │
│          │──────────────────────────────────────────────────│
│          │                                                  │
│          │  Preview dos dados (primeiras 10 linhas):        │
│          │  ┌─────┬─────┬─────┬─────┬─────┬─────┐          │
│          │  │ Q1  │ Q2  │ Q3  │ Q4  │ Q5  │ ... │          │
│          │  │  1  │  0  │  1  │  1  │  0  │ ... │          │
│          │  │  0  │  1  │  1  │  0  │  1  │ ... │          │
│          │  └─────┴─────┴─────┴─────┴─────┴─────┘          │
│          │                                                  │
│          │  ✅ 100 candidatos × 80 itens detectados         │
│          │                                                  │
└──────────┴──────────────────────────────────────────────────┘
```

#### Funcionalidades
- Drag & drop com preview visual
- Validação automática (0/1, sem missings)
- Detecção automática de número de candidatos e itens
- Preview interativo dos dados

---

### Tela 2: Seleção do Tipo de Análise

#### Layout
```
┌─────────────────────────────────────────────────────────────┐
│  Configurar Análise                              [Cancelar] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Tipo de Exame                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   📝        │  │   🏥        │  │   📚        │         │
│  │   ENEM      │  │   ENAMED    │  │   SAEB      │         │
│  │             │  │             │  │             │         │
│  │ • 3PL       │  │ • Rasch 1PL │  │ • Rasch 1PL │         │
│  │ • EAP       │  │ • Angoff    │  │ • EAP       │         │
│  │ • Regressão │  │ • EAP       │  │ • Escalas   │         │
│  │   Linear    │  │             │  │   alternativ│         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  ⚙️ Configurações Avançadas                                  │
│                                                             │
│  Modelo: [Rasch ▼] [1PL ▼] [2PL ▼] [3PL ▼]                 │
│                                                             │
│  Método de Estimação: [EAP ●] [MAP ○] [ML ○]               │
│                                                             │
│  Transformação de Nota:                                     │
│  [ ] Linear (50 + 10×θ)                                     │
│  [x] Equipercentil                                          │
│  [ ] Personalizada                                          │
│                                                             │
│                    [Iniciar Análise →]                      │
└─────────────────────────────────────────────────────────────┘
```

#### Presets por Exame

**ENEM:**
- Modelo: 3PL
- Prior para c: Beta(4,16) → E[c] = 0.20
- Estimação: EAP
- Transformação: Regressão linear específica INEP
- Saída: Escala 0-1000

**ENAMED:**
- Modelo: Rasch 1PL
- Estimação: EAP
- Método Angoff: Sim (se houver valores)
- Transformação: Linear 0-100 ou equipercentil

**SAEB:**
- Modelo: Rasch 1PL
- Equalização: MultipleGroup (se múltiplos anos)
- Escalas: Alternativas por série

---

### Tela 3: Dashboard de Resultados

#### Layout
```
┌─────────────────────────────────────────────────────────────┐
│  Resultados da Análise - ENEM 2024               [⬇ Export]│
├──────────┬──────────────────────────────────────────────────┤
│          │  KPIs Principais                                 │
│          │  ┌──────────┐ ┌──────────┐ ┌──────────┐         │
│          │  │ Candidatos│ │  Itens   │ │   Modelo │         │
│          │  │   5.234   │ │    90    │ │   3PL    │         │
│          │  └──────────┘ └──────────┘ └──────────┘         │
│          │                                                  │
│          │  ─────────────────────────────────────────────   │
│          │                                                  │
│          │  📊 Distribuição de Notas                        │
│          │  ┌────────────────────────────────────────┐     │
│          │  │      📈 Histograma Interativo          │     │
│          │  │                                        │     │
│          │  │    Média: 520 | DP: 85 | Mediana: 515  │     │
│          │  └────────────────────────────────────────┘     │
│          │                                                  │
│          │  ─────────────────────────────────────────────   │
│          │                                                  │
│          │  📈 Curvas Características dos Itens (CCIs)      │
│          │  ┌────────────────────────────────────────┐     │
│          │  │     📉 Múltiplas curvas S-shaped       │     │
│          │  │                                        │     │
│          │  │  Selecionar: [Todas ▼] [Fáceis ▼]      │     │
│          │  └────────────────────────────────────────┘     │
│          │                                                  │
│          │  ─────────────────────────────────────────────   │
│          │                                                  │
│          │  📋 Tabela de Conversão - Estilo ENEM            │
│          │  ┌──────┬───────┬────────┬────────┬────────┐    │
│          │  │Acertos│  %    │ Nota   │  MIN   │  MAX   │    │
│          │  │  45   │ 50%   │  450   │  420   │  480   │    │
│          │  │  60   │ 67%   │  580   │  560   │  600   │    │
│          │  │  75   │ 83%   │  720   │  700   │  740   │    │
│          │  └──────┴───────┴────────┴────────┴────────┘    │
│          │                                                  │
│          │  ─────────────────────────────────────────────   │
│          │                                                  │
│          │  ⚠️ Itens para Revisão                           │
│          │  ┌────────────────────────────────────────┐     │
│          │  │ Q23: r_bisserial = 0.12 (baixo)        │     │
│          │  │ Q45: taxa acerto = 0.95 (muito fácil)  │     │
│          │  └────────────────────────────────────────┘     │
└──────────┴──────────────────────────────────────────────────┘
```

---

## 📈 Componentes de Gráficos

### 1. ICCChart - Curvas Características
```tsx
interface ICCChartProps {
  items: Array<{
    id: string;
    a: number;  // discriminação
    b: number;  // dificuldade
    c?: number; // acaso (3PL)
  }>;
  selectedItems?: string[];
  onItemSelect?: (id: string) => void;
}

// Features:
// - Hover mostra valores (a, b, c)
// - Zoom no eixo X (range de theta)
// - Toggle para mostrar/esconder itens
// - Cores por faixa de dificuldade
```

### 2. ScoreDistribution - Distribuição de Notas
```tsx
interface ScoreDistributionProps {
  scores: number[];
  binSize?: number;
  showPercentiles?: boolean;
  percentiles?: number[]; // [10, 25, 50, 75, 90]
}

// Features:
// - Histograma com curva de densidade
// - Linhas verticais nos percentis
// - Tooltip com contagem e %
// - Comparação com distribuição normal
```

### 3. ENEMConversionTable - Tabela de Conversão ENEM 2024

**Referência:** `docs/ENEM-2024-dificuldades.pdf`

Esta tabela é essencial para o ENEM, mostrando a conversão de acertos para nota na escala 0-1000 com intervalos de confiança.

```tsx
interface ENEMConversionTableProps {
  // Estrutura baseada no PDF oficial ENEM 2024
  data: Array<{
    acertos: number;           // Número de acertos (0-45 ou 0-90)
    percentual: number;        // % de acertos
    notaPadrao: number;        // Nota na escala 0-1000
    notaMin: number;           // Limite inferior (95% CI)
    notaMed: number;           // Nota média estimada
    notaMax: number;           // Limite superior (95% CI)
    amplitude: number;         // Max - Min (precisão da estimativa)
  }>;
  area: 'LC' | 'CH' | 'CN' | 'MT' | 'RED';  // Área do ENEM
  ano: number;  // 2024, 2023, etc.
}

// Features específicas ENEM:
// - Visualização tipo "thermometer" para cada faixa
// - Cores por área (LC=azul, CH=vermelho, CN=verde, MT=amarelo)
// - Filtro por faixa de acertos
// - Comparador ano vs ano (evolução da prova)
// - Exportação no formato oficial INEP
```

#### Estrutura Visual da Tabela (baseada no PDF)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ ENEM 2024 - TABELA DE CONVERSÃO DE NOTAS                                │
│ Área: Ciências Humanas (CH)                                             │
├─────────┬──────────┬────────────┬────────────┬────────────┬─────────────┤
│ Acertos │    %     │ Nota Mín   │ Nota Média │ Nota Máx   │ Amplitude   │
├─────────┼──────────┼────────────┼────────────┼────────────┼─────────────┤
│    0    │   0.0%   │    295.2   │   301.8    │   308.4    │    13.2     │
│    1    │   2.2%   │    312.5   │   318.4    │   324.3    │    11.8     │
│   ...   │   ...    │    ...     │    ...     │    ...     │    ...      │
│   22    │  48.9%   │    498.7   │   502.3    │   506.1    │     7.4     │
│   23    │  51.1%   │    504.2   │   508.5    │   512.8    │     8.6     │
│   ...   │   ...    │    ...     │    ...     │    ...     │    ...      │
│   45    │ 100.0%   │    815.6   │   821.3    │   827.0    │    11.4     │
└─────────┴──────────┴────────────┴────────────┴────────────┴─────────────┘

Legenda:
• Nota Mín/Máx: Intervalo de confiança de 95% (2×EP)
• Nota Média: Estimativa EAP (Expected A Posteriori)
• Amplitude: Indicador da precisão da estimativa
```

#### Visualizações Adicionais

**1. Gráfico de Conversão (Scatter + Error Bars):**
```tsx
<ENEMConversionChart
  data={conversionData}
  showConfidenceInterval={true}
  highlightRange={[20, 25]}  // Destacar faixa de acertos
/>
```

**2. Comparador de Anos:**
```tsx
<YearComparisonChart
  years={[2022, 2023, 2024]}
  metric="notaMed"
  acertos={23}  // Comparar nota para 23 acertos ao longo dos anos
/>
```

**3. Mapa de Calor por Área:**
```tsx
<AreaHeatmap
  areas={['LC', 'CH', 'CN', 'MT']}
  highlightDifficulty={true}  // Mostrar qual área é mais difícil
/>
```

#### Importância para o Frontend

A tabela ENEM-2024-dificuldades.pdf define:
1. **Estrutura de dados:** 5 colunas (acertos, %, min, média, max)
2. **Visualização:** Necessidade de mostrar intervalos de confiança
3. **Cálculos:** Amplitude = NotaMax - NotaMin (indicador de precisão)
4. **Contexto:** Cada área (LC, CH, CN, MT) tem sua própria tabela
5. **Validação:** Comparação com tabelas oficiais INEP

### 4. GenericConversionTable - Outros Exames

Para ENAMED, SAEB e outros:

```tsx
interface GenericConversionTableProps {
  data: Array<{
    acertos: number;
    percentual: number;
    nota: number;
    // Sem intervalo (apenas nota única) ou com desvio padrão
    desvioPadrao?: number;
  }>;
  examType: 'ENAMED' | 'SAEB' | 'CUSTOM';
  scale: '0-100' | '0-10' | '0-1000';
}
```

---

## 🔌 Integração com Backend R

### API Endpoints

```typescript
// lib/api.ts

interface AnalysisRequest {
  fileId: string;
  examType: 'ENEM' | 'ENAMED' | 'SAEB' | 'CUSTOM';
  model: 'Rasch' | '1PL' | '2PL' | '3PL';
  method: 'EAP' | 'MAP' | 'ML';
  transformation: 'linear' | 'equipercentil' | 'custom';
  customConfig?: {
    priors?: Record<string, number[]>;
    anchors?: Record<string, number>;
  };
}

interface AnalysisResponse {
  analysisId: string;
  status: 'processing' | 'completed' | 'error';
  progress?: number;
  results?: {
    parameters: ItemParameter[];
    scores: CandidateScore[];
    fitStatistics: FitStatistics;
    charts: ChartData;
  };
}

// Hooks
export const useAnalysis = () => {
  const startAnalysis = async (data: AnalysisRequest) => {
    const response = await fetch('/api/calibrar', {
      method: 'POST',
      body: JSON.stringify(data)
    });
    return response.json();
  };

  const getStatus = async (id: string) => {
    const response = await fetch(`/api/status/${id}`);
    return response.json();
  };

  return { startAnalysis, getStatus };
};
```

### Fluxo de Processamento

```
1. Frontend → POST /api/upload (arquivo)
2. Backend R → Validação e parsing
3. Frontend ← fileId
4. Frontend → POST /api/calibrar (fileId + config)
5. Backend R → Processamento (pode ser longo)
6. Frontend ← analysisId
7. Frontend → WebSocket /ws/status/{analysisId} (polling alternativo)
8. Backend R → Progress updates
9. Backend R → Resultados prontos
10. Frontend → GET /api/resultados/{analysisId}
11. Frontend → Renderização dos gráficos
```

---

## 📊 Cálculo da Tabela ENEM (Backend R)

**Baseado em:** `docs/ENEM-2024-dificuldades.pdf`

O ENEM usa uma metodologia específica para gerar a tabela de conversão com intervalos de confiança:

### Passos para Geração da Tabela

```r
# 1. Calibrar modelo 3PL com prior Beta(4,16) para c
mod_3pl <- mirt(dados, 1, itemtype="3PL",
                parprior=list(c=cbind(4, 16)))

# 2. Extrair parâmetros
pars <- coef(mod_3pl, IRTpars=TRUE, simplify=TRUE)$items

# 3. Gerar escores para cada número de acertos possível
gerar_tabela_enem <- function(mod, n_itens) {
  tabela <- data.frame()
  
  for(n_acertos in 0:n_itens) {
    # Estimar theta via EAP para n acertos
    # (simulação ou cálculo direto)
    theta_est <- estimar_theta_acertos(n_acertos, pars)
    
    # Calcular nota via regressão logística
    nota_media <- 300 + 200 * plogis(theta_est)
    
    # Calcular erro padrão
    se <- calcular_erro_padrao(theta_est, pars)
    
    # Intervalo de confiança 95%
    nota_min <- nota_media - 1.96 * se
    nota_max <- nota_media + 1.96 * se
    
    tabela <- rbind(tabela, data.frame(
      acertos = n_acertos,
      percentual = round(n_acertos/n_itens * 100, 1),
      notaMin = round(nota_min, 1),
      notaMed = round(nota_media, 1),
      notaMax = round(nota_max, 1),
      amplitude = round(nota_max - nota_min, 1)
    ))
  }
  
  return(tabela)
}
```

### Estrutura de Retorno da API

```typescript
// GET /api/tabela-conversao/{analysisId}
{
  "exame": "ENEM",
  "ano": 2024,
  "area": "CH",
  "nItens": 45,
  "tabela": [
    {
      "acertos": 0,
      "percentual": 0.0,
      "notaMin": 295.2,
      "notaMed": 301.8,
      "notaMax": 308.4,
      "amplitude": 13.2
    },
    // ... todas as linhas até nItens
  ],
  "metadata": {
    "modelo": "3PL",
    "metodo": "EAP",
    "intervaloConfianca": 0.95
  }
}
```

### Visualização no Frontend

```tsx
// Componente específico ENEM
<ENEMTabelaConversao 
  data={tabelaData}
  showHeatmap={true}        // Mapa de calor por faixa
  highlightAcertos={23}     // Destacar 23 acertos
  compareWithPrevious={2023} // Comparar com ano anterior
/>
```

---

## 📤 Exportação de Relatórios

### Formatos Suportados

#### Excel (.xlsx)
```typescript
// Abas:
// 1. Resumo Executivo (KPIs)
// 2. Notas Candidatos (ID, Theta, Nota, Percentil)
// 3. Parâmetros Itens (ID, a, b, c, INFIT, OUTFIT)
// 4. Tabela Conversão (Acertos → Nota)
// 5. Estatísticas TCT (Taxa acerto, correlação)
// 6. Itens Revisar (Flags de qualidade)
```

#### PDF
```typescript
// Seções:
// 1. Capa (título, data, resumo)
// 2. Metodologia (modelo, parâmetros)
// 3. Resultados gerais (texto + tabelas)
// 4. Gráficos (ICC, distribuição)
// 5. Anexos (tabela completa)
```

---

## 📚 Presets de Referência Históricos (ENEM 2009-2023)

**Baseado em:** `docs/TRI ENEM DE 2009 A 2023 MIN MED E MAX.xlsx`

Arquivo Excel com tabelas de conversão oficiais do ENEM de 2009 a 2023, todas as áreas (CH, CN, LC, MT).

### Estrutura dos Dados

```json
// config/presets_enem_historico.json
{
  "2023": {
    "ano": 2023,
    "exame": "ENEM",
    "modelo": "3PL",
    "metodo": "EAP",
    "escala": {"min": 0, "max": 1000},
    "areas": {
      "CH": {
        "n_itens": 45,
        "tabela": [
          {"acertos": 0, "notaMin": 300.0, "notaMed": 305.1, "notaMax": 310.2},
          {"acertos": 1, "notaMin": 310.5, "notaMed": 318.3, "notaMax": 326.1},
          // ... até 45 acertos
        ],
        "stats": {
          "nota_min_geral": 300.0,
          "nota_max_geral": 839.2,
          "media_geral": 562.3
        }
      },
      "CN": { ... },
      "LC": { ... },
      "MT": { ... }
    }
  },
  "2022": { ... },
  "2021": { ... },
  // ... até 2009
}
```

### Presets Disponíveis no Frontend

```typescript
// stores/referencePresets.ts

// Anos disponíveis
export const ENEM_YEARS = [2009, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023];

// Áreas do ENEM
export const ENEM_AREAS = [
  { code: 'CH', name: 'Ciências Humanas', color: '#FF3B30' },
  { code: 'CN', name: 'Ciências da Natureza', color: '#34C759' },
  { code: 'LC', name: 'Linguagens e Códigos', color: '#0071E3' },
  { code: 'MT', name: 'Matemática', color: '#FF9500' }
];

// Hook para acessar presets
export const useENEMPresets = () => {
  const [selectedYear, setSelectedYear] = useState(2023);
  const [selectedArea, setSelectedArea] = useState('CH');
  
  const currentTable = useMemo(() => {
    return loadPreset('ENEM', selectedYear, selectedArea);
  }, [selectedYear, selectedArea]);
  
  const compareYears = (year1: number, year2: number) => {
    return comparePresets('ENEM', year1, year2, selectedArea);
  };
  
  return { selectedYear, selectedArea, currentTable, compareYears };
};
```

### Componente de Seleção de Preset

```tsx
// components/presets/PresetSelector.tsx

<PresetSelector
  examType="ENEM"
  availableYears={[2019, 2020, 2021, 2022, 2023]}
  defaultYear={2023}
  areas={['CH', 'CN', 'LC', 'MT']}
  onChange={(config) => {
    // config = { year: 2023, area: 'CH', table: {...} }
    setReferenceTable(config.table);
  }}
  showComparison={true}  // Mostrar vs ano anterior
/>
```

### Uso em Análises

**Cenário 1: Simulado baseado no ENEM 2023**
```tsx
// Usuário seleciona preset
const preset = await loadPreset('ENEM', 2023, 'CH');

// Sistema calcula notas dos candidatos usando essa tabela
const notas = candidatos.map(c => {
  const linha = preset.tabela.find(t => t.acertos === c.acertos);
  return {
    ...c,
    nota: linha.notaMed,
    notaMin: linha.notaMin,
    notaMax: linha.notaMax
  };
});
```

**Cenário 2: Comparação entre anos**
```tsx
// Comparar desempenho 2022 vs 2023
const table2022 = loadPreset('ENEM', 2022, 'CH');
const table2023 = loadPreset('ENEM', 2023, 'CH');

// Análise: Para 25 acertos, qual a diferença?
const diff = table2023.tabela[25].notaMed - table2022.tabela[25].notaMed;
// Resultado: "2023 foi X pontos mais difícil/fácil"
```

### Dashboard de Presets

```
┌─────────────────────────────────────────────────────────────┐
│  📚 Presets de Referência - ENEM                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Selecionar Ano: [2023 ▼]  Área: [CH ▼]        [Comparar]  │
│                                                             │
│  📊 Tabela de Conversão - ENEM 2023 - Ciências Humanas     │
│  ┌───────┬────────┬────────┬────────┬─────────────────────┐│
│  │Acertos│ Nota   │  Min   │  Máx   │ vs 2022             ││
│  ├───────┼────────┼────────┼────────┼─────────────────────┤│
│  │   20  │ 498.5  │ 492.1  │ 504.9  │  +5.3  🟢          ││
│  │   25  │ 542.8  │ 537.2  │ 548.4  │  +2.1  🟢          ││
│  │   30  │ 601.2  │ 595.8  │ 606.6  │  -3.4  🔴          ││
│  └───────┴────────┴────────┴────────┴─────────────────────┘│
│                                                             │
│  📈 Evolução da Dificuldade (2020-2023)                     │
│  [Gráfico de linhas mostrando nota média ao longo dos anos] │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Carregamento Otimizado

```typescript
// Estratégia de carregamento
const loadPresetStrategy = {
  // 1. Carregar índice (metadados) - pequeno
  loadIndex: async () => {
    const response = await fetch('/config/presets_enem_index.json');
    return response.json(); // { anos: [...], areas: [...] }
  },
  
  // 2. Carregar preset específico sob demanda
  loadPreset: async (year: number, area: string) => {
    const response = await fetch(`/config/presets_enem_historico.json`);
    const allPresets = await response.json();
    return allPresets[year].areas[area];
  },
  
  // 3. Cache no localStorage
  cachePreset: (year, area, data) => {
    localStorage.setItem(`preset_enem_${year}_${area}`, JSON.stringify(data));
  }
};
```

---

## 📈 Análise de Tendências e Previsão

**Dados disponíveis:** 2009, 2015-2023 (histórico) + 2024 (atual)

**Aguardando:** 2025 (quando sair, upload simples)

### Botão Principal: "🔮 Análise de Tendências"

```
┌─────────────────────────────────────────────────────────────┐
│  📈 Análise de Tendências ENEM                 [🔙 Voltar]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🎯 PROJEÇÃO 2025 (Baseada em Tendências Históricas)       │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Selecionar Área: [CN ▼]                                ││
│  │                                                         ││
│  │ 📊 Dados Históricos: 2009, 2015-2024 (11 anos)        ││
│  │ 📁 Dados 2024: ✓ Carregado                            ││
│  │ 📁 Dados 2025: ⏳ Aguardando publicação INEP          ││
│  │                                                         ││
│  │ [🔮 Gerar Projeção 2025]  [📊 Analisar Tendências]     ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  📉 RESULTADOS DA ANÁLISE                                   │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Tendência Últimos 5 Anos (2020-2024):                  ││
│  │ • Dificuldade Geral: 🟡 ESTÁVEL (-2.3 pts média)       ││
│  │ • Nota Média: 587.4 → 594.2 (+6.8 pts)                 ││
│  │ • Variação por Faixa: Maior em 25-35 acertos           ││
│  │                                                         ││
│  │ 🎯 PROJEÇÃO PARA 2025:                                  ││
│  │ • Nota Média Estimada: 598.5 (±15 pts)                 ││
│  │ • Intervalo de Confiança: 583.5 - 613.5                ││
│  │ • Probabilidade de Manter Padrão: 78%                  ││
│  │                                                         ││
│  │ [📥 Baixar Projeção 2025]  [📊 Ver Gráfico Completo]   ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  📊 GRÁFICOS INTERATIVOS                                    │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  [Evolução da Nota Média] [Dispersão por Ano]          ││
│  │  [Comparação por Faixa]   [Previsão 2025]              ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Funcionalidades da Análise

#### 1. **Comparador de Anos** (Botão "📊 Analisar Tendências")

```tsx
<YearComparisonAnalyzer
  baseYear={2024}
  compareYears={[2020, 2021, 2022, 2023]}
  area="CN"
  metrics={['notaMed', 'notaMin', 'notaMax']}
  acertosRange={[20, 30]}  // Foco na faixa de 20-30 acertos
/>
```

**Saída:**
```
Comparação: 2024 vs Média 2020-2023
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Acertos 20:  498.2 → 502.1  (+3.9)  🟢
Acertos 25:  542.8 → 545.3  (+2.5)  🟢
Acertos 30:  601.2 → 598.4  (-2.8)  🔴
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Conclusão: Prova 2024 ligeiramente mais fácil na base,
           mais difícil no topo (discriminação maior)
```

#### 2. **Detector de Tendências**

```typescript
interface TrendAnalysis {
  period: string;           // "2020-2024"
  slope: number;           // Inclinação da regressão
  r2: number;              // Coeficiente de determinação
  prediction2025: {
    estimated: number;     // Nota média projetada
    confidenceInterval: [number, number];
    probability: number;   // Probabilidade da previsão
  };
  alerts: string[];        // Alertas de mudanças significativas
}

// Algoritmo de detecção
const analyzeTrends = (historicalData: YearData[]): TrendAnalysis => {
  // 1. Regressão linear por faixa de acertos
  // 2. Cálculo de drift (mudança média anual)
  // 3. Previsão com intervalo de confiança
  // 4. Detecção de outliers (anos atípicos)
};
```

#### 3. **Visualizações de Tendência**

**Gráfico 1: Evolução Temporal**
```
Nota Média (25 acertos)
800 ┤                                    ╭──── 2024
    │                              ╭────╯
750 ┤                        ╭────╯
    │                  ╭────╯
700 ┤            ╭────╯
    │      ╭────╯
650 ┤──────╯
    └────┬────┬────┬────┬────┬────┬────┬
        2017 2018 2019 2020 2021 2022 2023 2024

Linha tracejada: Projeção 2025
Área sombreada: Intervalo de confiança (95%)
```

**Gráfico 2: Heatmap de Mudanças**
```
Mudança vs Ano Anterior (em pontos)
        CH      CN      LC      MT
2020    +2.1    -1.3    +5.2    +8.1
2021    -0.5    +1.2    -2.1    -3.4
2022    +1.8    +2.5    +0.8    +1.2
2023    -1.2    -0.8    +1.5    -2.1
2024    +0.3    +1.1    -0.5    +0.8

🟢 Verde: +5 pts (mais fácil)
🟡 Amarelo: ±2 pts (estável)
🔴 Vermelho: -5 pts (mais difícil)
```

#### 4. **Projeção 2025**

**Quando clicar em "🔮 Gerar Projeção 2025":**

```typescript
const generate2025Projection = async (area: string) => {
  // 1. Carregar dados históricos
  const historical = await loadHistoricalData(2009, 2024, area);
  
  // 2. Aplicar modelo de séries temporais
  const model = fitTimeSeriesModel(historical, {
    method: 'linear',      // ou 'exponential', 'arima'
    seasonality: false,    // ENEM não tem sazonalidade
    confidence: 0.95
  });
  
  // 3. Gerar projeção
  const projection = model.predict(2025);
  
  // 4. Calcular intervalos de confiança
  const ci = calculateConfidenceInterval(projection, historical.variance);
  
  return {
    projectedTable: generateFullTable(projection),
    confidenceInterval: ci,
    reliability: calculateReliability(historical),
    recommendation: generateRecommendation(projection, historical)
  };
};
```

**Resultado da Projeção:**
```json
{
  "ano": 2025,
  "tipo": "PROJEÇÃO",
  "baseado_em": "2009-2024",
  "area": "CH",
  "tabela_projetada": [
    {"acertos": 0, "notaMin": 302.1, "notaMed": 308.5, "notaMax": 314.9},
    // ... todas as linhas
  ],
  "intervalo_confianca": {
    "nivel": 0.95,
    "nota_media_min": 568.2,
    "nota_media_max": 614.8
  },
  "confiabilidade": 0.78,
  "recomendacao": "Usar com cautela. Validar quando dados oficiais 2025 saírem."
}
```

#### 5. **Upload de Dados 2025 (Quando Sair)**

**Botão de Ação:** "⬆️ Upload Tabela 2025" (aparece quando próximo da data de publicação)

```
STATUS ATUAL:
┌─────────────────────────────────────────┐
│  📅 Dados ENEM 2025                     │
│                                         │
│  Status: ⏳ Aguardando INEP             │
│  Previsão: Novembro/Dezembro 2025       │
│                                         │
│  Histórico de Publicação:               │
│  • 2024: Publicado em 17/01/2025        │
│  • 2023: Publicado em 15/01/2024        │
│  • 2022: Publicado em 20/01/2023        │
│                                         │
│  🔔 [Ativar Notificação]               │
│     Avise-me quando sair                │
└─────────────────────────────────────────┘

QUANDO SAIR - FLUXO DE UPLOAD:
┌─────────────────────────────────────────┐
│  ⬆️ Nova Tabela ENEM 2025 Detectada!   │
│                                         │
│  Arraste ou selecione:                  │
│  📁 ENEM-2025-dificuldades.pdf          │
│                                         │
│  ⚡ Processamento Automático:           │
│  ┌─────────────────────────────────────┐│
│  │ ✅ Parse do PDF                    ││
│  │ ⏳ Validar estrutura               ││
│  │ ⏳ Comparar com projeção 2025      ││
│  │ ⏳ Calcular acurácia da previsão   ││
│  │ ⏳ Atualizar banco de dados        ││
│  └─────────────────────────────────────┘│
│                                         │
│  [🚀 Iniciar Upload e Análise]          │
└─────────────────────────────────────────┘

RESULTADO DO UPLOAD:
┌─────────────────────────────────────────┐
│  ✅ ENEM 2025 Incorporado com Sucesso!  │
│                                         │
│  📊 Análise de Acurácia da Projeção:    │
│  • Acurácia Geral: 89.3%                │
│  • Desvio Médio: 4.2 pontos             │
│  • Faixa Mais Acertada: 25-30 acertos   │
│  • Faixa Menos Acertada: 0-5 acertos    │
│                                         │
│  📈 Comparativo Projeção vs Real:       │
│  ┌──────────┬──────────┬──────────┐    │
│  │ Acertos  │ Projeção │   Real   │    │
│  ├──────────┼──────────┼──────────┤    │
│  │    20    │   498.5  │   502.1  │ 🟢 │
│  │    25    │   542.8  │   540.3  │ 🟢 │
│  │    30    │   601.2  │   595.8  │ 🟡 │
│  └──────────┴──────────┴──────────┘    │
│                                         │
│  🎯 Ações Recomendadas:                 │
│  • [📊 Ver Análise Completa]            │
│  • [📥 Baixar Relatório PDF]            │
│  • [🔮 Atualizar Projeção 2026]         │
└─────────────────────────────────────────┘
```

**Processo Técnico:**

```typescript
// Quando usuário fizer upload de 2025
const process2025Upload = async (file: File) => {
  // 1. Parse do PDF
  const extractedData = await parsePDF(file);
  
  // 2. Validar estrutura
  const validation = validateTableStructure(extractedData, 'ENEM');
  if (!validation.valid) {
    showError(validation.errors);
    return;
  }
  
  // 3. Carregar projeção 2025 (se existir)
  const projection2025 = await loadProjection(2025);
  
  // 4. Calcular acurácia
  const accuracy = calculateProjectionAccuracy(
    projection2025.tabela,
    extractedData.tabela
  );
  
  // 5. Salvar no banco
  await saveReferenceTable({
    exam: 'ENEM',
    year: 2025,
    data: extractedData,
    metadata: {
      uploadDate: new Date(),
      sourceFile: file.name,
      projectionAccuracy: accuracy,
      validated: true
    }
  });
  
  // 6. Gerar relatório
  return generateUploadReport(extractedData, projection2025, accuracy);
};
```

### Alertas Automáticos

```typescript
// Detectar anos atípicos
const alerts = [
  {
    type: 'WARNING',
    message: '2020 apresenta variação atípica (pandemia)',
    recommendation: 'Considerar excluir 2020 da análise de tendência'
  },
  {
    type: 'INFO', 
    message: 'Tendência de estabilidade nos últimos 3 anos',
    confidence: 0.85
  },
  {
    type: 'ALERT',
    message: 'Projeção 2025 tem baixa confiabilidade (dados insuficientes)',
    action: 'Aguardar dados oficiais ou usar 2024 como base'
  }
];
```

### Botão Flutuante (Quick Action)

```tsx
// Botão sempre visível no canto inferior direito
<FloatingActionButton
  icon="🔮"
  label="Análise de Tendências"
  onClick={() => router.push('/analise-tendencias')}
  pulse={hasNewData2024}  // Pulsar quando 2024 foi carregado
/>
```

---

## 🗂️ Versionamento de Tabelas de Referência

**Problema:** Tabelas ENEM mudam a cada ano (ENEM-2024-dificuldades.pdf, ENEM-2025, etc.)

**Solução:** Sistema de versionamento com banco de dados

### Estratégia de Gestão

#### 1. Estrutura de Dados (PostgreSQL/SQLite)

```sql
-- Tabela principal de referências
CREATE TABLE tabelas_referencia (
  id SERIAL PRIMARY KEY,
  exam_type VARCHAR(20) NOT NULL,        -- 'ENEM', 'ENAMED', 'SAEB'
  year INTEGER NOT NULL,                  -- 2024, 2025, etc.
  area VARCHAR(10),                       -- 'LC', 'CH', 'CN', 'MT' (ENEM)
  n_itens INTEGER NOT NULL,
  file_name VARCHAR(255),                 -- 'ENEM-2024-dificuldades.pdf'
  file_hash VARCHAR(64),                  -- SHA-256 para integridade
  created_at TIMESTAMP DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,         -- Tabela atual em uso
  metadata JSONB                          -- Informações extras
);

-- Dados da tabela (linhas)
CREATE TABLE tabela_linhas (
  id SERIAL PRIMARY KEY,
  tabela_id INTEGER REFERENCES tabelas_referencia(id),
  acertos INTEGER NOT NULL,
  percentual DECIMAL(5,2),
  nota_min DECIMAL(6,2),
  nota_med DECIMAL(6,2),
  nota_max DECIMAL(6,2),
  amplitude DECIMAL(6,2),
  UNIQUE(tabela_id, acertos)
);

-- Histórico de alterações
CREATE TABLE tabela_audit (
  id SERIAL PRIMARY KEY,
  tabela_id INTEGER REFERENCES tabelas_referencia(id),
  action VARCHAR(20),                     -- 'INSERT', 'UPDATE', 'DELETE'
  changed_by VARCHAR(100),
  changed_at TIMESTAMP DEFAULT NOW(),
  old_values JSONB,
  new_values JSONB
);
```

#### 2. Upload de Nova Tabela de Referência

**Fluxo no Frontend:**

```tsx
// Componente de upload de tabela de referência
<ReferenceTableUpload
  examType="ENEM"
  year={2025}
  area="CH"
  onUpload={async (file, metadata) => {
    // 1. Parse do PDF/Excel
    const parsedData = await parseReferenceTable(file);
    
    // 2. Validação contra tabela anterior
    const diff = await compareWithPrevious({
      examType: 'ENEM',
      year: 2024,
      area: 'CH'
    });
    
    // 3. Preview das diferenças
    showDiffModal({
      message: `Diferenças detectadas vs 2024:`,
      changes: diff,
      onConfirm: () => saveNewTable(parsedData)
    });
  }}
/>
```

#### 3. Sistema de Versionamento

```typescript
// stores/referenceTableStore.ts
interface ReferenceTableState {
  // Tabelas disponíveis
  availableTables: {
    ENEM: { 2022: TableMeta[], 2023: TableMeta[], 2024: TableMeta[] },
    ENAMED: { 2023: TableMeta[], 2024: TableMeta[] },
    SAEB: { 2022: TableMeta[], 2023: TableMeta[], 2024: TableMeta[] }
  };
  
  // Tabela ativa para comparação
  activeTable: {
    exam: string;
    year: number;
    area?: string;
  };
  
  // Histórico de comparações
  comparisonHistory: Array<{
    date: string;
    tables: [TableMeta, TableMeta];
    differences: TableDiff[];
  }>;
}

// Ações
const useReferenceTableStore = create<ReferenceTableState>((set, get) => ({
  // Alternar entre anos para comparação
  compareYears: (exam, year1, year2) => {
    const table1 = fetchTable(exam, year1);
    const table2 = fetchTable(exam, year2);
    return calculateDifferences(table1, table2);
  },
  
  // Detectar drift (mudanças significativas)
  detectSignificantChanges: (newTable, oldTable) => {
    const threshold = 20; // pontos na escala ENEM
    return newTable.filter((row, i) => 
      Math.abs(row.notaMed - oldTable[i].notaMed) > threshold
    );
  }
}));
```

#### 4. Interface de Gestão (Admin)

```
┌─────────────────────────────────────────────────────────────┐
│  📚 Gestão de Tabelas de Referência              [+ Upload] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🏛️ Tabelas Disponíveis                                     │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ ENEM                                                    ││
│  │ ├── 2025 (novo)          [⚠️ Revisar] [✓ Ativar]       ││
│  │ ├── 2024 (ativo)         [👁️ Visualizar] [📊 Análise]  ││
│  │ ├── 2023                 [👁️ Visualizar]               ││
│  │ └── 2022                 [👁️ Visualizar]               ││
│  │                                                         ││
│  │ ENAMED                                                  ││
│  │ └── 2024 (ativo)                                      ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  📊 Comparação de Versões                                   │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Comparar: [ENEM 2024 ▼] vs [ENEM 2025 ▼]   [Analisar]  ││
│  │                                                         ││
│  │ ⚠️ Diferenças Significativas:                           ││
│  │ • 20-25 acertos: +15 pontos média (prova mais fácil)   ││
│  │ • 35-40 acertos: -8 pontos média                       ││
│  │                                                         ││
│  │ [📈 Ver Gráfico Comparativo] [📄 Relatório]             ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  📋 Log de Alterações                                       │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Data       Usuário       Ação              Tabela       ││
│  │ 14/01/25   admin@tri     Upload ENEM 2025  CH, CN      ││
│  │ 10/01/25   admin@tri     Ativar ENEM 2024  Todas       ││
│  │ 05/12/24   admin@tri     Upload ENEM 2024  LC, MT      ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

#### 5. Detecção de Mudanças Significativas (Drift)

```typescript
// Detecção automática de mudanças na prova
interface TableDriftDetection {
  detect: (oldTable: ENEMTable, newTable: ENEMTable) => DriftResult;
}

const detectTableDrift = (oldTable, newTable): DriftResult => {
  const diffs = [];
  
  for (let i = 0; i < oldTable.length; i++) {
    const oldRow = oldTable[i];
    const newRow = newTable[i];
    
    const diff = {
      acertos: i,
      oldNota: oldRow.notaMed,
      newNota: newRow.notaMed,
      delta: newRow.notaMed - oldRow.notaMed,
      percentChange: ((newRow.notaMed - oldRow.notaMed) / oldRow.notaMed) * 100
    };
    
    // Thresholds para alerta
    if (Math.abs(diff.delta) > 20) {
      diff.severity = 'HIGH';
      diffs.push(diff);
    } else if (Math.abs(diff.delta) > 10) {
      diff.severity = 'MEDIUM';
      diffs.push(diff);
    }
  }
  
  return {
    hasSignificantChanges: diffs.length > 0,
    changes: diffs,
    recommendation: diffs.length > 5 
      ? 'Prova significativamente diferente. Considerar recalibração completa.'
      : 'Mudanças pontuais. Ajuste na curva de notas pode ser suficiente.'
  };
};
```

#### 6. Backup e Auditoria

```typescript
// Backup automático antes de atualizar
const backupCurrentTable = async (examType, year) => {
  const currentTable = await fetchTable(examType, year);
  
  await db.query(`
    INSERT INTO tabelas_backup 
    SELECT * FROM tabelas_referencia 
    WHERE exam_type = $1 AND year = $2
  `, [examType, year]);
  
  // Log da ação
  await auditLog.record({
    action: 'BACKUP_CREATED',
    table: `${examType}_${year}`,
    timestamp: new Date(),
    user: currentUser.id
  });
};
```

#### 7. API Endpoints para Versionamento

```typescript
// GET /api/tabelas-referencia
// Lista todas as tabelas disponíveis
{
  "ENEM": {
    "2025": { "areas": ["LC", "CH", "CN", "MT"], "status": "draft" },
    "2024": { "areas": ["LC", "CH", "CN", "MT"], "status": "active" },
    "2023": { "areas": ["LC", "CH", "CN", "MT"], "status": "archived" }
  }
}

// GET /api/tabelas-referencia/ENEM/2024/CH
// Retorna dados específicos da tabela

// POST /api/tabelas-referencia
// Upload de nova tabela
{
  "examType": "ENEM",
  "year": 2025,
  "area": "CH",
  "data": [...],
  "validateAgainst": "2024"  // Comparar com ano anterior
}

// GET /api/tabelas-referencia/compare?exam=ENEM&year1=2024&year2=2025
// Comparação entre anos
{
  "differences": [...],
  "significantChanges": true,
  "recommendation": "..."
}
```

---

## 🎨 Animações e Interações (Framer Motion)

```tsx
// Transição de páginas
const pageVariants = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -20 }
};

// Cards hover
const cardHover = {
  rest: { scale: 1 },
  hover: { scale: 1.02, transition: { duration: 0.2 } }
};

// Upload success
const uploadSuccess = {
  hidden: { scale: 0.8, opacity: 0 },
  visible: { 
    scale: 1, 
    opacity: 1,
    transition: { type: "spring", stiffness: 200 }
  }
};
```

---

## 🚀 Roadmap de Implementação

### Fase 1: MVP (2 semanas)
- [ ] Setup Next.js + Tailwind + shadcn
- [ ] Upload de arquivos (CSV/Excel)
- [ ] Seleção ENEM/ENAMED/SAEB
- [ ] Dashboard básico com 3 KPIs
- [ ] Tabela de resultados

### Fase 2: Visualizações (2 semanas)
- [ ] Gráfico de distribuição de notas
- [ ] CCIs interativas
- [ ] Tabela conversão estilo ENEM
- [ ] Exportação Excel

### Fase 3: Avançado (2 semanas)
- [ ] Exportação PDF
- [ ] Animações Framer Motion
- [ ] Modo escuro
- [ ] Responsivo mobile

### Fase 4: Integração (1 semana)
- [ ] Conexão com API R
- [ ] WebSocket para progresso
- [ ] Cache de análises
- [ ] Deploy (Vercel)

---

## 📝 Comandos para Iniciar

```bash
# 1. Criar projeto Next.js
npx create-next-app@latest tri-dashboard --typescript --tailwind --app

# 2. Instalar shadcn
npx shadcn-ui@latest init

# 3. Instalar componentes
npx shadcn-ui@latest add button card dialog tabs table

# 4. Instalar dependências
npm install recharts framer-motion zustand @tanstack/react-query
npm install react-dropzone papaparse xlsx jspdf html2canvas

# 5. Instalar tipos
npm install -D @types/papaparse @types/xlsx
```

---

## 📚 Recursos de Referência

### Design
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Notion Design System](https://www.notion.so/design)
- [shadcn/ui Components](https://ui.shadcn.com)

### Gráficos
- [Recharts Documentation](https://recharts.org)
- [D3.js Gallery](https://observablehq.com/@d3/gallery)

### Dados
- [Papa Parse](https://www.papaparse.com)
- [SheetJS/xlsx](https://sheetjs.com)

---

**Nota:** Este documento serve como especificação técnica para implementação do frontend. O backend em R (API Plumber) já está desenvolvido e deve ser adaptado para expor os endpoints necessários.
