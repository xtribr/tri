'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Button } from '@/components/ui/button';
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
import { 
  BookOpen, 
  TrendingDown, 
  Target, 
  TrendingUp, 
  Download,
  CheckCircle2
} from 'lucide-react';
import { ENEM_2024_DADOS, getTabela2024, getEstatisticas2024 } from '@/lib/api/enemData2024';
import type { ENEMArea } from '@/lib/utils/enemConversion';

const AREAS_CONFIG: Record<ENEMArea, { nome: string; cor: string; n_itens: number }> = {
  CH: { nome: 'Ciências Humanas', cor: '#0071E3', n_itens: 45 },
  CN: { nome: 'Ciências da Natureza', cor: '#34C759', n_itens: 45 },
  LC: { nome: 'Linguagens e Códigos', cor: '#FF9500', n_itens: 50 },
  MT: { nome: 'Matemática', cor: '#AF52DE', n_itens: 45 },
};

export default function Tabela2024Page() {
  const [area, setArea] = useState<ENEMArea>('MT');
  
  const areaConfig = AREAS_CONFIG[area];
  const stats = getEstatisticas2024(area);
  const tabela = getTabela2024(area);
  
  // Preparar dados para gráfico
  const dadosGrafico = tabela?.map((row) => ({
    acertos: row.acertos,
    min: row.notaMin,
    med: row.notaMed,
    max: row.notaMax,
    amplitude: row.notaMax - row.notaMin,
  })) || [];

  // Exportar CSV
  const exportarCSV = () => {
    if (!tabela) return;
    
    const headers = ['Acertos', 'Nota_MIN', 'Nota_MED', 'Nota_MAX', 'Amplitude'];
    const rows = tabela.map((row) => [
      row.acertos,
      row.notaMin.toFixed(1),
      row.notaMed.toFixed(1),
      row.notaMax.toFixed(1),
      (row.notaMax - row.notaMin).toFixed(1),
    ]);
    
    const csv = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `tabela_enem_2024_${area}.csv`;
    a.click();
  };

  if (!stats || !tabela) {
    return (
      <div className="max-w-7xl mx-auto">
        <div className="page-header">
          <h1 className="page-title">Tabela ENEM 2024 - Dados Reais</h1>
        </div>
        <Card className="glass-card p-8 text-center">
          <p className="text-[var(--text-secondary)]">Dados não disponíveis</p>
        </Card>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto animate-fade-in">
      <div className="page-header">
        <div className="flex items-end justify-between">
          <div>
            <div className="flex items-center gap-3">
              <h1 className="page-title">Tabela ENEM 2024</h1>
              <Badge variant="default" className="bg-[var(--success)]">
                <CheckCircle2 className="w-3 h-3 mr-1" />
                Dados Reais
              </Badge>
            </div>
            <p className="page-subtitle">
              Microdados oficiais do INEP - {ENEM_2024_DADOS.metadata.total_inscritos.toLocaleString('pt-BR')} inscritos
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
            
            <Button variant="outline" onClick={exportarCSV}>
              <Download className="w-4 h-4 mr-2" />
              Exportar
            </Button>
          </div>
        </div>
      </div>

      {/* Cards de resumo com dados reais */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Nota Mínima Real</p>
            <p className="text-3xl font-bold text-[var(--error)]">
              {stats.min.toFixed(0)}
            </p>
            <p className="text-xs text-[var(--text-secondary)]">0 acertos</p>
          </CardContent>
        </Card>
        
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Média Nacional</p>
            <p className="text-3xl font-bold text-[var(--primary)]">
              {stats.media.toFixed(0)}
            </p>
            <p className="text-xs text-[var(--text-secondary)]">{stats.n_presentes.toLocaleString('pt-BR')} presentes</p>
          </CardContent>
        </Card>
        
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Nota Máxima Real</p>
            <p className="text-3xl font-bold text-[var(--success)]">
              {stats.max.toFixed(0)}
            </p>
            <p className="text-xs text-[var(--text-secondary)]">{areaConfig.n_itens} acertos</p>
          </CardContent>
        </Card>
        
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Desvio Padrão</p>
            <p className="text-3xl font-bold" style={{ color: areaConfig.cor }}>
              {stats.dp.toFixed(0)}
            </p>
            <p className="text-xs text-[var(--text-secondary)]">variabilidade</p>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="grafico" className="space-y-6">
        <TabsList className="grid w-full grid-cols-2 lg:w-auto lg:inline-flex">
          <TabsTrigger value="grafico">Gráfico de Amplitude</TabsTrigger>
          <TabsTrigger value="tabela">Tabela Completa (0-{areaConfig.n_itens})</TabsTrigger>
        </TabsList>

        {/* Gráfico de Amplitude */}
        <TabsContent value="grafico">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingDown className="w-5 h-5 text-[var(--error)]" />
                <Target className="w-5 h-5 text-[var(--primary)]" />
                <TrendingUp className="w-5 h-5 text-[var(--success)]" />
                Faixa de Notas por Acertos - {areaConfig.nome} (2024)
                <span className="text-sm font-normal text-[var(--text-secondary)] ml-2">
                  Dados reais: {stats.n_presentes.toLocaleString('pt-BR')} candidatos
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={500}>
                <ComposedChart data={dadosGrafico} key={area}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
                  <XAxis 
                    dataKey="acertos" 
                    label={{ value: 'Número de Acertos', position: 'insideBottom', offset: -5 }}
                  />
                  <YAxis 
                    label={{ value: 'Nota ENEM', angle: -90, position: 'insideLeft' }}
                    tickFormatter={(value) => value.toFixed(0)}
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
                    type="linear"
                    dataKey="min"
                    stroke="#FF3B30"
                    fill="#FF3B30"
                    fillOpacity={0.1}
                    strokeWidth={2}
                    name="Mínima"
                  />
                  <Area
                    type="linear"
                    dataKey="max"
                    stroke="#34C759"
                    fill="#34C759"
                    fillOpacity={0.1}
                    strokeWidth={2}
                    name="Máxima"
                  />
                  <Line
                    type="linear"
                    dataKey="med"
                    stroke="#0071E3"
                    strokeWidth={3}
                    dot={{ r: 3 }}
                    name="Média"
                  />
                </ComposedChart>
              </ResponsiveContainer>
              
              <div className="mt-6 grid grid-cols-3 gap-4 text-center text-sm">
                <div className="p-3 rounded-lg bg-[var(--error)]/10">
                  <p className="font-medium text-[var(--error)]">Linha Vermelha</p>
                  <p className="text-[var(--text-secondary)]">Nota mínima real para cada número de acertos</p>
                </div>
                <div className="p-3 rounded-lg bg-[var(--primary)]/10">
                  <p className="font-medium text-[var(--primary)]">Linha Azul</p>
                  <p className="text-[var(--text-secondary)]">Nota média (mais provável)</p>
                </div>
                <div className="p-3 rounded-lg bg-[var(--success)]/10">
                  <p className="font-medium text-[var(--success)]">Linha Verde</p>
                  <p className="text-[var(--text-secondary)]">Nota máxima real para cada número de acertos</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Tabela Completa */}
        <TabsContent value="tabela">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle>
                Tabela Completa - {areaConfig.nome} (2024)
                <span className="text-sm font-normal text-[var(--text-secondary)] ml-2">
                  Baseada em {stats.n_presentes.toLocaleString('pt-BR')} candidatos presentes
                </span>
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
                    </tr>
                  </thead>
                  <tbody>
                    {tabela.map((row, idx) => {
                      const variacaoAnterior = idx > 0 
                        ? ((row.notaMed - tabela[idx-1].notaMed) / tabela[idx-1].notaMed) * 100
                        : 0;
                      const amplitude = row.notaMax - row.notaMin;
                      const isDestaque = row.acertos % 5 === 0;
                      
                      return (
                        <tr 
                          key={row.acertos} 
                          className={`border-b border-[var(--border-light)] hover:bg-[var(--bg-tertiary)] transition-colors ${
                            isDestaque ? 'bg-[var(--bg-secondary)]/50' : ''
                          }`}
                        >
                          <td className="p-3 font-mono font-bold text-lg">{row.acertos}</td>
                          <td className="p-3 text-right font-mono text-[var(--text-secondary)]">
                            {row.notaMin.toFixed(1)}
                          </td>
                          <td className="p-3 text-right font-mono font-bold text-[var(--primary)] text-lg">
                            {row.notaMed.toFixed(1)}
                          </td>
                          <td className="p-3 text-right font-mono text-[var(--text-secondary)]">
                            {row.notaMax.toFixed(1)}
                          </td>
                          <td className="p-3 text-right">
                            <Badge 
                              variant={amplitude > 100 ? 'destructive' : amplitude > 50 ? 'secondary' : 'outline'}
                              className="font-mono"
                            >
                              {amplitude.toFixed(1)}
                            </Badge>
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
