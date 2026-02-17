'use client';

import React, { useState } from 'react';
import { useAppStore } from '@/lib/stores/appStore';
import { ICCCurve } from '@/components/charts/ICCCurve';
import { ScoreDistribution } from '@/components/charts/ScoreDistribution';
import { CandidateTable } from '@/components/dashboard/CandidateTable';
import { ENEMReferenceTable } from '@/components/dashboard/ENEMReferenceTable';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Users, 
  FileQuestion, 
  BarChart3, 
  Target,
  AlertCircle,
  Play,
  Download,
  RefreshCw,
  GraduationCap,
  Table2
} from 'lucide-react';
import Link from 'next/link';
import { calibrarItens, estimarEscores } from '@/lib/api/client';
import type { CalibrationResult, ScoringResult, CalibratedItem } from '@/types';
import type { ENEMArea } from '@/lib/utils/enemConversion';

// Dados mock para demonstração
const MOCK_ITEMS: CalibratedItem[] = [
  { cod: 'Q001', b: -1.5, a: 1.2, status: 'OK' },
  { cod: 'Q002', b: -0.8, a: 1.0, status: 'OK' },
  { cod: 'Q003', b: -0.2, a: 1.3, status: 'OK' },
  { cod: 'Q004', b: 0.5, a: 0.9, status: 'ATENCAO' },
  { cod: 'Q005', b: 1.2, a: 1.1, status: 'OK' },
  { cod: 'Q006', b: 1.8, a: 1.0, status: 'OK' },
];

export default function DashboardPage() {
  const upload = useAppStore((state) => state.upload);
  const preset = useAppStore((state) => state.preset);
  const modelo = useAppStore((state) => state.modelo);
  
  const [isLoading, setIsLoading] = useState(false);
  const [calibracao, setCalibracao] = useState<CalibrationResult | null>(null);
  const [escores, setEscores] = useState<ScoringResult[] | null>(null);
  const [erro, setErro] = useState<string | null>(null);
  const [enemArea, setEnemArea] = useState<ENEMArea>('CH');
  const [enemAno, setEnemAno] = useState<number>(2023);
  const [activeTab, setActiveTab] = useState('overview');

  const handleCalibrar = async () => {
    if (!upload) return;
    
    setIsLoading(true);
    setErro(null);
    
    try {
      // Chamar API real
      const result = await calibrarItens(upload.dados, modelo);
      setCalibracao(result);
      
      // Estimar escores individuais
      const scores = await estimarEscores(upload.dados, result.itens, 'EAP');
      setEscores(scores);
    } catch (error) {
      console.error('Erro na calibração:', error);
      setErro(error instanceof Error ? error.message : 'Erro desconhecido na calibração');
      
      // Fallback para mock em caso de erro
      setCalibracao({
        itens: MOCK_ITEMS,
        estatisticas_ajuste: {
          loglikelihood: -2500,
          aic: 5100,
          bic: 5300,
        },
        convergencia: true,
        iteracoes: 25,
      });
      
      // Gerar escores mock
      const mockScores: ScoringResult[] = upload.dados.map((row, i) => {
        const acertos = row.reduce((a, b) => a + b, 0);
        const theta = (acertos / row.length) * 6 - 3 + (Math.random() - 0.5);
        return {
          theta,
          erro_padrao: 0.3 + Math.random() * 0.2,
          ic_95: [theta - 0.6, theta + 0.6],
          metodo: 'EAP',
          respostas_consideradas: row.length,
        };
      });
      setEscores(mockScores);
    } finally {
      setIsLoading(false);
    }
  };

  if (!upload) {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="page-header">
          <h1 className="page-title">Dashboard</h1>
          <p className="page-subtitle">
            Visualização dos resultados da análise TRI
          </p>
        </div>
        
        <div className="glass-card p-8 text-center">
          <AlertCircle className="w-12 h-12 text-[var(--warning)] mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-[var(--text-primary)] mb-2">
            Nenhum dado carregado
          </h3>
          <Button className="btn-primary" asChild>
            <Link href="/upload">Ir para Upload</Link>
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto animate-fade-in">
      <div className="page-header flex items-end justify-between">
        <div>
          <h1 className="page-title">Dashboard</h1>
          <p className="page-subtitle">
            Resultados da análise psicométrica
            {preset && (
              <span className="ml-2">
                <Badge variant="secondary">{preset.tipo}</Badge>
                <Badge variant="outline" className="ml-1">{preset.modelo_padrao}</Badge>
              </span>
            )}
          </p>
        </div>
        <div className="flex gap-2">
          {!calibracao ? (
            <Button 
              className="btn-primary" 
              onClick={handleCalibrar}
              disabled={isLoading}
            >
              {isLoading ? (
                <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
              ) : (
                <Play className="w-4 h-4 mr-2" />
              )}
              {isLoading ? 'Calibrando...' : 'Iniciar Análise'}
            </Button>
          ) : (
            <>
              <Button variant="outline" onClick={handleCalibrar}>
                <RefreshCw className="w-4 h-4 mr-2" />
                Recalcular
              </Button>
              <Button variant="outline">
                <Download className="w-4 h-4 mr-2" />
                Exportar
              </Button>
            </>
          )}
        </div>
      </div>

      {erro && (
        <div className="mb-6 p-4 rounded-lg bg-[var(--warning)]/10 border border-[var(--warning)]/20 text-[var(--warning)]">
          <p className="text-sm font-medium">API não disponível. Mostrando dados simulados.</p>
          <p className="text-xs mt-1 opacity-80">{erro}</p>
        </div>
      )}

      {/* KPI Cards */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        <div className="kpi-card">
          <p className="kpi-label flex items-center gap-2">
            <Users className="w-4 h-4" />
            Candidatos
          </p>
          <p className="kpi-value">{upload.n_candidatos.toLocaleString()}</p>
        </div>
        <div className="kpi-card">
          <p className="kpi-label flex items-center gap-2">
            <FileQuestion className="w-4 h-4" />
            Itens
          </p>
          <p className="kpi-value">{upload.n_itens}</p>
        </div>
        <div className="kpi-card">
          <p className="kpi-label flex items-center gap-2">
            <BarChart3 className="w-4 h-4" />
            Média θ
          </p>
          <p className="kpi-value">
            {escores 
              ? (escores.reduce((a, s) => a + s.theta, 0) / escores.length).toFixed(2)
              : '-'
            }
          </p>
        </div>
        <div className="kpi-card">
          <p className="kpi-label flex items-center gap-2">
            <Target className="w-4 h-4" />
            Modelo
          </p>
          <p className="kpi-value text-2xl">{modelo}</p>
        </div>
      </div>

      {/* Tabs de conteúdo */}
      {calibracao && escores && (
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
          <TabsList className="grid w-full grid-cols-4 lg:w-auto lg:inline-flex">
            <TabsTrigger value="overview">
              <BarChart3 className="w-4 h-4 mr-2" />
              Visão Geral
            </TabsTrigger>
            <TabsTrigger value="candidates">
              <Table2 className="w-4 h-4 mr-2" />
              Candidatos ({escores.length})
            </TabsTrigger>
            <TabsTrigger value="enem">
              <GraduationCap className="w-4 h-4 mr-2" />
              ENEM
            </TabsTrigger>
            <TabsTrigger value="items">
              <FileQuestion className="w-4 h-4 mr-2" />
              Itens
            </TabsTrigger>
          </TabsList>

          {/* Tab: Visão Geral */}
          <TabsContent value="overview" className="space-y-6">
            <div className="grid grid-cols-2 gap-6">
              {/* ICC Curves */}
              <Card className="glass-card col-span-2">
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span>Curvas Características dos Itens (ICC)</span>
                    <Badge variant="secondary">
                      {calibracao.itens.length} itens calibrados
                    </Badge>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <ICCCurve items={calibracao.itens} height={400} />
                </CardContent>
              </Card>

              {/* Score Distribution */}
              <Card className="glass-card">
                <CardHeader>
                  <CardTitle>Distribuição de Habilidade (θ)</CardTitle>
                </CardHeader>
                <CardContent>
                  <ScoreDistribution scores={escores} height={300} />
                </CardContent>
              </Card>

              {/* Estatísticas de Ajuste */}
              <Card className="glass-card">
                <CardHeader>
                  <CardTitle>Estatísticas de Ajuste do Modelo</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-4 rounded-lg bg-[var(--bg-secondary)] text-center">
                      <p className="text-2xl font-bold text-[var(--primary)]">
                        {calibracao.estatisticas_ajuste.loglikelihood.toFixed(0)}
                      </p>
                      <p className="text-xs text-[var(--text-secondary)] mt-1">Log-Likelihood</p>
                    </div>
                    <div className="p-4 rounded-lg bg-[var(--bg-secondary)] text-center">
                      <p className="text-2xl font-bold text-[var(--primary)]">
                        {calibracao.estatisticas_ajuste.aic.toFixed(0)}
                      </p>
                      <p className="text-xs text-[var(--text-secondary)] mt-1">AIC</p>
                    </div>
                    <div className="p-4 rounded-lg bg-[var(--bg-secondary)] text-center">
                      <p className="text-2xl font-bold text-[var(--primary)]">
                        {calibracao.estatisticas_ajuste.bic.toFixed(0)}
                      </p>
                      <p className="text-xs text-[var(--text-secondary)] mt-1">BIC</p>
                    </div>
                    <div className="p-4 rounded-lg bg-[var(--bg-secondary)] text-center">
                      <p className="text-2xl font-bold text-[calibracao.convergencia ? 'var(--success)' : 'var(--error)']">
                        {calibracao.iteracoes}
                      </p>
                      <p className="text-xs text-[var(--text-secondary)] mt-1">
                        Iterações
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          {/* Tab: Candidatos */}
          <TabsContent value="candidates">
            <Card className="glass-card">
              <CardHeader>
                <CardTitle>Escores TRI por Candidato</CardTitle>
              </CardHeader>
              <CardContent>
                <CandidateTable
                  candidatos={upload.candidatos}
                  respostas={upload.dados}
                  escores={escores}
                  itens={calibracao.itens}
                  area={enemArea}
                  anoENEM={enemAno}
                  mostrarENEM={preset?.tipo === 'ENEM'}
                />
              </CardContent>
            </Card>
          </TabsContent>

          {/* Tab: ENEM */}
          <TabsContent value="enem">
            <div className="grid grid-cols-2 gap-6">
              <ENEMReferenceTable
                area={enemArea}
                ano={enemAno}
                onAreaChange={setEnemArea}
                onAnoChange={setEnemAno}
              />
              <Card className="glass-card">
                <CardHeader>
                  <CardTitle>Conversão de Theta para ENEM</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <p className="text-sm text-[var(--text-secondary)]">
                      A conversão é feita em dois passos:
                    </p>
                    <ol className="text-sm text-[var(--text-secondary)] space-y-2 list-decimal list-inside">
                      <li>
                        <strong>Theta → Acertos Esperados:</strong> Soma das probabilidades 
                        de acerto dadas pelo modelo TRI
                      </li>
                      <li>
                        <strong>Acertos → Nota ENEM:</strong> Interpolação linear na tabela 
                        de referência do INEP
                      </li>
                    </ol>
                    <div className="p-4 rounded-lg bg-[var(--bg-secondary)] text-sm">
                      <p className="font-medium text-[var(--text-primary)] mb-2">
                        Fórmula da Probabilidade (3PL):
                      </p>
                      <p className="font-mono text-[var(--text-secondary)]">
                        P(θ) = c + (1-c) / (1 + e^(-a(θ-b)))
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          </TabsContent>

          {/* Tab: Itens */}
          <TabsContent value="items">
            <Card className="glass-card">
              <CardHeader>
                <CardTitle>Parâmetros dos Itens Calibrados</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
                  {calibracao.itens.map((item) => (
                    <div 
                      key={item.cod}
                      className="p-4 rounded-lg bg-[var(--bg-secondary)] border border-[var(--border-light)]"
                    >
                      <div className="flex items-center justify-between mb-3">
                        <span className="font-mono font-bold text-[var(--text-primary)]">
                          {item.cod}
                        </span>
                        {item.status && (
                          <Badge 
                            variant={item.status === 'OK' ? 'default' : 'secondary'}
                            className="text-xs"
                          >
                            {item.status}
                          </Badge>
                        )}
                      </div>
                      <div className="space-y-1 text-sm">
                        <div className="flex justify-between">
                          <span className="text-[var(--text-tertiary)]">Dificuldade (b)</span>
                          <span className="font-mono font-medium">{item.b.toFixed(3)}</span>
                        </div>
                        {item.a && (
                          <div className="flex justify-between">
                            <span className="text-[var(--text-tertiary)]">Discriminação (a)</span>
                            <span className="font-mono">{item.a.toFixed(3)}</span>
                          </div>
                        )}
                        {item.c && (
                          <div className="flex justify-between">
                            <span className="text-[var(--text-tertiary)]">Acerto ao acaso (c)</span>
                            <span className="font-mono">{item.c.toFixed(3)}</span>
                          </div>
                        )}
                        {item.infit && (
                          <div className="flex justify-between">
                            <span className="text-[var(--text-tertiary)]">INFIT</span>
                            <span className={`font-mono ${
                              item.infit >= 0.7 && item.infit <= 1.3 
                                ? 'text-[var(--success)]' 
                                : 'text-[var(--warning)]'
                            }`}>
                              {item.infit.toFixed(2)}
                            </span>
                          </div>
                        )}
                        {item.outfit && (
                          <div className="flex justify-between">
                            <span className="text-[var(--text-tertiary)]">OUTFIT</span>
                            <span className={`font-mono ${
                              item.outfit >= 0.7 && item.outfit <= 1.3 
                                ? 'text-[var(--success)]' 
                                : 'text-[var(--warning)]'
                            }`}>
                              {item.outfit.toFixed(2)}
                            </span>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      )}

      {!calibracao && !isLoading && (
        <div className="text-center py-16">
          <BarChart3 className="w-16 h-16 text-[var(--border-medium)] mx-auto mb-4" />
          <h3 className="text-lg font-medium text-[var(--text-secondary)]">
            Clique em "Iniciar Análise" para calibrar os itens e estimar escores
          </h3>
        </div>
      )}
    </div>
  );
}
