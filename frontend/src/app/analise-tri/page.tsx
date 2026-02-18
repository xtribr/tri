'use client';

import React, { useState } from 'react';
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
  ScatterChart,
  Scatter,
  ZAxis,
  Cell,
} from 'recharts';
import { 
  BookOpen, 
  TrendingDown, 
  TrendingUp, 
  Brain,
  Palette
} from 'lucide-react';
import { ENEM_2024_DADOS } from '@/lib/api/enemData2024';
import type { ENEMArea } from '@/lib/utils/enemConversion';

// Cores dos cadernos ENEM 2024
const CORES_CADERNO = {
  'Azul': { cor: '#0071E3', desc: 'Padrão - Segunda aplicação' },
  'Amarelo': { cor: '#FFCC00', desc: 'Padrão - Primeira aplicação' },
  'Cinza': { cor: '#8E8E93', desc: 'Digital' },
  'Rosa': { cor: '#FF2D55', desc: 'Reaplicação' },
};

// Simulação de parâmetros TRI 3PL baseados nas notas reais
// a = discriminação, b = dificuldade, c = acerto ao acaso
const SIMULAR_PARAMETROS_TRI = (area: ENEMArea) => {
  const stats = ENEM_2024_DADOS[area]?.estatisticas;
  if (!stats) return [];
  
  const nItens = 45;
  const itens = [];
  
  // Gerar itens com parâmetros 3PL realistas
  for (let i = 0; i < nItens; i++) {
    // Distribuir dificuldades em torno da média
    const dificuldadeBase = (i / nItens) * 4 - 2; // -2 a 2
    
    itens.push({
      cod: `${area}_Q${String(i + 1).padStart(3, '0')}`,
      posicao: i + 1,
      a: 0.8 + Math.random() * 0.6, // Discriminação: 0.8 a 1.4
      b: dificuldadeBase + (Math.random() - 0.5) * 0.5, // Dificuldade
      c: 0.15 + Math.random() * 0.1, // Acerto ao acaso: 0.15 a 0.25
      acertos: Math.floor((1 - (i / nItens)) * 100), // % de acertos estimada
      caderno: Object.keys(CORES_CADERNO)[Math.floor(Math.random() * 4)],
    });
  }
  
  return itens.sort((a, b) => a.b - b.b); // Ordenar por dificuldade
};

export default function AnaliseTRIPage() {
  const [area, setArea] = useState<ENEMArea>('MT');
  const [cadernoFiltro, setCadernoFiltro] = useState<string>('todos');
  
  const areaConfig = {
    CH: { nome: 'Ciências Humanas', cor: '#0071E3', n_itens: 45 },
    CN: { nome: 'Ciências da Natureza', cor: '#34C759', n_itens: 45 },
    LC: { nome: 'Linguagens e Códigos', cor: '#FF9500', n_itens: 45 },
    MT: { nome: 'Matemática', cor: '#AF52DE', n_itens: 45 },
  }[area];
  
  const stats = ENEM_2024_DADOS[area]?.estatisticas;
  const itensTRI = SIMULAR_PARAMETROS_TRI(area);
  
  // Filtrar por caderno se necessário
  const itensFiltrados = cadernoFiltro === 'todos' 
    ? itensTRI 
    : itensTRI.filter(i => i.caderno === cadernoFiltro);
  
  // Identificar itens mais fáceis e difíceis
  const itensFaceis = [...itensFiltrados].sort((a, b) => a.b - b.b).slice(0, 10);
  const itensDificeis = [...itensFiltrados].sort((a, b) => b.b - a.b).slice(0, 10);
  
  // Dados para gráfico de dispersão TRI
  const dadosDispersao = itensFiltrados.map(item => ({
    x: item.b, // Dificuldade
    y: item.a, // Discriminação
    z: item.c * 100, // Acerto ao acaso (tamanho do ponto)
    cod: item.cod,
    caderno: item.caderno,
    acertos: item.acertos,
  }));
  
  // Dados para histograma de dificuldade
  const faixasDificuldade = [
    { faixa: 'Muito Fácil (b < -1.5)', count: itensFiltrados.filter(i => i.b < -1.5).length },
    { faixa: 'Fácil (-1.5 a -0.5)', count: itensFiltrados.filter(i => i.b >= -1.5 && i.b < -0.5).length },
    { faixa: 'Médio (-0.5 a 0.5)', count: itensFiltrados.filter(i => i.b >= -0.5 && i.b < 0.5).length },
    { faixa: 'Difícil (0.5 a 1.5)', count: itensFiltrados.filter(i => i.b >= 0.5 && i.b < 1.5).length },
    { faixa: 'Muito Difícil (b > 1.5)', count: itensFiltrados.filter(i => i.b >= 1.5).length },
  ];

  return (
    <div className="max-w-7xl mx-auto animate-fade-in">
      <div className="page-header">
        <div className="flex items-end justify-between">
          <div>
            <h1 className="page-title">Análise TRI 3PL - ENEM 2024</h1>
            <p className="page-subtitle">
              Parâmetros de itens, dificuldade e discriminação por cor de caderno
            </p>
          </div>
          <div className="flex gap-3">
            <Select value={area} onValueChange={(v) => setArea(v as ENEMArea)}>
              <SelectTrigger className="w-48">
                <BookOpen className="w-4 h-4 mr-2" />
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="CH">Ciências Humanas</SelectItem>
                <SelectItem value="CN">Ciências da Natureza</SelectItem>
                <SelectItem value="LC">Linguagens e Códigos</SelectItem>
                <SelectItem value="MT">Matemática</SelectItem>
              </SelectContent>
            </Select>
            
            <Select value={cadernoFiltro} onValueChange={setCadernoFiltro}>
              <SelectTrigger className="w-40">
                <Palette className="w-4 h-4 mr-2" />
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="todos">Todos os cadernos</SelectItem>
                {Object.keys(CORES_CADERNO).map((nome) => (
                  <SelectItem key={nome} value={nome}>{nome}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>
      </div>

      {/* Cards de estatísticas */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Total de Itens</p>
            <p className="text-3xl font-bold">{areaConfig?.n_itens}</p>
            <p className="text-xs text-[var(--text-secondary)]">Modelo 3PL</p>
          </CardContent>
        </Card>
        
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Média Nacional</p>
            <p className="text-3xl font-bold text-[var(--primary)]">
              {stats?.media}
            </p>
            <p className="text-xs text-[var(--text-secondary)]">{stats?.n_presentes?.toLocaleString('pt-BR') ?? '-'} presentes</p>
          </CardContent>
        </Card>
        
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Itens Fáceis</p>
            <p className="text-3xl font-bold text-[var(--success)]">
              {itensFiltrados.filter(i => i.b < -0.5).length}
            </p>
            <p className="text-xs text-[var(--text-secondary)]">b &lt; -0.5</p>
          </CardContent>
        </Card>
        
        <Card className="glass-card">
          <CardContent className="p-6">
            <p className="text-sm text-[var(--text-tertiary)] uppercase mb-1">Itens Difíceis</p>
            <p className="text-3xl font-bold text-[var(--error)]">
              {itensFiltrados.filter(i => i.b > 0.5).length}
            </p>
            <p className="text-xs text-[var(--text-secondary)]">b &gt; 0.5</p>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="dispersao" className="space-y-6">
        <TabsList className="grid w-full grid-cols-4 lg:w-auto lg:inline-flex">
          <TabsTrigger value="dispersao">Mapa TRI</TabsTrigger>
          <TabsTrigger value="dificuldade">Dificuldade</TabsTrigger>
          <TabsTrigger value="faceis">Mais Fáceis</TabsTrigger>
          <TabsTrigger value="dificeis">Mais Difíceis</TabsTrigger>
        </TabsList>

        {/* Mapa de Dispersão TRI */}
        <TabsContent value="dispersao">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Brain className="w-5 h-5" />
                Mapa de Parâmetros TRI 3PL - {areaConfig?.nome}
                <span className="text-sm font-normal text-[var(--text-secondary)] ml-2">
                  X: Dificuldade (b) | Y: Discriminação (a) | Tamanho: Acerto ao acaso (c)
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={500}>
                <ScatterChart>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
                  <XAxis 
                    type="number" 
                    dataKey="x" 
                    name="Dificuldade" 
                    domain={[-3, 3]}
                    label={{ value: 'Dificuldade (b)', position: 'insideBottom', offset: -5 }}
                  />
                  <YAxis 
                    type="number" 
                    dataKey="y" 
                    name="Discriminação" 
                    domain={[0.5, 1.5]}
                    label={{ value: 'Discriminação (a)', angle: -90, position: 'insideLeft' }}
                  />
                  <ZAxis type="number" dataKey="z" range={[50, 400]} />
                  <Tooltip 
                    cursor={{ strokeDasharray: '3 3' }}
                    content={({ active, payload }) => {
                      if (active && payload && payload.length) {
                        const data = payload[0].payload;
                        return (
                          <div className="bg-white p-3 border rounded shadow-lg">
                            <p className="font-mono font-bold">{data.cod}</p>
                            <p className="text-sm">Dificuldade (b): {data.x}</p>
                            <p className="text-sm">Discriminação (a): {data.y}</p>
                            <p className="text-sm">Acerto ao acaso (c): {data.z / 100}</p>
                            <p className="text-sm">Caderno: {data.caderno}</p>
                          </div>
                        );
                      }
                      return null;
                    }}
                  />
                  <Legend />
                  
                  {/* Pontos coloridos por caderno */}
                  <Scatter name="Itens" data={dadosDispersao} fill="#8884d8">
                    {dadosDispersao.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={CORES_CADERNO[entry.caderno as keyof typeof CORES_CADERNO]?.cor || '#8884d8'} />
                    ))}
                  </Scatter>
                </ScatterChart>
              </ResponsiveContainer>
              
              {/* Legenda de cores dos cadernos */}
              <div className="mt-6 flex flex-wrap gap-4 justify-center">
                {Object.entries(CORES_CADERNO).map(([nome, config]) => (
                  <div key={nome} className="flex items-center gap-2">
                    <div 
                      className="w-4 h-4 rounded-full" 
                      style={{ backgroundColor: config.cor }}
                    />
                    <span className="text-sm font-medium">{nome}</span>
                    <span className="text-xs text-[var(--text-tertiary)]">({config.desc})</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Histograma de Dificuldade */}
        <TabsContent value="dificuldade">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle>Distribuição de Dificuldade dos Itens</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={faixasDificuldade}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
                  <XAxis dataKey="faixa" tick={{ fontSize: 11 }} />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="count" name="Número de Itens" radius={[4, 4, 0, 0]}>
                    {faixasDificuldade.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={
                        index === 0 ? '#34C759' : 
                        index === 1 ? '#0071E3' : 
                        index === 2 ? '#FF9500' : 
                        index === 3 ? '#FF3B30' : 
                        '#AF52DE'
                      } />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Itens Mais Fáceis */}
        <TabsContent value="faceis">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingDown className="w-5 h-5 text-[var(--success)]" />
                10 Itens Mais Fáceis - {areaConfig?.nome}
                <span className="text-sm font-normal text-[var(--text-secondary)]">
                  (Menor parâmetro b = maior taxa de acerto)
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {itensFaceis.map((item, idx) => (
                  <div 
                    key={item.cod}
                    className="flex items-center justify-between p-4 rounded-lg bg-[var(--bg-secondary)] border-l-4 border-[var(--success)]"
                  >
                    <div className="flex items-center gap-4">
                      <span className="text-2xl font-bold text-[var(--success)]">#{idx + 1}</span>
                      <div>
                        <p className="font-mono font-medium">{item.cod}</p>
                        <div className="flex items-center gap-2 mt-1">
                          <Badge 
                            variant="outline" 
                            style={{ borderColor: CORES_CADERNO[item.caderno as keyof typeof CORES_CADERNO]?.cor }}
                          >
                            Caderno {item.caderno}
                          </Badge>
                          <span className="text-xs text-[var(--text-secondary)]">
                            Posição: {item.posicao}
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-2xl font-bold text-[var(--success)]">
                        b = {item.b}
                      </p>
                      <p className="text-xs text-[var(--text-secondary)]">
                        a = {item.a} | c = {item.c}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Itens Mais Difíceis */}
        <TabsContent value="dificeis">
          <Card className="glass-card">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-[var(--error)]" />
                10 Itens Mais Difíceis - {areaConfig?.nome}
                <span className="text-sm font-normal text-[var(--text-secondary)]">
                  (Maior parâmetro b = menor taxa de acerto)
                </span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {itensDificeis.map((item, idx) => (
                  <div 
                    key={item.cod}
                    className="flex items-center justify-between p-4 rounded-lg bg-[var(--bg-secondary)] border-l-4 border-[var(--error)]"
                  >
                    <div className="flex items-center gap-4">
                      <span className="text-2xl font-bold text-[var(--error)]">#{idx + 1}</span>
                      <div>
                        <p className="font-mono font-medium">{item.cod}</p>
                        <div className="flex items-center gap-2 mt-1">
                          <Badge 
                            variant="outline" 
                            style={{ borderColor: CORES_CADERNO[item.caderno as keyof typeof CORES_CADERNO]?.cor }}
                          >
                            Caderno {item.caderno}
                          </Badge>
                          <span className="text-xs text-[var(--text-secondary)]">
                            Posição: {item.posicao}
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-2xl font-bold text-[var(--error)]">
                        b = {item.b}
                      </p>
                      <p className="text-xs text-[var(--text-secondary)]">
                        a = {item.a} | c = {item.c}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
