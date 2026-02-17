'use client';

import React, { useState } from 'react';
import { useAppStore } from '@/lib/stores/appStore';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Separator } from '@/components/ui/separator';
import { Badge } from '@/components/ui/badge';
import { 
  Calculator, 
  Brain, 
  GraduationCap, 
  Stethoscope, 
  Settings,
  Play,
  AlertCircle,
  CheckCircle2
} from 'lucide-react';
import Link from 'next/link';
import type { TRIModel, ExamType } from '@/types';

const PRESETS = [
  {
    id: 'ENAMED' as ExamType,
    name: 'ENAMED/ENARE',
    description: 'Exame Nacional de Avaliação Médica',
    icon: Stethoscope,
    defaultModel: 'Rasch' as TRIModel,
    areas: ['Cirurgia', 'Ginecologia', 'Pediatria', 'Clínica Médica', 'Preventiva'],
    color: '#0071E3',
  },
  {
    id: 'ENEM' as ExamType,
    name: 'ENEM',
    description: 'Exame Nacional do Ensino Médio',
    icon: GraduationCap,
    defaultModel: '3PL_ENEM' as TRIModel,
    areas: ['CH', 'CN', 'LC', 'MT'],
    color: '#34C759',
  },
  {
    id: 'SAEB' as ExamType,
    name: 'SAEB',
    description: 'Sistema de Avaliação da Educação Básica',
    icon: Brain,
    defaultModel: 'Rasch' as TRIModel,
    areas: ['Português', 'Matemática'],
    color: '#FF9500',
  },
  {
    id: 'CUSTOM' as ExamType,
    name: 'Personalizado',
    description: 'Configure manualmente os parâmetros',
    icon: Settings,
    defaultModel: '2PL' as TRIModel,
    areas: [],
    color: '#5856D6',
  },
];

const MODELS: { value: TRIModel; label: string; description: string }[] = [
  { 
    value: 'Rasch', 
    label: 'Rasch (1PL)', 
    description: 'Apenas parâmetro de dificuldade (b). Modelo mais simples e robusto.' 
  },
  { 
    value: '2PL', 
    label: '2PL', 
    description: 'Dificuldade (b) + Discriminação (a). Maior flexibilidade.' 
  },
  { 
    value: '3PL', 
    label: '3PL', 
    description: 'Adiciona parâmetro de acerto ao acaso (c). Para múltipla escolha.' 
  },
  { 
    value: '3PL_ENEM', 
    label: '3PL (ENEM)', 
    description: '3PL com prior Beta(4,16) para c. Especificação INEP.' 
  },
];

export default function AnalysisPage() {
  const upload = useAppStore((state) => state.upload);
  const preset = useAppStore((state) => state.preset);
  const setPreset = useAppStore((state) => state.setPreset);
  const setModelo = useAppStore((state) => state.setModelo);
  
  const [selectedPreset, setSelectedPreset] = useState<ExamType>(preset?.tipo || 'ENAMED');
  const [selectedModel, setSelectedModel] = useState<TRIModel>(preset?.modelo_padrao || 'Rasch');
  const [showAdvanced, setShowAdvanced] = useState(false);

  const handleApply = () => {
    const presetConfig = PRESETS.find(p => p.id === selectedPreset);
    if (presetConfig) {
      setPreset({
        tipo: selectedPreset,
        modelo_padrao: selectedModel,
        metodo_scoring: 'EAP',
        n_itens: upload?.n_itens || 0,
        areas: presetConfig.areas,
      });
      setModelo(selectedModel);
    }
  };

  if (!upload) {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="page-header">
          <h1 className="page-title">Configuração da Análise</h1>
          <p className="page-subtitle">
            Selecione o modelo TRI e parâmetros de calibração
          </p>
        </div>
        
        <div className="glass-card p-8 text-center">
          <AlertCircle className="w-12 h-12 text-[var(--warning)] mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-[var(--text-primary)] mb-2">
            Nenhum dado carregado
          </h3>
          <p className="text-[var(--text-secondary)] mb-4">
            Você precisa carregar os dados de respostas antes de configurar a análise.
          </p>
          <Button className="btn-primary" asChild>
            <Link href="/upload">Ir para Upload</Link>
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto animate-fade-in">
      <div className="page-header">
        <h1 className="page-title">Configuração da Análise</h1>
        <p className="page-subtitle">
          Selecione o preset e modelo TRI apropriados para seus dados
        </p>
      </div>

      <div className="grid gap-6">
        {/* Preset Selection */}
        <Card className="glass-card">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calculator className="w-5 h-5 text-[var(--primary)]" />
              Selecione o Tipo de Exame
            </CardTitle>
          </CardHeader>
          <CardContent>
            <RadioGroup 
              value={selectedPreset} 
              onValueChange={(v) => {
                setSelectedPreset(v as ExamType);
                const preset = PRESETS.find(p => p.id === v);
                if (preset) setSelectedModel(preset.defaultModel);
              }}
              className="grid grid-cols-2 gap-4"
            >
              {PRESETS.map((p) => (
                <div key={p.id}>
                  <RadioGroupItem 
                    value={p.id} 
                    id={p.id}
                    className="peer sr-only"
                  />
                  <label
                    htmlFor={p.id}
                    className="flex flex-col p-4 rounded-lg border-2 border-[var(--border-light)] cursor-pointer transition-all hover:border-[var(--primary)] peer-data-[state=checked]:border-[var(--primary)] peer-data-[state=checked]:bg-[var(--primary-light)]"
                  >
                    <div className="flex items-start gap-3">
                      <div 
                        className="w-10 h-10 rounded-lg flex items-center justify-center"
                        style={{ backgroundColor: `${p.color}15` }}
                      >
                        <p.icon className="w-5 h-5" style={{ color: p.color }} />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-[var(--text-primary)]">
                            {p.name}
                          </span>
                          {preset?.tipo === p.id && (
                            <CheckCircle2 className="w-4 h-4 text-[var(--success)]" />
                          )}
                        </div>
                        <p className="text-sm text-[var(--text-secondary)]">
                          {p.description}
                        </p>
                        {p.areas.length > 0 && (
                          <div className="flex flex-wrap gap-1 mt-2">
                            {p.areas.map(area => (
                              <Badge key={area} variant="secondary" className="text-xs">
                                {area}
                              </Badge>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                  </label>
                </div>
              ))}
            </RadioGroup>
          </CardContent>
        </Card>

        {/* Model Selection */}
        <Card className="glass-card">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Brain className="w-5 h-5 text-[var(--primary)]" />
              Modelo Estatístico
            </CardTitle>
          </CardHeader>
          <CardContent>
            <Select 
              value={selectedModel} 
              onValueChange={(v) => setSelectedModel(v as TRIModel)}
            >
              <SelectTrigger className="w-full">
                <SelectValue placeholder="Selecione o modelo TRI" />
              </SelectTrigger>
              <SelectContent>
                {MODELS.map((m) => (
                  <SelectItem key={m.value} value={m.value}>
                    <div className="flex flex-col items-start">
                      <span className="font-medium">{m.label}</span>
                      <span className="text-xs text-[var(--text-secondary)]">
                        {m.description}
                      </span>
                    </div>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            
            <div className="mt-4 p-4 rounded-lg bg-[var(--bg-secondary)]">
              <h4 className="text-sm font-medium text-[var(--text-primary)] mb-2">
                Parâmetros do Modelo
              </h4>
              <div className="grid grid-cols-3 gap-4 text-sm">
                <div>
                  <span className="text-[var(--text-tertiary)]">a (Discriminação)</span>
                  <p className="font-mono text-[var(--text-primary)]">
                    {selectedModel === 'Rasch' ? 'Fixo = 1.0' : 'Estimado'}
                  </p>
                </div>
                <div>
                  <span className="text-[var(--text-tertiary)]">b (Dificuldade)</span>
                  <p className="font-mono text-[var(--text-primary)]">Estimado</p>
                </div>
                <div>
                  <span className="text-[var(--text-tertiary)]">c (Acerto ao acaso)</span>
                  <p className="font-mono text-[var(--text-primary)]">
                    {selectedModel.includes('3PL') ? 'Estimado (com prior)' : 'Fixo = 0'}
                  </p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Advanced Settings */}
        {showAdvanced && (
          <Card className="glass-card animate-fade-in">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Settings className="w-5 h-5 text-[var(--primary)]" />
                Configurações Avançadas
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Método de Estimação</Label>
                  <Select defaultValue="EM">
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="EM">EM (Expectation-Maximization)</SelectItem>
                      <SelectItem value="MHRM">MHRM (Metropolis-Hastings)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label>Pontos de Quadratura</Label>
                  <Select defaultValue="61">
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="41">41 pontos</SelectItem>
                      <SelectItem value="61">61 pontos (padrão)</SelectItem>
                      <SelectItem value="81">81 pontos</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Action Buttons */}
        <div className="flex items-center justify-between pt-4">
          <Button 
            variant="ghost" 
            onClick={() => setShowAdvanced(!showAdvanced)}
          >
            <Settings className="w-4 h-4 mr-2" />
            {showAdvanced ? 'Ocultar' : 'Avançado'}
          </Button>
          
          <div className="flex gap-3">
            <Button variant="outline" asChild>
              <Link href="/upload">Voltar</Link>
            </Button>
            <Button 
              className="btn-primary"
              onClick={handleApply}
              asChild
            >
              <Link href="/dashboard">
                <Play className="w-4 h-4 mr-2" />
                Aplicar e Analisar
              </Link>
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
