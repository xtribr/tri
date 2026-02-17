'use client';

import React from 'react';
import { FileUpload } from '@/components/upload/FileUpload';
import { useAppStore } from '@/lib/stores/appStore';
import { Button } from '@/components/ui/button';
import { ArrowRight, Database, Settings } from 'lucide-react';
import Link from 'next/link';

export default function UploadPage() {
  const upload = useAppStore((state) => state.upload);
  const preset = useAppStore((state) => state.preset);
  
  return (
    <div className="max-w-4xl mx-auto animate-fade-in">
      <div className="page-header">
        <h1 className="page-title">Upload de Dados</h1>
        <p className="page-subtitle">
          Carregue o arquivo CSV com as respostas dos candidatos para iniciar a análise TRI.
        </p>
      </div>

      <div className="grid gap-8">
        {/* Upload Component */}
        <section className="glass-card p-8">
          <FileUpload />
        </section>

        {/* Quick Stats */}
        {upload && (
          <section className="grid grid-cols-3 gap-4 animate-fade-in">
            <div className="kpi-card">
              <p className="kpi-label">Candidatos</p>
              <p className="kpi-value">{upload.n_candidatos.toLocaleString()}</p>
            </div>
            <div className="kpi-card">
              <p className="kpi-label">Itens</p>
              <p className="kpi-value">{upload.n_itens}</p>
            </div>
            <div className="kpi-card">
              <p className="kpi-label">Média de Acertos</p>
              <p className="kpi-value">{upload.media_acertos.toFixed(1)}%</p>
            </div>
          </section>
        )}

        {/* Next Steps */}
        {upload && (
          <section className="glass-card p-6 animate-fade-in">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-lg font-semibold text-[var(--text-primary)]">
                  Dados carregados com sucesso
                </h3>
                <p className="text-sm text-[var(--text-secondary)] mt-1">
                  {preset 
                    ? `Configuração selecionada: ${preset.tipo} - ${preset.modelo_padrao}`
                    : 'Selecione uma configuração de análise para continuar'
                  }
                </p>
              </div>
              <div className="flex gap-3">
                <Button variant="outline" asChild>
                  <Link href="/analysis">
                    <Settings className="w-4 h-4 mr-2" />
                    Configurar
                  </Link>
                </Button>
                <Button className="btn-primary" asChild>
                  <Link href="/dashboard">
                    Ver Dashboard
                    <ArrowRight className="w-4 h-4 ml-2" />
                  </Link>
                </Button>
              </div>
            </div>
          </section>
        )}

        {/* Info Cards */}
        {!upload && (
          <section className="grid grid-cols-2 gap-6">
            <div className="p-6 rounded-xl bg-[var(--bg-secondary)] border border-[var(--border-light)]">
              <Database className="w-8 h-8 text-[var(--primary)] mb-3" />
              <h3 className="font-semibold text-[var(--text-primary)] mb-2">
                Formatos Suportados
              </h3>
              <ul className="text-sm text-[var(--text-secondary)] space-y-1">
                <li>• CSV com separador vírgula ou ponto-e-vírgula</li>
                <li>• Colunas: nome, email, Q1, Q2... (valores 0 ou 1)</li>
                <li>• Mínimo recomendado: 100 candidatos</li>
              </ul>
            </div>
            <div className="p-6 rounded-xl bg-[var(--bg-secondary)] border border-[var(--border-light)]">
              <Settings className="w-8 h-8 text-[var(--primary)] mb-3" />
              <h3 className="font-semibold text-[var(--text-primary)] mb-2">
                Modelos Disponíveis
              </h3>
              <ul className="text-sm text-[var(--text-secondary)] space-y-1">
                <li>• <strong>Rasch (1PL):</strong> Dificuldade apenas</li>
                <li>• <strong>2PL:</strong> Dificuldade + Discriminação</li>
                <li>• <strong>3PL:</strong> + Acerto ao acaso (ENEM)</li>
              </ul>
            </div>
          </section>
        )}
      </div>
    </div>
  );
}
