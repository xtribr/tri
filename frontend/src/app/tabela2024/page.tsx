'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Info, FileText, Download } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import Link from 'next/link';
import { 
  ComposedChart, Area, Line, XAxis, YAxis, CartesianGrid, 
  Tooltip, ResponsiveContainer 
} from 'recharts';
import { ENEM_2024_DADOS } from '@/lib/api/enemData2024';
import type { ENEMArea } from '@/lib/utils/enemConversion';

const AREA_INFO = {
  CH: { nome: 'Ciências Humanas', cor: '#34C759', n_itens: 45 },
  CN: { nome: 'Ciências da Natureza', cor: '#007AFF', n_itens: 45 },
  LC: { nome: 'Linguagens e Códigos', cor: '#FF9500', n_itens: 45 },
  MT: { nome: 'Matemática', cor: '#AF52DE', n_itens: 45 },
};

export default function Tabela2024Page() {
  const [area, setArea] = useState<ENEMArea>('MT');
  
  const dadosArea = ENEM_2024_DADOS[area];
  const info = AREA_INFO[area];
  
  // Preparar dados para o gráfico
  const dadosGrafico = dadosArea?.tabela_amplitude?.map((row) => ({
    acertos: row.acertos,
    min: row.notaMin,
    med: row.notaMed,
    max: row.notaMax,
  })) || [];
  
  const yMin = Math.min(...dadosGrafico.map(d => d.min));
  const yMax = Math.max(...dadosGrafico.map(d => d.max));
  
  // Exportar CSV
  const exportarCSV = () => {
    if (!dadosArea?.tabela_amplitude) return;
    
    let csv = 'Acertos,NotaMin,NotaMed,NotaMax\n';
    dadosArea.tabela_amplitude.forEach(row => {
      csv += `${row.acertos},${row.notaMin},${row.notaMed},${row.notaMax}\n`;
    });
    
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `enem_2024_${area.toLowerCase()}.csv`;
    a.click();
  };
  
  return (
    <div className="max-w-7xl mx-auto animate-fade-in">
      <div className="page-header">
        <h1 className="page-title">Tabela de Conversão ENEM 2024</h1>
        <p className="page-subtitle">
          Dados calculados via MIRT a partir dos microdados oficiais do INEP
        </p>
      </div>

      {/* Badge de metodologia */}
      <div className="mb-6">
        <Badge variant="outline" className="px-3 py-1.5 text-sm font-medium bg-[var(--success)]/10 text-[var(--success)] border-[var(--success)]/30">
          Método: Acertos calculados cruzando TX_RESPOSTAS × TX_GABARITO
        </Badge>
      </div>

      {/* Seletor de área */}
      <div className="flex flex-wrap gap-2 mb-6">
        {(Object.keys(AREA_INFO) as ENEMArea[]).map((a) => (
          <button
            key={a}
            onClick={() => setArea(a)}
            className={`px-4 py-2 rounded-lg font-medium transition-all ${
              area === a
                ? 'text-white shadow-md scale-105'
                : 'bg-[var(--background-elevated)] text-[var(--text-secondary)] hover:bg-[var(--border-light)]'
            }`}
            style={{ 
              backgroundColor: area === a ? info.cor : undefined 
            }}
          >
            {a}
          </button>
        ))}
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        {/* Gráfico */}
        <Card className="glass-card lg:col-span-2">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-lg">
              <span style={{ color: info.cor }}>{info.nome}</span>
              <span className="text-sm font-normal text-[var(--text-secondary)]">
                ({info.n_itens} questões)
              </span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[400px]">
              <ResponsiveContainer width="100%" height="100%">
                <ComposedChart data={dadosGrafico} margin={{ top: 10, right: 20, bottom: 10, left: 0 }}>
                  <defs>
                    <linearGradient id={`gradient-${area}`} x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor={info.cor} stopOpacity={0.3}/>
                      <stop offset="95%" stopColor={info.cor} stopOpacity={0.05}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--border-light)" />
                  <XAxis 
                    dataKey="acertos" 
                    stroke="var(--text-secondary)"
                    tick={{ fill: 'var(--text-secondary)', fontSize: 12 }}
                  />
                  <YAxis 
                    domain={[Math.floor(yMin * 0.95), Math.ceil(yMax * 1.02)]}
                    stroke="var(--text-secondary)"
                    tick={{ fill: 'var(--text-secondary)', fontSize: 12 }}
                    tickFormatter={(value) => value.toFixed(0)}
                  />
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: 'var(--background-elevated)',
                      border: '1px solid var(--border-light)',
                      borderRadius: '8px'
                    }}
                    labelStyle={{ color: 'var(--text-primary)' }}
                  />
                  <Area 
                    type="monotone" 
                    dataKey="max" 
                    stroke="none" 
                    fill={`url(#gradient-${area})`}
                  />
                  <Area 
                    type="monotone" 
                    dataKey="min" 
                    stroke="none" 
                    fill="transparent"
                  />
                  <Line 
                    type="monotone" 
                    dataKey="med" 
                    stroke={info.cor} 
                    strokeWidth={3}
                    dot={{ fill: info.cor, strokeWidth: 0, r: 3 }}
                    name="Mediana"
                  />
                </ComposedChart>
              </ResponsiveContainer>
            </div>
            
            <div className="flex items-center justify-center gap-6 mt-4 text-sm text-[var(--text-secondary)]">
              <div className="flex items-center gap-2">
                <div className="w-4 h-1 rounded" style={{ backgroundColor: info.cor }} />
                <span>Mediana</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 rounded opacity-30" style={{ backgroundColor: info.cor }} />
                <span>Faixa (Min-Max)</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Estatísticas */}
        <Card className="glass-card">
          <CardHeader className="pb-2">
            <CardTitle className="text-lg">Estatísticas</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="p-3 rounded-lg bg-[var(--background-elevated)]">
                <div className="text-sm text-[var(--text-secondary)]">Candidatos</div>
                <div className="text-2xl font-bold text-[var(--text-primary)]">
                  {dadosArea?.estatisticas?.n_presentes?.toLocaleString('pt-BR') || '-'}
                </div>
              </div>
              
              <div className="p-3 rounded-lg bg-[var(--background-elevated)]">
                <div className="text-sm text-[var(--text-secondary)]">Média</div>
                <div className="text-2xl font-bold" style={{ color: info.cor }}>
                  {dadosArea?.estatisticas?.media?.toFixed(1) || '-'}
                </div>
              </div>
              
              <div className="p-3 rounded-lg bg-[var(--background-elevated)]">
                <div className="text-sm text-[var(--text-secondary)]">Mediana</div>
                <div className="text-2xl font-bold text-[var(--text-primary)]">
                  {dadosArea?.estatisticas?.mediana?.toFixed(1) || '-'}
                </div>
              </div>
              
              <div className="p-3 rounded-lg bg-[var(--background-elevated)]">
                <div className="text-sm text-[var(--text-secondary)]">Desvio Padrão</div>
                <div className="text-2xl font-bold text-[var(--text-primary)]">
                  {dadosArea?.estatisticas?.dp?.toFixed(1) || '-'}
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-2 pt-2">
                <div className="p-2 rounded bg-[var(--background-elevated)] text-center">
                  <div className="text-xs text-[var(--text-secondary)]">Mínimo</div>
                  <div className="font-semibold">{dadosArea?.estatisticas?.min?.toFixed(1) || '-'}</div>
                </div>
                <div className="p-2 rounded bg-[var(--background-elevated)] text-center">
                  <div className="text-xs text-[var(--text-secondary)]">Máximo</div>
                  <div className="font-semibold">{dadosArea?.estatisticas?.max?.toFixed(1) || '-'}</div>
                </div>
              </div>
              
              <Button onClick={exportarCSV} className="w-full btn-primary" variant="outline">
                <Download className="w-4 h-4 mr-2" />
                Exportar CSV
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabela de dados */}
      <Card className="glass-card mt-6">
        <CardHeader className="pb-2">
          <CardTitle className="text-lg">Tabela Completa - {info.nome}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-[var(--border-light)]">
                  <th className="text-left py-2 px-3 font-semibold text-[var(--text-secondary)]">Acertos</th>
                  <th className="text-right py-2 px-3 font-semibold text-[var(--text-secondary)]">Nota Min</th>
                  <th className="text-right py-2 px-3 font-semibold" style={{ color: info.cor }}>Nota Med</th>
                  <th className="text-right py-2 px-3 font-semibold text-[var(--text-secondary)]">Nota Max</th>
                  <th className="text-right py-2 px-3 font-semibold text-[var(--text-secondary)]">Δ Min→Max</th>
                </tr>
              </thead>
              <tbody>
                {dadosArea?.tabela_amplitude?.map((row, idx) => (
                  <tr 
                    key={row.acertos} 
                    className={`border-b border-[var(--border-light)] hover:bg-[var(--background-elevated)] transition-colors ${
                      idx % 5 === 0 ? 'bg-[var(--background-elevated)]/50' : ''
                    }`}
                  >
                    <td className="py-1.5 px-3 font-medium">{row.acertos}</td>
                    <td className="text-right py-1.5 px-3 text-[var(--text-secondary)]">{row.notaMin.toFixed(1)}</td>
                    <td className="text-right py-1.5 px-3 font-semibold" style={{ color: info.cor }}>{row.notaMed.toFixed(1)}</td>
                    <td className="text-right py-1.5 px-3 text-[var(--text-secondary)]">{row.notaMax.toFixed(1)}</td>
                    <td className="text-right py-1.5 px-3 text-xs text-[var(--text-tertiary)]">
                      +{(row.notaMax - row.notaMin).toFixed(1)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Info de metodologia */}
      <Card className="glass-card mt-6 border-[var(--primary)]/30">
        <CardHeader className="pb-2">
          <CardTitle className="flex items-center gap-2 text-base">
            <Info className="w-5 h-5 text-[var(--primary)]" />
            Metodologia
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-sm text-[var(--text-secondary)] space-y-2">
            <p>
              <strong className="text-[var(--text-primary)]">Fonte:</strong> Microdados ENEM 2024 (INEP)
            </p>
            <p>
              <strong className="text-[var(--text-primary)]">Método:</strong> Cálculo de acertos por candidato 
              cruzando <code className="bg-[var(--background-elevated)] px-1.5 py-0.5 rounded text-xs">TX_RESPOSTAS</code> com 
              <code className="bg-[var(--background-elevated)] px-1.5 py-0.5 rounded text-xs">TX_GABARITO</code> do arquivo ITENS_PROVA.
            </p>
            <p>
              <strong className="text-[var(--text-primary)]">Amostra:</strong> 100.000 candidatos aleatórios (representativa).
            </p>
            <p>
              <strong className="text-[var(--text-primary)]">LC:</strong> 45 questões (língua estrangeira removida - 
              questões de inglês/espanhol são alternativas).
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Links */}
      <div className="flex flex-wrap gap-4 mt-6">
        <Button className="btn-primary" asChild>
          <Link href="/tabela">
            <FileText className="w-4 h-4 mr-2" />
            Ver Tabelas Históricas
          </Link>
        </Button>
      </div>
    </div>
  );
}
