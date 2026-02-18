/**
 * Sistema de Conversão ENEM - Tabelas de Referência INEP
 * Converte acertos/theta para escala ENEM (0-1000) com MIN/MED/MAX
 */

import enemData from '@config/presets_enem_historico.json';

export type ENEMArea = 'CH' | 'CN' | 'LC' | 'MT';
export type ENEMYear = 2009 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 | 2022 | 2023;

interface ConversionRow {
  acertos: number;
  notaMin: number | null;
  notaMed: number | null;
  notaMax: number | null;
}

interface ENEMTable {
  ano: number;
  exame: string;
  modelo: string;
  metodo: string;
  escala: { min: number; max: number };
  areas: Record<ENEMArea, {
    n_itens: number;
    tabela: ConversionRow[];
  }>;
}

// Type assertion para os dados importados
const enemTables = enemData as Record<string, ENEMTable>;

/**
 * Converte número de acertos para nota ENEM usando interpolação linear
 * @param acertos - Número de acertos (0-45 para CH/CN/MT, 0-50 para LC em anos históricos, 0-45 para LC em 2024)
 * @param ano - Ano da prova de referência
 * @param area - Área do conhecimento
 * @param tipo - 'min' | 'med' | 'max'
 * @returns Nota na escala ENEM
 */
export function acertosParaNotaENEM(
  acertos: number,
  ano: ENEMYear | number = 2023,
  area: ENEMArea = 'CH',
  tipo: 'min' | 'med' | 'max' = 'med'
): number {
  const yearData = enemTables[ano.toString()];
  if (!yearData) {
    console.warn(`Ano ${ano} não encontrado, usando 2023`);
    return acertosParaNotaENEM(acertos, 2023, area, tipo);
  }

  const areaData = yearData.areas[area];
  if (!areaData) {
    throw new Error(`Área ${area} não encontrada para o ano ${ano}`);
  }

  const tabela = areaData.tabela;
  const maxAcertos = areaData.n_itens;
  
  // Garantir que acertos está no range válido
  const acertosClamped = Math.max(0, Math.min(acertos, maxAcertos));
  
  // Encontrar os pontos de interpolação
  const idx = Math.floor(acertosClamped);
  const frac = acertosClamped - idx;
  
  const row1 = tabela.find(r => r.acertos === idx);
  const row2 = tabela.find(r => r.acertos === idx + 1);
  
  if (!row1) {
    return tabela[0]?.[tipo === 'min' ? 'notaMin' : tipo === 'med' ? 'notaMed' : 'notaMax'] || 300;
  }
  
  if (!row2 || frac === 0) {
    const val = tipo === 'min' ? row1.notaMin : tipo === 'med' ? row1.notaMed : row1.notaMax;
    return val ?? (tipo === 'min' ? 0 : tipo === 'med' ? 500 : 1000);
  }
  
  // Interpolação linear
  const val1 = tipo === 'min' ? (row1.notaMin ?? 0) : tipo === 'med' ? (row1.notaMed ?? 500) : (row1.notaMax ?? 1000);
  const val2 = tipo === 'min' ? (row2.notaMin ?? 0) : tipo === 'med' ? (row2.notaMed ?? 500) : (row2.notaMax ?? 1000);
  
  return val1 + (val2 - val1) * frac;
}

/**
 * Converte theta (habilidade TRI) para acertos equivalentes
 * Baseado na probabilidade média de acerto dado theta
 * @param theta - Habilidade na escala logit
 * @param itens - Parâmetros dos itens calibrados
 * @returns Número esperado de acertos
 */
export function thetaParaAcertosEsperados(
  theta: number,
  itens: Array<{ a?: number; b: number; c?: number }>
): number {
  // Probabilidade de acerto no modelo 3PL: P(θ) = c + (1-c) / (1 + exp(-a(θ-b)))
  const probabilidades = itens.map(item => {
    const a = item.a ?? 1;
    const b = item.b;
    const c = item.c ?? 0;
    const exponent = -a * (theta - b);
    return c + (1 - c) / (1 + Math.exp(exponent));
  });
  
  // Soma das probabilidades = número esperado de acertos
  return probabilidades.reduce((sum, p) => sum + p, 0);
}

/**
 * Converte theta diretamente para nota ENEM
 * Combina theta → acertos esperados → nota ENEM
 */
export function thetaParaNotaENEM(
  theta: number,
  itens: Array<{ a?: number; b: number; c?: number }>,
  ano: ENEMYear | number = 2023,
  area: ENEMArea = 'CH',
  tipo: 'min' | 'med' | 'max' = 'med'
): number {
  const acertosEsperados = thetaParaAcertosEsperados(theta, itens);
  return acertosParaNotaENEM(acertosEsperados, ano, area, tipo);
}

/**
 * Retorna estatísticas da tabela de referência
 */
export function getTabelaInfo(ano: ENEMYear | number, area: ENEMArea) {
  const yearData = enemTables[ano.toString()];
  if (!yearData) return null;
  
  const areaData = yearData.areas[area];
  if (!areaData) return null;
  
  const tabela = areaData.tabela;
  const notasMed = tabela.map(r => r.notaMed);
  
  const notasMinValidas = tabela.map(r => r.notaMin).filter((n): n is number => n !== null);
  const notasMaxValidas = tabela.map(r => r.notaMax).filter((n): n is number => n !== null);
  const notasMedValidas = notasMed.filter((n): n is number => n !== null);
  
  return {
    ano,
    area,
    n_itens: areaData.n_itens,
    nota_minima: notasMinValidas.length > 0 ? Math.min(...notasMinValidas) : 300,
    nota_maxima: notasMaxValidas.length > 0 ? Math.max(...notasMaxValidas) : 1000,
    media_nacional: notasMedValidas.length > 0 ? notasMedValidas.reduce((a, b) => a + b, 0) / notasMedValidas.length : 500,
    mediana: notasMedValidas[Math.floor(notasMedValidas.length / 2)] ?? 500,
    tabela_completa: tabela,
  };
}

/**
 * Lista anos disponíveis
 */
export function getAnosDisponiveis(): number[] {
  return Object.keys(enemTables).map(Number).sort();
}

/**
 * Lista áreas disponíveis
 */
export function getAreasDisponiveis(): ENEMArea[] {
  return ['CH', 'CN', 'LC', 'MT'];
}
