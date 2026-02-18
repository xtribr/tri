'use client';

import React from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  ReferenceLine,
} from 'recharts';
import type { ScoringResult } from '@/types';

interface ScoreDistributionProps {
  scores: ScoringResult[];
  height?: number;
}

export function ScoreDistribution({ scores, height = 300 }: ScoreDistributionProps) {
  // Calcular bins para theta (-4 a 4)
  const binWidth = 0.5;
  const bins: Record<string, number> = {};
  
  for (let i = -4; i <= 4; i += binWidth) {
    const label = `${i} - ${i + binWidth}`;
    bins[label] = 0;
  }
  
  // Distribuir scores nos bins
  scores.forEach((score) => {
    const binIndex = Math.floor((score.theta + 4) / binWidth);
    const start = -4 + binIndex * binWidth;
    const label = `${start} - ${start + binWidth}`;
    if (bins[label] !== undefined) {
      bins[label]++;
    }
  });

  const data = Object.entries(bins).map(([range, count]) => ({
    range,
    count,
    midpoint: parseFloat(range.split(' - ')[0]) + binWidth / 2,
  }));

  // Calcular estatísticas
  const thetas = scores.map(s => s.theta);
  const mean = thetas.reduce((a, b) => a + b, 0) / thetas.length;
  const sorted = [...thetas].sort((a, b) => a - b);
  const median = sorted[Math.floor(sorted.length / 2)];

  return (
    <ResponsiveContainer width="100%" height={height}>
      <BarChart data={data} margin={{ top: 20, right: 30, left: 20, bottom: 20 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" vertical={false} />
        <XAxis 
          dataKey="range" 
          tick={{ fontSize: 10 }}
          interval={1}
          angle={-45}
          textAnchor="end"
          height={60}
          stroke="var(--text-secondary)"
        />
        <YAxis 
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
          formatter={(value) => [`${value} candidatos`, 'Frequência']}
        />
        <ReferenceLine 
          x={`${mean} - ${mean + binWidth}`}
          stroke="#FF3B30" 
          strokeDasharray="5 5"
          label={{ value: 'Média', fill: '#FF3B30', fontSize: 10, position: 'top' }}
        />
        <ReferenceLine 
          x={`${median} - ${median + binWidth}`}
          stroke="#FF9500" 
          strokeDasharray="5 5"
          label={{ value: 'Mediana', fill: '#FF9500', fontSize: 10, position: 'bottom' }}
        />
        <Bar 
          dataKey="count" 
          fill="var(--primary)" 
          radius={[4, 4, 0, 0]}
          opacity={0.8}
        />
      </BarChart>
    </ResponsiveContainer>
  );
}
