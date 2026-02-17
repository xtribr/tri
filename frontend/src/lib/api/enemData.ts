/**
 * API para carregar dados processados do ENEM
 * Lê os JSONs gerados pelo pipeline R
 */

import type { ENEMArea } from '@/lib/utils/enemConversion';

export interface ENEMYearData {
  ano: number;
  area: ENEMArea;
  n_itens: number;
  estatisticas: {
    n_presentes: number;
    n_faltantes: number;
    media: number;
    mediana: number;
    dp: number;
    min: number;
    max: number;
    p10: number;
    p25: number;
    p75: number;
    p90: number;
  };
  tabela_amplitude: Array<{
    acertos: number;
    notaMin: number | null;
    notaMed: number | null;
    notaMax: number | null;
  }>;
  escolas: Array<{
    CO_ESCOLA: number;
    TP_DEPENDENCIA_ADM_ESC: number;
    TP_LOCALIZACAO_ESC: number;
    n_alunos: number;
    media_nota: number;
    mediana_nota: number;
    dp_nota: number;
    min_nota: number;
    max_nota: number;
  }>;
  por_uf: Array<{
    SG_UF_ESC: string;
    n_alunos: number;
    media: number;
    mediana: number;
    dp: number;
  }>;
}

export interface ENEMMetadata {
  ano: number;
  data_processamento: string;
  total_inscritos: number;
  arquivo_fonte: string;
  areas_processadas: string[];
}

export interface ENEMCompleteData {
  metadata: ENEMMetadata;
  CH?: ENEMYearData;
  CN?: ENEMYearData;
  LC?: ENEMYearData;
  MT?: ENEMYearData;
}

// Dados mock para desenvolvimento - serão substituídos por fetch real
const MOCK_ENEM_2024: ENEMCompleteData = {
  metadata: {
    ano: 2024,
    data_processamento: new Date().toISOString(),
    total_inscritos: 4332944,
    arquivo_fonte: "RESULTADOS_2024.csv",
    areas_processadas: ["CH", "CN", "LC", "MT"]
  },
  CH: {
    ano: 2024,
    area: "CH",
    n_itens: 45,
    estatisticas: {
      n_presentes: 3167955,
      n_faltantes: 1164989,
      media: 511.0,
      mediana: 508.2,
      dp: 93.1,
      min: 0,
      max: 819.7,
      p10: 389.5,
      p25: 451.2,
      p75: 568.4,
      p90: 629.8
    },
    tabela_amplitude: Array.from({ length: 46 }, (_, i) => ({
      acertos: i,
      notaMin: i === 0 ? 300 : 300 + i * 11.5,
      notaMed: i === 0 ? 300 : 320 + i * 11.2,
      notaMax: i === 0 ? 300 : 340 + i * 10.8
    })),
    escolas: [],
    por_uf: []
  },
  CN: {
    ano: 2024,
    area: "CN",
    n_itens: 45,
    estatisticas: {
      n_presentes: 3004981,
      n_faltantes: 1327963,
      media: 493.9,
      mediana: 487.3,
      dp: 79.1,
      min: 0,
      max: 867.2,
      p10: 381.2,
      p25: 439.8,
      p75: 546.5,
      p90: 601.4
    },
    tabela_amplitude: Array.from({ length: 46 }, (_, i) => ({
      acertos: i,
      notaMin: i === 0 ? 300 : 300 + i * 12.5,
      notaMed: i === 0 ? 300 : 315 + i * 12.2,
      notaMax: i === 0 ? 300 : 330 + i * 11.8
    })),
    escolas: [],
    por_uf: []
  },
  LC: {
    ano: 2024,
    area: "LC",
    n_itens: 50,
    estatisticas: {
      n_presentes: 3167955,
      n_faltantes: 1164989,
      media: 524.5,
      mediana: 521.8,
      dp: 70.0,
      min: 0,
      max: 795.8,
      p10: 428.5,
      p25: 476.3,
      p75: 571.2,
      p90: 615.4
    },
    tabela_amplitude: Array.from({ length: 51 }, (_, i) => ({
      acertos: i,
      notaMin: i === 0 ? 300 : 300 + i * 9.8,
      notaMed: i === 0 ? 300 : 320 + i * 9.5,
      notaMax: i === 0 ? 300 : 340 + i * 9.1
    })),
    escolas: [],
    por_uf: []
  },
  MT: {
    ano: 2024,
    area: "MT",
    n_itens: 45,
    estatisticas: {
      n_presentes: 3004981,
      n_faltantes: 1327963,
      media: 527.0,
      mediana: 519.4,
      dp: 114.2,
      min: 0,
      max: 961.9,
      p10: 389.7,
      p25: 448.6,
      p75: 598.3,
      p90: 678.5
    },
    tabela_amplitude: Array.from({ length: 46 }, (_, i) => ({
      acertos: i,
      notaMin: i === 0 ? 300 : 300 + i * 14.5,
      notaMed: i === 0 ? 300 : 325 + i * 14.2,
      notaMax: i === 0 ? 300 : 350 + i * 13.8
    })),
    escolas: [],
    por_uf: []
  }
};

/**
 * Carrega dados do ENEM para um ano específico
 * Em produção, isso buscaria o arquivo JSON gerado pelo R
 */
export async function carregarDadosENEM(ano: number): Promise<ENEMCompleteData | null> {
  try {
    // Tentar carregar do arquivo JSON processado
    const response = await fetch(`/data/enem_${ano}_completo.json`);
    if (response.ok) {
      return await response.json();
    }
    
    // Fallback para mock se arquivo não existir
    if (ano === 2024) {
      console.log('[ENEM Data] Usando dados mock para 2024');
      return MOCK_ENEM_2024;
    }
    
    return null;
  } catch (error) {
    console.error('[ENEM Data] Erro ao carregar:', error);
    // Retornar mock em caso de erro
    if (ano === 2024) return MOCK_ENEM_2024;
    return null;
  }
}

/**
 * Lista anos disponíveis para análise
 */
export async function listarAnosDisponiveis(): Promise<number[]> {
  // Por enquanto, retornar apenas 2024 (mock)
  // Em produção, isso verificaria quais arquivos JSON existem
  return [2024];
}

/**
 * Compara dados entre dois anos
 */
export function compararAnos(
  dadosAno1: ENEMCompleteData,
  dadosAno2: ENEMCompleteData
): Record<ENEMArea, { variacaoMedia: number; variacaoPercentual: number }> {
  const areas: ENEMArea[] = ['CH', 'CN', 'LC', 'MT'];
  const resultado = {} as Record<ENEMArea, { variacaoMedia: number; variacaoPercentual: number }>;
  
  for (const area of areas) {
    const stats1 = dadosAno1[area]?.estatisticas;
    const stats2 = dadosAno2[area]?.estatisticas;
    
    if (stats1 && stats2) {
      const variacaoMedia = stats2.media - stats1.media;
      resultado[area] = {
        variacaoMedia,
        variacaoPercentual: (variacaoMedia / stats1.media) * 100
      };
    }
  }
  
  return resultado;
}
