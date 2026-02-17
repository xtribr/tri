'use client';

import React, { useState } from 'react';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { TrendingUp, TrendingDown, BookOpen } from 'lucide-react';
import { getTabelaInfo, getAnosDisponiveis, ENEMArea, acertosParaNotaENEM } from '@/lib/utils/enemConversion';

interface ENEMReferenceTableProps {
  area?: ENEMArea;
  ano?: number;
  onAreaChange?: (area: ENEMArea) => void;
  onAnoChange?: (ano: number) => void;
}

export function ENEMReferenceTable({
  area = 'CH',
  ano = 2023,
  onAreaChange,
  onAnoChange,
}: ENEMReferenceTableProps) {
  const [selectedArea, setSelectedArea] = useState<ENEMArea>(area);
  const [selectedAno, setSelectedAno] = useState<number>(ano);
  
  const anos = getAnosDisponiveis();
  const areas: ENEMArea[] = ['CH', 'CN', 'LC', 'MT'];
  
  const tabelaInfo = getTabelaInfo(selectedAno, selectedArea);
  
  const handleAreaChange = (value: ENEMArea) => {
    setSelectedArea(value);
    onAreaChange?.(value);
  };
  
  const handleAnoChange = (value: string) => {
    const ano = parseInt(value);
    setSelectedAno(ano);
    onAnoChange?.(ano);
  };

  if (!tabelaInfo) {
    return (
      <Card className="glass-card">
        <CardContent className="p-8 text-center text-[var(--text-secondary)]">
          Tabela não disponível para {selectedArea} {selectedAno}
        </CardContent>
      </Card>
    );
  }

  const tabela = tabelaInfo.tabela_completa;
  
  // Calcular algumas estatísticas (filtrando nulls)
  const notasMed = tabela.map(r => r.notaMed).filter((n): n is number => n !== null);
  const notasMax = tabela.map(r => r.notaMax).filter((n): n is number => n !== null);
  const notasMin = tabela.map(r => r.notaMin).filter((n): n is number => n !== null);
  const mediaGeral = notasMed.reduce((a, b) => a + b, 0) / (notasMed.length || 1);
  const notaMaxima = notasMax.length > 0 ? Math.max(...notasMax) : 1000;
  const notaMinima = notasMin.length > 0 ? Math.min(...notasMin) : 300;

  return (
    <Card className="glass-card">
      <CardHeader>
        <div className="flex items-start justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <BookOpen className="w-5 h-5 text-[var(--primary)]" />
              Tabela de Conversão ENEM
            </CardTitle>
            <p className="text-sm text-[var(--text-secondary)] mt-1">
              Escala de {notaMinima.toFixed(0)} a {notaMaxima.toFixed(0)} pontos
            </p>
          </div>
          <div className="flex gap-2">
            <Select value={selectedArea} onValueChange={handleAreaChange}>
              <SelectTrigger className="w-24">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {areas.map(a => (
                  <SelectItem key={a} value={a}>{a}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select value={selectedAno.toString()} onValueChange={handleAnoChange}>
              <SelectTrigger className="w-28">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {anos.map(a => (
                  <SelectItem key={a} value={a.toString()}>{a}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {/* Estatísticas rápidas */}
        <div className="grid grid-cols-4 gap-4 mb-4">
          <div className="p-3 rounded-lg bg-[var(--bg-secondary)] text-center">
            <p className="text-2xl font-bold text-[var(--primary)]">{tabelaInfo.n_itens}</p>
            <p className="text-xs text-[var(--text-secondary)]">Itens</p>
          </div>
          <div className="p-3 rounded-lg bg-[var(--bg-secondary)] text-center">
            <p className="text-2xl font-bold text-[var(--primary)]">{mediaGeral.toFixed(0)}</p>
            <p className="text-xs text-[var(--text-secondary)]">Média</p>
          </div>
          <div className="p-3 rounded-lg bg-[var(--bg-secondary)] text-center">
            <p className="text-2xl font-bold text-[var(--success)]">{notaMaxima.toFixed(0)}</p>
            <p className="text-xs text-[var(--text-secondary)]">Máxima</p>
          </div>
          <div className="p-3 rounded-lg bg-[var(--bg-secondary)] text-center">
            <p className="text-2xl font-bold text-[var(--error)]">{notaMinima.toFixed(0)}</p>
            <p className="text-xs text-[var(--text-secondary)]">Mínima</p>
          </div>
        </div>

        {/* Tabela de conversão */}
        <ScrollArea className="h-[400px]">
          <Table>
            <TableHeader className="sticky top-0 bg-[var(--bg-secondary)] z-10">
              <TableRow>
                <TableHead className="text-right">Acertos</TableHead>
                <TableHead className="text-right text-[var(--error)]">
                  <TrendingDown className="w-4 h-4 inline mr-1" />
                  Mínima
                </TableHead>
                <TableHead className="text-right text-[var(--primary)] font-bold">
                  Média
                </TableHead>
                <TableHead className="text-right text-[var(--success)]">
                  <TrendingUp className="w-4 h-4 inline mr-1" />
                  Máxima
                </TableHead>
                <TableHead className="text-right">Amplitude</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {tabela.map((row) => {
                const notaMin = row.notaMin ?? 0;
                const notaMed = row.notaMed ?? 500;
                const notaMax = row.notaMax ?? 1000;
                const amplitude = notaMax - notaMin;
                return (
                  <TableRow key={row.acertos} className="hover:bg-[var(--bg-tertiary)]">
                    <TableCell className="text-right font-mono font-medium">
                      {row.acertos}
                    </TableCell>
                    <TableCell className="text-right font-mono text-[var(--text-secondary)]">
                      {notaMin.toFixed(1)}
                    </TableCell>
                    <TableCell className="text-right font-mono font-bold text-[var(--primary)]">
                      {notaMed.toFixed(1)}
                    </TableCell>
                    <TableCell className="text-right font-mono text-[var(--text-secondary)]">
                      {notaMax.toFixed(1)}
                    </TableCell>
                    <TableCell className="text-right">
                      <Badge variant={amplitude > 100 ? 'destructive' : amplitude > 50 ? 'secondary' : 'outline'} className="font-mono text-xs">
                        ±{((notaMax - notaMed)).toFixed(0)}
                      </Badge>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </ScrollArea>
      </CardContent>
    </Card>
  );
}
