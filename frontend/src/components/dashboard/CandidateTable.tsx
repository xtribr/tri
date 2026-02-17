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
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Download, Search, ChevronLeft, ChevronRight } from 'lucide-react';
import type { ScoringResult, CalibratedItem } from '@/types';
import { thetaParaNotaENEM, acertosParaNotaENEM, ENEMArea } from '@/lib/utils/enemConversion';

interface CandidateTableProps {
  candidatos: string[];
  respostas: number[][];
  escores: ScoringResult[];
  itens: CalibratedItem[];
  area?: ENEMArea;
  anoENEM?: number;
  mostrarENEM?: boolean;
}

const ITEMS_PER_PAGE = 50;

export function CandidateTable({
  candidatos,
  respostas,
  escores,
  itens,
  area = 'CH',
  anoENEM = 2023,
  mostrarENEM = true,
}: CandidateTableProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);

  // Preparar dados combinados
  const dados = candidatos.map((nome, idx) => {
    const escore = escores[idx];
    const resposta = respostas[idx];
    const acertos = resposta.filter(r => r === 1).length;
    const taxaAcerto = (acertos / resposta.length) * 100;
    
    // Calcular notas ENEM se solicitado
    let notaENEM: { min: number; med: number; max: number } | null = null;
    if (mostrarENEM && escore) {
      const acertosExp = thetaParaAcertosEsperados(escore.theta, itens);
      notaENEM = {
        min: acertosParaNotaENEM(acertosExp, anoENEM, area, 'min'),
        med: acertosParaNotaENEM(acertosExp, anoENEM, area, 'med'),
        max: acertosParaNotaENEM(acertosExp, anoENEM, area, 'max'),
      };
    }
    
    return {
      id: idx + 1,
      nome,
      acertos,
      total: resposta.length,
      taxaAcerto,
      theta: escore?.theta ?? 0,
      erroPadrao: escore?.erro_padrao ?? 0,
      ic95: escore?.ic_95 ?? [0, 0],
      notaENEM,
    };
  });

  // Filtrar por busca
  const filtered = dados.filter(d => 
    d.nome.toLowerCase().includes(searchTerm.toLowerCase()) ||
    d.id.toString().includes(searchTerm)
  );

  // Paginação
  const totalPages = Math.ceil(filtered.length / ITEMS_PER_PAGE);
  const start = (currentPage - 1) * ITEMS_PER_PAGE;
  const paginated = filtered.slice(start, start + ITEMS_PER_PAGE);

  // Exportar CSV
  const exportCSV = () => {
    const headers = ['ID', 'Nome', 'Acertos', 'Total', 'Taxa_Acerto', 'Theta', 'Erro_Padrao', 'IC_95_Lower', 'IC_95_Upper'];
    if (mostrarENEM) {
      headers.push('ENEM_MIN', 'ENEM_MED', 'ENEM_MAX');
    }
    
    const rows = filtered.map(d => [
      d.id,
      d.nome,
      d.acertos,
      d.total,
      d.taxaAcerto.toFixed(2),
      d.theta.toFixed(3),
      d.erroPadrao.toFixed(3),
      d.ic95[0].toFixed(3),
      d.ic95[1].toFixed(3),
      ...(mostrarENEM && d.notaENEM ? [
        d.notaENEM.min.toFixed(1),
        d.notaENEM.med.toFixed(1),
        d.notaENEM.max.toFixed(1),
      ] : []),
    ]);
    
    const csv = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `escores_tri_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
  };

  // Helpers
  function thetaParaAcertosEsperados(theta: number, itens: CalibratedItem[]): number {
    return itens.reduce((sum, item) => {
      const a = item.a ?? 1;
      const b = item.b;
      const c = item.c ?? 0;
      const exponent = -a * (theta - b);
      return sum + (c + (1 - c) / (1 + Math.exp(exponent)));
    }, 0);
  }

  return (
    <div className="space-y-4">
      {/* Header com busca e export */}
      <div className="flex items-center justify-between gap-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[var(--text-tertiary)]" />
          <Input
            placeholder="Buscar candidato..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-9"
          />
        </div>
        <div className="flex items-center gap-2 text-sm text-[var(--text-secondary)]">
          <span>{filtered.length} candidatos</span>
          <Button variant="outline" size="sm" onClick={exportCSV}>
            <Download className="w-4 h-4 mr-2" />
            Exportar CSV
          </Button>
        </div>
      </div>

      {/* Tabela */}
      <div className="rounded-lg border border-[var(--border-light)] overflow-hidden">
        <ScrollArea className="h-[500px]">
          <Table>
            <TableHeader className="sticky top-0 bg-[var(--bg-secondary)] z-10">
              <TableRow>
                <TableHead className="w-12">#</TableHead>
                <TableHead>Candidato</TableHead>
                <TableHead className="text-right">Acertos</TableHead>
                <TableHead className="text-right">Taxa</TableHead>
                <TableHead className="text-right">Theta (θ)</TableHead>
                <TableHead className="text-right">Erro</TableHead>
                <TableHead className="text-right">IC 95%</TableHead>
                {mostrarENEM && (
                  <TableHead className="text-right">
                    Nota ENEM ({anoENEM})
                    <span className="block text-xs font-normal text-[var(--text-tertiary)]">
                      MIN / MED / MAX
                    </span>
                  </TableHead>
                )}
                <TableHead className="text-center">Nível</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {paginated.map((d) => (
                <TableRow key={d.id} className="hover:bg-[var(--bg-tertiary)]">
                  <TableCell className="font-mono text-xs text-[var(--text-tertiary)]">
                    {d.id}
                  </TableCell>
                  <TableCell className="font-medium max-w-[200px] truncate" title={d.nome}>
                    {d.nome}
                  </TableCell>
                  <TableCell className="text-right font-mono">
                    {d.acertos}/{d.total}
                  </TableCell>
                  <TableCell className="text-right">
                    <span className={`font-mono ${
                      d.taxaAcerto >= 70 ? 'text-[var(--success)]' :
                      d.taxaAcerto >= 50 ? 'text-[var(--warning)]' :
                      'text-[var(--error)]'
                    }`}>
                      {d.taxaAcerto.toFixed(1)}%
                    </span>
                  </TableCell>
                  <TableCell className="text-right font-mono font-medium">
                    {d.theta.toFixed(3)}
                  </TableCell>
                  <TableCell className="text-right font-mono text-[var(--text-secondary)]">
                    ±{d.erroPadrao.toFixed(3)}
                  </TableCell>
                  <TableCell className="text-right font-mono text-xs text-[var(--text-secondary)]">
                    [{d.ic95[0].toFixed(2)}, {d.ic95[1].toFixed(2)}]
                  </TableCell>
                  {mostrarENEM && d.notaENEM && (
                    <TableCell className="text-right">
                      <div className="flex items-center justify-end gap-1 font-mono text-sm">
                        <span className="text-[var(--text-tertiary)]">{d.notaENEM.min.toFixed(0)}</span>
                        <span className="text-[var(--text-secondary)]">/</span>
                        <span className="font-bold text-[var(--primary)]">{d.notaENEM.med.toFixed(0)}</span>
                        <span className="text-[var(--text-secondary)]">/</span>
                        <span className="text-[var(--text-tertiary)]">{d.notaENEM.max.toFixed(0)}</span>
                      </div>
                    </TableCell>
                  )}
                  <TableCell className="text-center">
                    <Badge variant={
                      d.theta > 1 ? 'default' :
                      d.theta > -0.5 ? 'secondary' :
                      'outline'
                    } className="text-xs">
                      {d.theta > 1 ? 'Avançado' :
                       d.theta > -0.5 ? 'Intermediário' :
                       'Básico'}
                    </Badge>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </ScrollArea>
      </div>

      {/* Paginação */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
            disabled={currentPage === 1}
          >
            <ChevronLeft className="w-4 h-4 mr-2" />
            Anterior
          </Button>
          <span className="text-sm text-[var(--text-secondary)]">
            Página {currentPage} de {totalPages}
          </span>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
            disabled={currentPage === totalPages}
          >
            Próxima
            <ChevronRight className="w-4 h-4 ml-2" />
          </Button>
        </div>
      )}
    </div>
  );
}
