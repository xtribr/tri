'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { ScrollArea } from '@/components/ui/scroll-area';
import {
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  Line,
  ComposedChart,
  Area,
} from 'recharts';
import { BookOpen, TrendingDown, Target, TrendingUp, Download } from 'lucide-react';
import { Button } from '@/components/ui/button';
import type { ENEMArea } from '@/lib/utils/enemConversion';
import enemData from '@/../config/presets_enem_historico.json';

const AREAS_CONFIG: Record<ENEMArea, { nome: string; cor: string; n_itens: number }> = {
  CH: { nome: 'Ciências Humanas', cor: '#0071E3', n_itens: 45 },
  CN: { nome: 'Ciências da Natureza', cor: '#34C759', n_itens: 45 },
  LC: { nome: 'Linguagens e Códigos', cor: '#FF9500', n_itens: 50 },
  MT: { nome: 'Matemática', cor: '#AF52DE', n_itens: 45 },
};

// Usar dados históricos do JSON
const DADOS_HISTORICOS = enemData as Record<string, any>;

export default function TabelaPage() {
  const [ano, setAno] = useState('2024');
  const [area, setArea] = useState<ENEMArea>('MT');
  const [anosComparacao, setAnosComparacao] = useState<string[]>(['2023', '2024']);

  const areaConfig = AREAS_CONFIG[area];
  
  // Pegar dados do ano selecionado
  const dadosAno = DADOS_HISTORICOS[ano]?.areas?.[area]?.tabela || [];
  
  // Preparar dados para gráfico de amplitude
  const dadosGrafico = dadosAno.map((row: any) => ({
    acertos: row.acertos,
    min: row.notaMin ?? row.min ?? 0,
    med: row.notaMed ?? row.med ?? 0,
    max: row.notaMax ?? row.max ?? 0,
    amplitude: (row.notaMax ?? row.max ?? 0) - (row.notaMin ?? row.min ?? 0),
  }));

  // Dados para comparação de médias entre anos
  const dadosComparacaoMed = anosComparacao.map(anoComp => {
    const tabela = DADOS_HISTORICOS[anoComp]?.areas?.[area]?.tabela || [];
    return tabela.map((row: any) => ({
      acertos: row.acertos,
      [anoComp]: row.notaMed ?? row.med ?? 0,
    }));
  });

  // Merge dos dados de comparação
  const dadosComparacaoMerged = dadosComparacaoMed.reduce((acc: any[], anoDados: any[]) => {
    anoDados.forEach((row: any) => {
      const existing = acc.find((r: any) => r.acertos === row.acertos);
      if (existing) {
        Object.assign(existing, row);
      } else {
        acc.push(row);
      }
    });
    return acc;
  }, [] as any[]);

  // Exportar CSV
  const exportarCSV = () => {
    const headers = ['Acertos', 'Nota_MIN', 'Nota_MED', 'Nota_MAX', 'Amplitude'];
    const rows = dadosGrafico.map((row: { acertos: number; min: number; med: number; max: number; amplitude: number }) => [
      row.acertos,
      row.min.toFixed(1),
      row.med.toFixed(1),
      row.max.toFixed(1),
      row.amplitude.toFixed(1),
    ]);
    
    const csv = [headers.join(','), ...rows.map((r: (string | number)[]) => r.join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `tabela_enem_${ano}_${area}.csv`;
    a.click();
  };

  return (
    <div className="max-w-7xl mx-auto animate-fade-in">
      <div className="page-header">
        <div className="flex items-end justify-between">
          <div>
            <h1 className="page-title">Tabela de Conversão ENEM</h1>
            <p className="page-subtitle">
              Notas MIN, MED e MAX por número de acertos oficiais do INEP
            </p>
          </div>
          <div className="flex gap-3">
            <Select value={area} onValueChange={(v) => setArea(v as ENEMArea)}>
              <SelectTrigger className="w-48">
                <BookOpen className="w-4 h-4 mr-2" />
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {Object.entries(AREAS_CONFIG).map(([cod, config]) => (
                  <SelectItem key={cod} value={cod}>{config.nome}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            
            <Select value={ano} onValueChange={setAno}>
              <SelectTrigger className="w-28">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {['2009', '2015', '2016', '2017', '2018', '2019', '2020', '2021', '2022', '2023', '2024'].map(a => (
                  <SelectItem key={a} value={a}>{a}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            
            <Button variant="outline" onClick={exportarCSV}>
              <Download className="w-4 h-4 mr-2" />
              Exportar
            </Button>
          </div>
        </div>
      </div>

      {/* Cards de resumo */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Nota Mínima</p>
            <p className="text-3xl font-bold text-[var(--error)]">
              {dadosGrafico.length > 0 ? dadosGrafico[0].min.toFixed(0) : '-'}
            </p>
            <p className="text-xs text-[var(--text-secondary)]">0 acertos</p>
          </CardContent>
        </Card>
        
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Nota Média (50%)</p>
            <p className="text-3xl font-bold text-[var(--primary)]">
              {dadosGrafico.length > 0 ? dadosGrafico[Math.floor(dadosGrafico.length/2)].med.toFixed(0) : '-'}
            </p>
            <p className="text-xs text-[var(--text-secondary)]">
              {Math.floor(areaConfig.n_itens/2)} acertos
            </p>
          </CardContent>
        </Card>
        
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Nota Máxima</p>
            <p className="text-3xl font-bold text-[var(--success)]">
              {dadosGrafico.length > 0 ? dadosGrafico[dadosGrafico.length-1].max.toFixed(0) : '-'}
            </p>
            <p className="text-xs text-[var(--text-secondary)]">{areaConfig.n_itens} acertos</p>
          </CardContent>
        </Card>
        
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Amplitude Máx</p>
            <p className="text-3xl font-bold" style={{ color: areaConfig.cor }}>
              {dadosGrafico.length > 0 
                ? Math.max(...dadosGrafico.map((d: { amplitude: number }) => d.amplitude)).toFixed(0) 
                : '-'}
            </p>
            <p className="text-xs text-[var(--text-secondary)]">maior variação</p>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="grafico" className="space-y-6">
        <TabsList className="grid w-full grid-cols-3 lg:w-auto lg:inline-flex">
          <TabsTrigger value="grafico">Gráfico de Amplitude</TabsTrigger>
          <TabsTrigger value="comparacao">Comparação Anual</TabsTrigger>
          <TabsTrigger value="tabela">Tabela Completa</TabsTrigger>
        </TabsList>

        {/* Gráfico de Amplitude */}
        <TabsContent value="grafico">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingDown className="w-5 h-5 text-[var(--error)]" />
                <Target className="w-5 h-5 text-[var(--primary)]" />
                <TrendingUp className="w-5 h-5 text-[var(--success)]" />
                Faixa de Notas por Acertos - {areaConfig.nome} ({ano})
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={500}>
                <ComposedChart data={dadosGrafico}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
                  <XAxis 
                    dataKey="acertos" 
                    label={{ value: 'Número de Acertos', position: 'insideBottom', offset: -5 }}
                  />
                  <YAxis 
                    domain={[250, 1000]}
                    label={{ value: 'Nota ENEM', angle: -90, position: 'insideLeft' }}
                  />
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: 'var(--bg-primary)', 
                      border: '1px solid var(--border-light)',
                      borderRadius: 'var(--radius-md)'
                    }}
                    formatter={(value, name) => {
                      const numValue = Number(value);
                      if (name === 'min') return [numValue.toFixed(1), 'Mínima'];
                      if (name === 'med') return [numValue.toFixed(1), 'Média'];
                      if (name === 'max') return [numValue.toFixed(1), 'Máxima'];
                      return [numValue.toFixed(1), name];
                    }}
                  />
                  <Legend />
                  
                  <Area
                    type="monotone"
                    dataKey="min"
                    stroke="#FF3B30"
                    fill="#FF3B30"
                    fillOpacity={0.1}
                    strokeWidth={2}
                    name="Mínima"
                  />
                  <Area
                    type="monotone"
                    dataKey="max"
                    stroke="#34C759"
                    fill="#34C759"
                    fillOpacity={0.1}
                    strokeWidth={2}
                    name="Máxima"
                  />
                  <Line
                    type="monotone"
                    dataKey="med"
                    stroke="#0071E3"
                    strokeWidth={3}
                    dot={false}
                    name="Média"
                  />
                </ComposedChart>
              </ResponsiveContainer>
              
              <div className="mt-6 grid grid-cols-3 gap-4 text-center text-sm">
                <div className="p-3 rounded-lg bg-[var(--error)]/10">
                  <p className="font-medium text-[var(--error)]">Linha Vermelha</p>
                  <p className="text-[var(--text-secondary)]">Nota mínima para cada número de acertos</p>
                </div>
                <div className="p-3 rounded-lg bg-[var(--primary)]/10">
                  <p className="font-medium text-[var(--primary)]">Linha Azul</p>
                  <p className="text-[var(--text-secondary)]">Nota média (mais provável)</p>
                </div>
                <div className="p-3 rounded-lg bg-[var(--success)]/10">
                  <p className="font-medium text-[var(--success)]">Linha Verde</p>
                  <p className="text-[var(--text-secondary)]">Nota máxima para cada número de acertos</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Comparação Anual */}
        <TabsContent value="comparacao">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle>Comparação de Médias - {areaConfig.nome}</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="mb-4 flex flex-wrap gap-2">
                {['2020', '2021', '2022', '2023', '2024'].map(anoOpt => (
                  <Badge
                    key={anoOpt}
                    variant={anosComparacao.includes(anoOpt) ? 'default' : 'outline'}
                    className="cursor-pointer"
                    onClick={() => {
                      if (anosComparacao.includes(anoOpt)) {
                        if (anosComparacao.length > 1) {
                          setAnosComparacao(anosComparacao.filter(a => a !== anoOpt));
                        }
                      } else {
                        setAnosComparacao([...anosComparacao, anoOpt]);
                      }
                    }}
                  >
                    {anoOpt}
                  </Badge>
                ))}
              </div>
              
              <ResponsiveContainer width="100%" height={450}>
                <ComposedChart data={dadosComparacaoMerged}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
                  <XAxis dataKey="acertos" />
                  <YAxis domain={[250, 1000]} />
                  <Tooltip />
                  <Legend />
                  {anosComparacao.map((anoComp, idx) => (
                    <Line
                      key={anoComp}
                      type="monotone"
                      dataKey={anoComp}
                      stroke={['#0071E3', '#34C759', '#FF9500', '#AF52DE', '#FF3B30'][idx]}
                      strokeWidth={2}
                      dot={false}
                    />
                  ))}
                </ComposedChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Tabela Completa */}
        <TabsContent value="tabela">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle>
                Tabela Completa - {areaConfig.nome} ({ano})
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ScrollArea className="h-[600px]">
                <table className="w-full">
                  <thead className="sticky top-0 bg-[var(--bg-secondary)] z-10">
                    <tr>
                      <th className="p-3 text-left text-xs font-bold text-[var(--text-secondary)] uppercase tracking-wider">
                        Acertos
                      </th>
                      <th className="p-3 text-right text-xs font-bold text-[var(--error)] uppercase tracking-wider">
                        <TrendingDown className="w-4 h-4 inline mr-1" />
                        Nota Mínima
                      </th>
                      <th className="p-3 text-right text-xs font-bold text-[var(--primary)] uppercase tracking-wider">
                        <Target className="w-4 h-4 inline mr-1" />
                        Nota Média
                      </th>
                      <th className="p-3 text-right text-xs font-bold text-[var(--success)] uppercase tracking-wider">
                        <TrendingUp className="w-4 h-4 inline mr-1" />
                        Nota Máxima
                      </th>
                      <th className="p-3 text-right text-xs font-bold text-[var(--text-secondary)] uppercase tracking-wider">
                        Amplitude
                      </th>
                      <th className="p-3 text-center text-xs font-bold text-[var(--text-secondary)] uppercase tracking-wider">
                        Variação
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {dadosGrafico.map((row: { acertos: number; min: number; med: number; max: number; amplitude: number }, idx: number) => {
                      const variacaoAnterior = idx > 0 
                        ? ((row.med - dadosGrafico[idx-1].med) / dadosGrafico[idx-1].med) * 100
                        : 0;
                      
                      return (
                        <tr 
                          key={row.acertos} 
                          className="border-b border-[var(--border-light)] hover:bg-[var(--bg-tertiary)] transition-colors"
                        >
                          <td className="p-3 font-mono font-bold text-lg">{row.acertos}</td>
                          <td className="p-3 text-right font-mono text-[var(--text-secondary)]">
                            {row.min.toFixed(1)}
                          </td>
                          <td className="p-3 text-right font-mono font-bold text-[var(--primary)] text-lg">
                            {row.med.toFixed(1)}
                          </td>
                          <td className="p-3 text-right font-mono text-[var(--text-secondary)]">
                            {row.max.toFixed(1)}
                          </td>
                          <td className="p-3 text-right">
                            <Badge 
                              variant={row.amplitude > 100 ? 'destructive' : row.amplitude > 50 ? 'secondary' : 'outline'}
                              className="font-mono"
                            >
                              {row.amplitude.toFixed(1)}
                            </Badge>
                          </td>
                          <td className="p-3 text-center">
                            {idx > 0 && (
                              <span className={`text-xs font-mono ${variacaoAnterior > 0 ? 'text-[var(--success)]' : 'text-[var(--error)]'}`}>
                                {variacaoAnterior > 0 ? '+' : ''}{variacaoAnterior.toFixed(2)}%
                              </span>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </ScrollArea>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
