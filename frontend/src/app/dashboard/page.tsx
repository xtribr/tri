'use client';

import React, { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  LineChart,
  Line,
  Cell,
} from 'recharts';
import { 
  Users, 
  BookOpen, 
  TrendingUp, 
  TrendingDown,
  School,
  MapPin,
  Calendar,
  AlertCircle
} from 'lucide-react';
import { carregarDadosENEM, type ENEMCompleteData, type ENEMYearData } from '@/lib/api/enemData';
import type { ENEMArea } from '@/lib/utils/enemConversion';

const AREAS_INFO: Record<ENEMArea, { nome: string; cor: string; icone: React.ElementType }> = {
  CH: { nome: 'Ciências Humanas', cor: '#0071E3', icone: BookOpen },
  CN: { nome: 'Ciências da Natureza', cor: '#34C759', icone: BookOpen },
  LC: { nome: 'Linguagens e Códigos', cor: '#FF9500', icone: BookOpen },
  MT: { nome: 'Matemática', cor: '#AF52DE', icone: BookOpen },
};

export default function DashboardPage() {
  const [anoSelecionado, setAnoSelecionado] = useState<number>(2024);
  const [dados, setDados] = useState<ENEMCompleteData | null>(null);
  const [carregando, setCarregando] = useState(true);
  const [areaDestaque, setAreaDestaque] = useState<ENEMArea>('MT');

  useEffect(() => {
    async function carregar() {
      setCarregando(true);
      const dadosENEM = await carregarDadosENEM(anoSelecionado);
      setDados(dadosENEM);
      setCarregando(false);
    }
    carregar();
  }, [anoSelecionado]);

  if (carregando) {
    return (
      <div className="max-w-7xl mx-auto flex items-center justify-center h-[60vh]">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[var(--primary)] mx-auto mb-4" />
          <p className="text-[var(--text-secondary)]">Carregando dados do ENEM {anoSelecionado}...</p>
        </div>
      </div>
    );
  }

  if (!dados) {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="page-header">
          <h1 className="page-title">Dashboard</h1>
          <p className="page-subtitle">Dados não disponíveis</p>
        </div>
        <Card className="glass-card p-8 text-center">
          <AlertCircle className="w-12 h-12 text-[var(--warning)] mx-auto mb-4" />
          <p className="text-[var(--text-secondary)]">
            Nenhum dado processado encontrado para {anoSelecionado}.
            <br />
            Execute o pipeline R para processar os microdados.
          </p>
        </Card>
      </div>
    );
  }

  const { metadata } = dados;
  const areas: ENEMArea[] = ['CH', 'CN', 'LC', 'MT'];

  // Preparar dados para gráficos
  const dadosGraficoMedia = areas.map(area => ({
    area,
    nome: AREAS_INFO[area].nome,
    media: dados[area]?.estatisticas.media || 0,
    dp: dados[area]?.estatisticas.dp || 0,
    cor: AREAS_INFO[area].cor,
  }));

  const dadosGraficoDistribuicao = areas.map(area => {
    const stats = dados[area]?.estatisticas;
    return {
      area,
      p10: stats?.p10 || 0,
      p25: stats?.p25 || 0,
      mediana: stats?.mediana || 0,
      p75: stats?.p75 || 0,
      p90: stats?.p90 || 0,
    };
  });

  return (
    <div className="max-w-7xl mx-auto animate-fade-in">
      <div className="page-header flex flex-wrap items-end justify-between gap-4">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <h1 className="page-title">ENEM {anoSelecionado}</h1>
            <Select value={anoSelecionado.toString()} onValueChange={(v) => setAnoSelecionado(parseInt(v))}>
              <SelectTrigger className="w-28">
                <Calendar className="w-4 h-4 mr-2" />
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="2024">2024</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <p className="page-subtitle">
            Análise dos microdados oficiais do INEP
            <span className="ml-2 text-xs text-[var(--text-tertiary)]">
              Processado em: {new Date(metadata.data_processamento).toLocaleDateString('pt-BR')}
            </span>
          </p>
        </div>
        <Badge variant="secondary" className="text-base px-4 py-2">
          <Users className="w-4 h-4 mr-2" />
          {metadata.total_inscritos.toLocaleString('pt-BR')} inscritos
        </Badge>
      </div>

      {/* KPIs por área */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        {areas.map((area) => {
          const stats = dados[area]?.estatisticas;
          if (!stats) return null;
          
          const AreaIcone = AREAS_INFO[area].icone;
          const cor = AREAS_INFO[area].cor;
          
          return (
            <Card 
              key={area} 
              className={`glass-card cursor-pointer transition-all hover:shadow-lg ${
                areaDestaque === area ? 'ring-2 ring-[var(--primary)]' : ''
              }`}
              onClick={() => setAreaDestaque(area)}
            >
              <CardContent className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <div 
                    className="w-10 h-10 rounded-lg flex items-center justify-center"
                    style={{ backgroundColor: `${cor}20` }}
                  >
                    <AreaIcone className="w-5 h-5" style={{ color: cor }} />
                  </div>
                  <Badge variant="outline">{area}</Badge>
                </div>
                <p className="text-sm text-[var(--text-secondary)] mb-1">
                  {AREAS_INFO[area].nome}
                </p>
                <p className="text-3xl font-bold" style={{ color: cor }}>
                  {stats.media.toFixed(1)}
                </p>
                <p className="text-xs text-[var(--text-tertiary)] mt-2">
                  DP: {stats.dp.toFixed(1)} • {stats.n_presentes.toLocaleString('pt-BR')} presentes
                </p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <Tabs defaultValue="visao-geral" className="space-y-6">
        <TabsList className="grid w-full grid-cols-3 lg:w-auto lg:inline-flex">
          <TabsTrigger value="visao-geral">Visão Geral</TabsTrigger>
          <TabsTrigger value="distribuicao">Distribuição</TabsTrigger>
          <TabsTrigger value="tabela">Tabela de Conversão</TabsTrigger>
        </TabsList>

        {/* Visão Geral */}
        <TabsContent value="visao-geral" className="space-y-6">
          <div className="grid grid-cols-2 gap-6">
            <Card className="glass-card">
              <CardHeader>
                <CardTitle>Médias por Área</CardTitle>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={dadosGraficoMedia}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
                    <XAxis dataKey="area" />
                    <YAxis domain={[400, 550]} />
                    <Tooltip 
                      formatter={(value, name, props: any) => [
                        `${Number(value).toFixed(1)} (DP: ${props.payload.dp.toFixed(1)})`,
                        'Média'
                      ]}
                    />
                    <Bar dataKey="media" radius={[4, 4, 0, 0]}>
                      {dadosGraficoMedia.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.cor} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            <Card className="glass-card">
              <CardHeader>
                <CardTitle>Estatísticas Detalhadas - {areaDestaque}</CardTitle>
              </CardHeader>
              <CardContent>
                {dados[areaDestaque] && (
                  <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div className="p-4 rounded-lg bg-[var(--bg-secondary)]">
                        <p className="text-xs text-[var(--text-tertiary)] uppercase">Média</p>
                        <p className="text-2xl font-bold">{dados[areaDestaque]!.estatisticas.media.toFixed(1)}</p>
                      </div>
                      <div className="p-4 rounded-lg bg-[var(--bg-secondary)]">
                        <p className="text-xs text-[var(--text-tertiary)] uppercase">Mediana</p>
                        <p className="text-2xl font-bold">{dados[areaDestaque]!.estatisticas.mediana.toFixed(1)}</p>
                      </div>
                      <div className="p-4 rounded-lg bg-[var(--bg-secondary)]">
                        <p className="text-xs text-[var(--text-tertiary)] uppercase">Desvio Padrão</p>
                        <p className="text-2xl font-bold">{dados[areaDestaque]!.estatisticas.dp.toFixed(1)}</p>
                      </div>
                      <div className="p-4 rounded-lg bg-[var(--bg-secondary)]">
                        <p className="text-xs text-[var(--text-tertiary)] uppercase">Amplitude</p>
                        <p className="text-2xl font-bold">
                          {(dados[areaDestaque]!.estatisticas.max - dados[areaDestaque]!.estatisticas.min).toFixed(0)}
                        </p>
                      </div>
                    </div>
                    <div className="text-sm text-[var(--text-secondary)]">
                      <p>Presentes: <strong>{dados[areaDestaque]!.estatisticas.n_presentes.toLocaleString('pt-BR')}</strong></p>
                      <p>Faltantes: <strong>{dados[areaDestaque]!.estatisticas.n_faltantes.toLocaleString('pt-BR')}</strong></p>
                      <p>Taxa de presença: <strong>
                        {((dados[areaDestaque]!.estatisticas.n_presentes / (dados[areaDestaque]!.estatisticas.n_presentes + dados[areaDestaque]!.estatisticas.n_faltantes)) * 100).toFixed(1)}%
                      </strong></p>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Distribuição */}
        <TabsContent value="distribuicao">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle>Distribuição Percentil por Área</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={dadosGraficoDistribuicao}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
                  <XAxis dataKey="area" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="p10" name="P10" fill="#FF3B30" />
                  <Bar dataKey="p25" name="P25" fill="#FF9500" />
                  <Bar dataKey="mediana" name="Mediana" fill="#0071E3" />
                  <Bar dataKey="p75" name="P75" fill="#34C759" />
                  <Bar dataKey="p90" name="P90" fill="#5856D6" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Tabela de Conversão */}
        <TabsContent value="tabela">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span>Tabela de Conversão - {AREAS_INFO[areaDestaque].nome}</span>
                <Select value={areaDestaque} onValueChange={(v) => setAreaDestaque(v as ENEMArea)}>
                  <SelectTrigger className="w-24">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {areas.map(a => <SelectItem key={a} value={a}>{a}</SelectItem>)}
                  </SelectContent>
                </Select>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-[var(--bg-secondary)] sticky top-0">
                    <tr>
                      <th className="p-3 text-left text-xs font-medium text-[var(--text-secondary)] uppercase">Acertos</th>
                      <th className="p-3 text-right text-xs font-medium text-[var(--error)] uppercase">Mínima</th>
                      <th className="p-3 text-right text-xs font-medium text-[var(--primary)] uppercase">Média</th>
                      <th className="p-3 text-right text-xs font-medium text-[var(--success)] uppercase">Máxima</th>
                      <th className="p-3 text-right text-xs font-medium text-[var(--text-secondary)] uppercase">Amplitude</th>
                    </tr>
                  </thead>
                  <tbody>
                    {dados[areaDestaque]?.tabela_amplitude.map((row, idx) => {
                      if (idx % 5 !== 0) return null; // Mostrar a cada 5 acertos
                      const amplitude = (row.notaMax || 0) - (row.notaMin || 0);
                      return (
                        <tr key={row.acertos} className="border-b border-[var(--border-light)] hover:bg-[var(--bg-secondary)]">
                          <td className="p-3 font-mono">{row.acertos}</td>
                          <td className="p-3 text-right font-mono text-[var(--text-secondary)]">
                            {row.notaMin?.toFixed(1) || '-'}
                          </td>
                          <td className="p-3 text-right font-mono font-bold text-[var(--primary)]">
                            {row.notaMed?.toFixed(1) || '-'}
                          </td>
                          <td className="p-3 text-right font-mono text-[var(--text-secondary)]">
                            {row.notaMax?.toFixed(1) || '-'}
                          </td>
                          <td className="p-3 text-right">
                            <Badge variant={amplitude > 50 ? 'destructive' : 'secondary'} className="font-mono text-xs">
                              ±{(amplitude / 2).toFixed(0)}
                            </Badge>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
