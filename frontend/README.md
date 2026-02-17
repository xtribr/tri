# TRI Analytics - Frontend

Sistema de análise psicométrica usando Teoria de Resposta ao Item (TRI).

## Tecnologias

- **Next.js 16** (App Router)
- **React 19**
- **TypeScript**
- **Tailwind CSS v4**
- **shadcn/ui**
- **Recharts** (visualizações)
- **Zustand** (state management)
- **Framer Motion** (animações)

## Design System

Inspirado em **Notion + Apple**:
- Glassmorphism com blur
- Cores: Azul Apple (#0071E3)
- Tipografia: Inter
- Bordas arredondadas: 8-20px
- Sombras sutis

## Estrutura

```
src/
├── app/                 # Next.js App Router
│   ├── page.tsx         # Redirect para /upload
│   ├── layout.tsx       # Root layout
│   ├── upload/          # Página de upload
│   ├── analysis/        # Configuração de análise
│   └── dashboard/       # Dashboard com gráficos
├── components/
│   ├── layout/          # Sidebar, MainLayout
│   ├── upload/          # FileUpload
│   ├── charts/          # ICCCurve, ScoreDistribution
│   └── ui/              # shadcn/ui components
├── lib/
│   ├── api/             # Cliente API (axios)
│   └── stores/          # Zustand stores
└── types/               # TypeScript types
```

## Scripts

```bash
npm run dev      # Desenvolvimento
npm run build    # Build produção
npm run start    # Servir build
```

## API Integration

O frontend se conecta à API R Plumber em `http://localhost:8000`:

- `POST /calibrar` - Calibração de itens
- `POST /scoring/estimar` - Estimativa de escores
- `POST /cat/sessao/*` - CAT endpoints

## Funcionalidades

1. **Upload**: CSV com respostas binárias (0/1)
2. **Configuração**: Presets ENAMED, ENEM, SAEB
3. **Calibração**: Modelos Rasch, 2PL, 3PL, 3PL_ENEM
4. **Dashboard**:
   - Curvas ICC
   - Distribuição de habilidade
   - Estatísticas de ajuste
   - Tabela de itens

## ⚠️ Avisos

**Este é um MVP (Minimum Viable Product)**. Requer revisão por especialistas em psicometria para garantir:
- Corretude matemática das fórmulas TRI
- Validação estatística dos resultados
- Conformidade com especificações INEP

## Requisitos Backend

Para funcionalidade completa, inicie a API R:

```bash
cd /Volumes/Kingston\ 1/apps/TRI/R
Rscript api/plumber_v2.R
```

## Licença

Uso interno - Projeto TRI ENAMED/ENARE 2026
