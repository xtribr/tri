/**
 * Tipos fundamentais para o sistema TRI Frontend
 * Baseado nas especificações do AGENTS.md e API Plumber
 */

// ============================================
// MODELOS E PARÂMETROS TRI
// ============================================

export type TRIModel = 'Rasch' | '2PL' | '3PL' | '3PL_ENEM';

export interface ItemParameters {
  a?: number;  // Discriminação (1PL fixo = 1, 2PL/3PL estimado)
  b: number;   // Dificuldade (logit)
  c?: number;  // Acerto ao acaso (3PL only)
}

export interface CalibratedItem extends ItemParameters {
  cod: string;
  posicao?: number;
  area?: string;
  tema?: string;
  subtema?: string;
  gabarito?: string;
  
  // Estatísticas de ajuste
  infit?: number;
  outfit?: number;
  correlacao_bisserial?: number;
  p_valor_sx2?: number;
  
  // Metadados
  status?: 'OK' | 'ATENCAO' | 'REMOVIDO';
  motivo_removido?: string;
}

export interface CalibrationResult {
  itens: CalibratedItem[];
  estatisticas_ajuste: {
    loglikelihood: number;
    aic: number;
    bic: number;
    rmsea?: number;
    cfi?: number;
    tli?: number;
  };
  convergencia: boolean;
  iteracoes: number;
}

// ============================================
// ESTIMATIVA DE HABILIDADE (THETA)
// ============================================

export type ScoringMethod = 'EAP' | 'MAP' | 'ML';

export interface ScoringResult {
  theta: number;
  erro_padrao: number;
  ic_95: [number, number];  // Intervalo de confiança
  metodo: ScoringMethod;
  respostas_consideradas: number;
  itens_respondidos?: number;
}

// ============================================
// CAT (COMPUTERIZED ADAPTIVE TESTING)
// ============================================

export interface CATSession {
  id: string;
  modelo: TRIModel;
  itens_disponiveis: string[];
  itens_aplicados: string[];
  respostas: Record<string, 0 | 1>;
  theta_atual: number;
  erro_padrao: number;
  finalizado: boolean;
  criterio_parada?: 'erro_minimo' | 'max_itens' | 'sem_itens';
}

export interface CATConfig {
  tamanho_maximo: number;
  erro_alvo: number;
  metodo_selecao: 'MFI' | 'KL' | 'progressive';
  exposicao_maxima?: number;
}

// ============================================
// DADOS E UPLOAD
// ============================================

export interface DataUpload {
  file?: File;
  nome: string;
  tipo: 'CSV' | 'XLSX' | 'JSON';
  dados: number[][];  // Matriz binária: 0 = erro, 1 = acerto
  candidatos: string[];  // IDs ou nomes
  itens: string[];  // Códigos dos itens
  n_candidatos: number;
  n_itens: number;
  media_acertos: number;
}

export interface ValidationResult {
  valido: boolean;
  erros: string[];
  avisos: string[];
  preview: {
    headers: string[];
    rows: (string | number)[][];
  };
}

// ============================================
// PRESETS E CONFIGURAÇÕES
// ============================================

export type ExamType = 'ENEM' | 'ENAMED' | 'SAEB' | 'CUSTOM';

export interface PresetConfig {
  tipo: ExamType;
  modelo_padrao: TRIModel;
  metodo_scoring: ScoringMethod;
  n_itens: number;
  areas?: string[];
  tempos?: Record<string, number>;
}

export interface ENAMPreset extends PresetConfig {
  tipo: 'ENAMED';
  areas: ['Cirurgia', 'Ginecologia', 'Pediatria', 'Clínica Médica', 'Preventiva'];
}

export interface ENEMPreset extends PresetConfig {
  tipo: 'ENEM';
  areas: ['CH', 'CN', 'LC', 'MT'];
  ano_referencia: number;
}

// ============================================
// ANÁLISE E RELATÓRIOS
// ============================================

export interface AnalysisReport {
  id: string;
  nome: string;
  data_criacao: string;
  
  // Sumário executivo
  sumario: {
    n_candidatos: number;
    n_itens: number;
    modelo: TRIModel;
    media_theta: number;
    desvio_theta: number;
    consistencia_interna?: number;  // Alfa de Cronbach
  };
  
  // Resultados detalhados
  calibracao: CalibrationResult;
  escores: ScoringResult[];
  
  // Análises adicionais
  analise_areas?: Record<string, AreaAnalysis>;
  curvas_caracteristicas?: ICCData[];
}

export interface AreaAnalysis {
  area: string;
  n_itens: number;
  media_dificuldade: number;
  discriminacao_media?: number;
  taxa_acerto_media: number;
}

// ============================================
// GRÁFICOS E VISUALIZAÇÕES
// ============================================

export interface ICCData {
  item_cod: string;
  theta_range: number[];  // -4 a 4 em passos
  probabilidades: number[];
  parametros: ItemParameters;
  info?: number[];  // Função de informação
}

export interface ScoreDistribution {
  bins: number[];  // Limites dos bins
  frequencias: number[];
  percentis: Record<string, number>;  // P10, P25, P50, P75, P90
}

export interface TrendData {
  ano: number;
  media_theta: number;
  dp_theta: number;
  n_candidatos: number;
  n_itens: number;
  modelo: TRIModel;
}

// ============================================
// CONFIGURAÇÕES DE REFERÊNCIA (ENEM)
// ============================================

export interface ENEMConversionRow {
  acertos: number;
  nota_min: number;
  nota_med: number;
  nota_max: number;
}

export interface ENEMReferenceTable {
  ano: number;
  area: 'CH' | 'CN' | 'LC' | 'MT';
  dados: ENEMConversionRow[];
  linhas: number;
  colunas: string[];
  aplicacao: 'digital' | 'impresso' | 'ambos';
  observacoes?: string;
}

export interface ReferenceVersion {
  id: string;
  ano: number;
  area: string;
  data_upload: string;
  fonte: string;
  status: 'active' | 'deprecated' | 'draft';
  diff_ano_anterior?: {
    mudancas_significativas: boolean;
    itens_afetados: number[];
    magnitude_media: number;
  };
}

// ============================================
// ESTADO DA APLICAÇÃO
// ============================================

export interface AppState {
  // Dados carregados
  upload: DataUpload | null;
  
  // Configurações selecionadas
  preset: PresetConfig | null;
  modelo: TRIModel;
  
  // Resultados
  calibracao: CalibrationResult | null;
  escores: ScoringResult[] | null;
  
  // CAT (se aplicável)
  cat_session: CATSession | null;
  
  // UI State
  etapa_atual: 'upload' | 'config' | 'processing' | 'results';
  is_loading: boolean;
  erro: string | null;
}

// ============================================
// API RESPONSE TYPES
// ============================================

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: unknown;
  };
}

export interface ApiError {
  code: string;
  message: string;
  status: number;
}
