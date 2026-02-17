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

### 3. ConversionTable - Tabela ENEM
```tsx
interface ConversionTableProps {
  data: Array<{
    acertos: number;
    percentual: number;
    nota: number;
    notaMin: number;
    notaMax: number;
  }>;
  examType: 'ENEM' | 'ENAMED' | 'SAEB';
}

// Features:
// - Ordenação por colunas
// - Filtro por faixa de notas
// - Destaque para mediana
// - Exportação CSV
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
