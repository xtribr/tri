/**
 * API para carregar dados ENEM 2024 processados do arquivo real
 * Usa o JSON gerado a partir dos microdados oficiais do INEP
 */

import type { ENEMArea } from '@/lib/utils/enemConversion';

export interface ENEM2024Data {
  metadata: {
    ano: number;
    data_processamento: string;
    total_inscritos: number;
    arquivo_fonte: string;
  };
  CH: ENEMAreaData;
  CN: ENEMAreaData;
  LC: ENEMAreaData;
  MT: ENEMAreaData;
}

export interface ENEMAreaData {
  ano: number;
  area: ENEMArea;
  n_itens: number;
  estatisticas: {
    n_presentes: number;
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
    notaMin: number;
    notaMed: number;
    notaMax: number;
  }>;
}

// Carregar dados do JSON
import enem2024Json from '../../../public/data/enem_2024.json';

export const ENEM_2024_DADOS: ENEM2024Data = enem2024Json as ENEM2024Data;

/**
 * Converte acertos para nota ENEM usando a tabela real de 2024
 */
export function acertosParaNota2024(
  acertos: number,
  area: ENEMArea,
  tipo: 'min' | 'med' | 'max' = 'med'
): number {
  const tabela = ENEM_2024_DADOS[area]?.tabela_amplitude;
  if (!tabela) return 0;
  
  const row = tabela.find(r => r.acertos === acertos);
  if (!row) return 0;
  
  return tipo === 'min' ? row.notaMin : tipo === 'med' ? row.notaMed : row.notaMax;
}

/**
 * Retorna estatísticas da área
 */
export function getEstatisticas2024(area: ENEMArea) {
  return ENEM_2024_DADOS[area]?.estatisticas;
}

/**
 * Retorna a tabela completa
 */
export function getTabela2024(area: ENEMArea) {
  return ENEM_2024_DADOS[area]?.tabela_amplitude;
}
