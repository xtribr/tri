'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  BarChart,
  Bar,
} from 'recharts';
import { 
  TrendingUp, 
  TrendingDown, 
  AlertTriangle, 
  School, 
  MapPin,
  Lightbulb,
  Download
} from 'lucide-react';

// Dados mockados para demonstração
const MOCK_COMPARATIVO_ANOS = [
  { ano: 2019, CH: 502.3, CN: 489.1, LC: 515.2, MT: 510.8, n_candidatos: 5095000 },
  { ano: 2020, CH: 508.5, CN: 495.2, LC: 520.1, MT: 518.3, n_candidatos: 5783000 },
  { ano: 2021, CH: 514.2, CN: 498.7, LC: 522.5, MT: 523.1, n_candidatos: 3386000 },
  { ano: 2022, CH: 509.8, CN: 491.3, LC: 518.9, MT: 519.4, n_candidatos: 3476000 },
  { ano: 2023, CH: 506.2, CN: 488.5, LC: 521.3, MT: 524.7, n_candidatos: 3954000 },
  { ano: 2024, CH: 511.0, CN: 493.9, LC: 524.5, MT: 527.0, n_candidatos: 4333000 },
];

const MOCK_INSIGHTS = {
  tendencias: [
    {
      area: 'MT',
      tipo: 'alta',
      mensagem: 'Tendência de alta consistente desde 2019 (+3.2%)',
      impacto: 'MÉDIO',
    },
    {
      area: 'CN',
      tipo: 'queda',
      mensagem: 'Recuperação em 2024 após queda em 2022-2023',
      impacto: 'MÉDIO',
    },
  ],
  alertas: [
    {
      area: 'CN',
      tipo: 'desigualdade',
      mensagem: 'Alta variabilidade nas notas (DP=79.1)',
      severidade: 'ALTA',
    },
  ],
  recomendacoes: [
    {
      prioridade: 1,
      categoria: 'Ação Imediata',
      titulo: 'Investigar queda em Ciências da Natureza',
      descricao: 'A área CN apresenta as menores médias e maior desigualdade.',
      acoes: ['Analisar itens por conteúdo', 'Identificar gargalos'],
    },
  ],
};

const MOCK_ESCOLAS_TIPO = [
  { tipo: 'Federal', media: 598.5, n_escolas: 892, n_alunos: 245000 },
  { tipo: 'Estadual', media: 498.3, n_escolas: 15234, n_alunos: 4850000 },
  { tipo: 'Municipal', media: 476.2, n_escolas: 8934, n_alunos: 1650000 },
  { tipo: 'Privada', media: 585.7, n_escolas: 4521, n_alunos: 980000 },
];

const MOCK_UFS = [
  { uf: 'DF', media: 542.3, n_alunos: 85000 },
  { uf: 'SP', media: 538.7, n_alunos: 890000 },
  { uf: 'RJ', media: 521.4, n_alunos: 320000 },
  { uf: 'MG', media: 518.9, n_alunos: 420000 },
  { uf: 'RS', media: 515.2, n_alunos: 210000 },
];

export default function ComparativoPage() {
  const [areaSelecionada, setAreaSelecionada] = useState('MT');
  const [anoBase, setAnoBase] = useState('2023');
  const [anoComparacao, setAnoComparacao] = useState('2024');

  const areas = ['CH', 'CN', 'LC', 'MT'];
  const anos = [2019, 2020, 2021, 2022, 2023, 2024];

  const dadosAnoBase = MOCK_COMPARATIVO_ANOS.find(d => d.ano === parseInt(anoBase));
  const dadosAnoComp = MOCK_COMPARATIVO_ANOS.find(d => d.ano === parseInt(anoComparacao));
  
  const variacao = dadosAnoBase && dadosAnoComp ? {
    media: ((dadosAnoComp[areaSelecionada as keyof typeof dadosAnoComp] as number) - 
            (dadosAnoBase[areaSelecionada as keyof typeof dadosAnoBase] as number)),
    percentual: (((dadosAnoComp[areaSelecionada as keyof typeof dadosAnoComp] as number) - 
                  (dadosAnoBase[areaSelecionada as keyof typeof dadosAnoBase] as number)) / 
                 (dadosAnoBase[areaSelecionada as keyof typeof dadosAnoBase] as number)) * 100,
  } : null;

  return (
    <div className="max-w-7xl mx-auto animate-fade-in">
      <div className="page-header">
        <h1 className="page-title">Análise Comparativa ENEM</h1>
        <p className="page-subtitle">Compare resultados entre anos, escolas e regiões</p>
      </div>

      {/* Filtros */}
      <div className="flex flex-wrap gap-4 mb-8">
        <div className="flex items-center gap-2">
          <span className="text-sm text-[var(--text-secondary)]">Área:</span>
          <Select value={areaSelecionada} onValueChange={setAreaSelecionada}>
            <SelectTrigger className="w-24">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {areas.map(a => <SelectItem key={a} value={a}>{a}</SelectItem>)}
            </SelectContent>
          </Select>
        </div>
        
        <div className="flex items-center gap-2">
          <span className="text-sm text-[var(--text-secondary)]">Ano base:</span>
          <Select value={anoBase} onValueChange={setAnoBase}>
            <SelectTrigger className="w-28">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {anos.map(a => <SelectItem key={a} value={a.toString()}>{a}</SelectItem>)}
            </SelectContent>
          </Select>
        </div>
        
        <div className="flex items-center gap-2">
          <span className="text-sm text-[var(--text-secondary)]">Comparar com:</span>
          <Select value={anoComparacao} onValueChange={setAnoComparacao}>
            <SelectTrigger className="w-28">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {anos.map(a => <SelectItem key={a} value={a.toString()}>{a}</SelectItem>)}
            </SelectContent>
          </Select>
        </div>
        
        <Button variant="outline" className="ml-auto">
          <Download className="w-4 h-4 mr-2" />
          Exportar
        </Button>
      </div>

      {/* Variação */}
      {variacao && (
        <Card className={`mb-8 ${variacao.percentual > 0 ? 'border-[var(--success)]' : 'border-[var(--error)]'}`}>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-[var(--text-secondary)]">
                  Variação {anoBase} → {anoComparacao} ({areaSelecionada})
                </p>
                <p className="text-4xl font-bold mt-2">
                  {variacao.media > 0 ? '+' : ''}{variacao.media} pts
                </p>
              </div>
              <Badge variant={variacao.percentual > 0 ? 'default' : 'destructive'} className="text-lg px-4 py-2">
                {variacao.percentual > 0 ? <TrendingUp className="w-5 h-5 inline mr-1" /> : <TrendingDown className="w-5 h-5 inline mr-1" />}
                {variacao.percentual > 0 ? '+' : ''}{variacao.percentual}%
              </Badge>
            </div>
          </CardContent>
        </Card>
      )}

      <Tabs defaultValue="evolucao" className="space-y-6">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="evolucao">Evolução</TabsTrigger>
          <TabsTrigger value="escolas">Escolas</TabsTrigger>
          <TabsTrigger value="regional">Regional</TabsTrigger>
          <TabsTrigger value="insights">Insights</TabsTrigger>
        </TabsList>

        <TabsContent value="evolucao">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle>Evolução das Médias</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <LineChart data={MOCK_COMPARATIVO_ANOS}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
                  <XAxis dataKey="ano" />
                  <YAxis domain={[450, 550]} />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="CH" stroke="#0071E3" strokeWidth={2} />
                  <Line type="monotone" dataKey="CN" stroke="#34C759" strokeWidth={2} />
                  <Line type="monotone" dataKey="LC" stroke="#FF9500" strokeWidth={2} />
                  <Line type="monotone" dataKey="MT" stroke="#AF52DE" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="escolas">
          <div className="grid grid-cols-2 gap-6">
            <Card className="glass-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <School className="w-5 h-5" />
                  Por Tipo de Escola
                </CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={MOCK_ESCOLAS_TIPO}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
                    <XAxis dataKey="tipo" />
                    <YAxis domain={[400, 650]} />
                    <Tooltip />
                    <Bar dataKey="media" fill="#0071E3" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            <Card className="glass-card">
              <CardHeader>
                <CardTitle>Detalhamento</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {MOCK_ESCOLAS_TIPO.map((escola) => (
                    <div key={escola.tipo} className="flex justify-between p-3 rounded-lg bg-[var(--bg-secondary)]">
                      <div>
                        <p className="font-medium">{escola.tipo}</p>
                        <p className="text-xs text-[var(--text-secondary)]">
                          {escola.n_escolas.toLocaleString()} escolas
                        </p>
                      </div>
                      <p className="text-xl font-bold">{escola.media}</p>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="regional">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MapPin className="w-5 h-5" />
                Ranking por UF
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {MOCK_UFS.map((uf, index) => (
                  <div key={uf.uf} className="flex items-center gap-4">
                    <span className="w-8 text-center font-bold text-[var(--text-tertiary)]">
                      {index + 1}º
                    </span>
                    <div className="flex-1">
                      <div className="flex justify-between mb-1">
                        <span className="font-medium">{uf.uf}</span>
                        <span className="font-mono">{uf.media}</span>
                      </div>
                      <div className="h-2 rounded-full bg-[var(--bg-secondary)]">
                        <div 
                          className="h-full bg-[var(--primary)] rounded-full"
                          style={{ width: `${(uf.media / 600) * 100}%` }}
                        />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="insights">
          <div className="grid gap-6">
            {MOCK_INSIGHTS.alertas.length > 0 && (
              <Card className="border-[var(--warning)]">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-[var(--warning)]">
                    <AlertTriangle className="w-5 h-5" />
                    Alertas
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {MOCK_INSIGHTS.alertas.map((alerta, i) => (
                    <div key={i} className="p-4 rounded-lg bg-[var(--warning)]/10">
                      <Badge variant="destructive">{alerta.severidade}</Badge>
                      <p className="mt-2">{alerta.mensagem}</p>
                    </div>
                  ))}
                </CardContent>
              </Card>
            )}

            <Card className="glass-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Lightbulb className="w-5 h-5" />
                  Recomendações
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {MOCK_INSIGHTS.recomendacoes.map((rec) => (
                    <div key={rec.prioridade} className="p-4 rounded-lg bg-[var(--bg-secondary)]">
                      <Badge className="mb-2">{rec.categoria}</Badge>
                      <h4 className="font-semibold">{rec.titulo}</h4>
                      <p className="text-sm text-[var(--text-secondary)] mt-2">{rec.descricao}</p>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
