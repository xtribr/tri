'use client';

import React from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import type { CalibratedItem } from '@/types';

interface ICCCurveProps {
  items: CalibratedItem[];
  selectedItems?: string[];
  height?: number;
}

// Função para calcular probabilidade de acerto (modelo 3PL)
function probabilidadeAcerto(theta: number, a: number, b: number, c: number): number {
  const exponent = -a * (theta - b);
  return c + (1 - c) / (1 + Math.exp(exponent));
}

export function ICCCurve({ items, selectedItems, height = 400 }: ICCCurveProps) {
  // Gerar pontos no eixo theta (-4 a 4)
  const thetaRange = Array.from({ length: 81 }, (_, i) => -4 + i * 0.1);
  
  // Preparar dados para o gráfico
  const data = thetaRange.map((theta) => {
    const point: Record<string, number> = { theta };
    
    items.forEach((item) => {
      const a = item.a ?? 1;
      const b = item.b;
      const c = item.c ?? 0;
      
      point[item.cod] = probabilidadeAcerto(theta, a, b, c);
    });
    
    return point;
  });

  // Cores para as curvas
  const colors = [
    '#0071E3', '#34C759', '#FF9500', '#FF3B30', '#5856D6',
    '#AF52DE', '#FF2D55', '#5AC8FA', '#FFCC00', '#A2845E',
  ];

  // Filtrar itens se necessário
  const displayItems = selectedItems 
    ? items.filter(i => selectedItems.includes(i.cod))
    : items.slice(0, 5); // Mostrar apenas os primeiros 5 por padrão

  return (
    <ResponsiveContainer width="100%" height={height}>
      <LineChart data={data} margin={{ top: 20, right: 30, left: 20, bottom: 20 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
        <XAxis 
          dataKey="theta" 
          type="number"
          scale="linear"
          domain={[-4, 4]}
          tickCount={9}
          label={{ value: 'Habilidade (θ)', position: 'insideBottom', offset: -10 }}
          stroke="var(--text-secondary)"
          fontSize={12}
        />
        <YAxis 
          domain={[0, 1]} 
          tickCount={6}
          tickFormatter={(v) => `${v * 100}%`}
          label={{ value: 'Probabilidade de Acerto', angle: -90, position: 'insideLeft' }}
          stroke="var(--text-secondary)"
          fontSize={12}
        />
        <Tooltip 
          contentStyle={{
            backgroundColor: 'var(--bg-primary)',
            border: '1px solid var(--border-light)',
            borderRadius: 'var(--radius-md)',
            fontSize: 12,
          }}
          formatter={(value) => [`${Number(value) * 100}%`, 'Probabilidade']}
          labelFormatter={(label) => `θ = ${Number(label)}`}
        />
        <Legend 
          wrapperStyle={{ fontSize: 12 }}
        />
        
        {displayItems.map((item, idx) => (
          <Line
            key={item.cod}
            type="monotone"
            dataKey={item.cod}
            stroke={colors[idx % colors.length]}
            strokeWidth={2}
            dot={false}
            name={`${item.cod} (b=${item.b})`}
          />
        ))}
      </LineChart>
    </ResponsiveContainer>
  );
}
