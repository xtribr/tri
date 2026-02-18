'use client';

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { AlertTriangle, Info, FileText } from 'lucide-react';
import { Button } from '@/components/ui/button';
import Link from 'next/link';

export default function Tabela2024Page() {
  return (
    <div className="max-w-4xl mx-auto animate-fade-in">
      <div className="page-header">
        <h1 className="page-title">Tabela de Conversão ENEM 2024</h1>
        <p className="page-subtitle">
          Dados oficiais do INEP
        </p>
      </div>

      <Card className="glass-card border-[var(--warning)]">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-[var(--warning)]">
            <AlertTriangle className="w-6 h-6" />
            Dados Não Disponíveis
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="p-4 rounded-lg bg-[var(--warning)]/10 border border-[var(--warning)]/20">
            <p className="text-lg font-medium text-[var(--text-primary)] mb-2">
              O INEP não publica a tabela completa MIN/MED/MAX por número de acertos.
            </p>
            <p className="text-[var(--text-secondary)]">
              O que temos são estatísticas agregadas (média, desvio padrão) e 
              tabelas históricas de anos anteriores (2009, 2015-2023).
            </p>
          </div>

          <div className="space-y-4">
            <h3 className="font-semibold flex items-center gap-2">
              <Info className="w-5 h-5 text-[var(--primary)]" />
              O que está disponível:
            </h3>
            
            <ul className="space-y-2 text-[var(--text-secondary)]">
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-[var(--primary)] mt-2" />
                Estatísticas descritivas: média, mediana, DP, percentis
              </li>
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-[var(--primary)] mt-2" />
                Tabelas históricas 2009, 2015-2023 (oficiais do INEP)
              </li>
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-[var(--primary)] mt-2" />
                Microdados completos para análise estatística
              </li>
            </ul>
          </div>

          <div className="flex gap-4 pt-4">
            <Button className="btn-primary" asChild>
              <Link href="/tabela">
                <FileText className="w-4 h-4 mr-2" />
                Ver Tabelas Históricas
              </Link>
            </Button>
            
            <Button variant="outline" asChild>
              <Link href="/dashboard">
                Ver Estatísticas 2024
              </Link>
            </Button>
          </div>

          <div className="text-sm text-[var(--text-tertiary)] pt-4 border-t border-[var(--border-light)]">
            <p>
              Nota: Qualquer tabela MIN/MED/MAX completa para 2024 seria uma 
              estimativa não oficial. Recomendamos usar os dados históricos ou 
              as estatísticas agregadas fornecidas pelo INEP.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
