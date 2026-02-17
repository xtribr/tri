/**
 * Cliente HTTP para API R Plumber
 * Base URL: http://localhost:8000 (conforme plumber_v2.R)
 */

import axios, { AxiosError, AxiosInstance, AxiosResponse } from 'axios';
import type {
  ApiResponse,
  CalibrationResult,
  ScoringResult,
  CATSession,
  CATConfig,
  CalibratedItem,
} from '@/types';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

// Cliente Axios configurado
const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: 300000, // 5 minutos para calibrações longas
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptores
apiClient.interceptors.request.use(
  (config) => {
    console.log(`[API Request] ${config.method?.toUpperCase()} ${config.url}`);
    return config;
  },
  (error) => Promise.reject(error)
);

apiClient.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error: AxiosError) => {
    console.error('[API Error]', error.response?.data || error.message);
    return Promise.reject(error);
  }
);

// ============================================
// HELPERS
// ============================================

function handleResponse<T>(response: AxiosResponse): T {
  return response.data;
}

function handleError(error: unknown): never {
  if (axios.isAxiosError(error)) {
    const message = error.response?.data?.error || error.message;
    throw new Error(`API Error: ${message}`);
  }
  throw error;
}

// ============================================
// ENDPOINTS DE CALIBRAÇÃO
// ============================================

/**
 * Calibra itens usando modelo TRI especificado
 * @param dados Matriz de respostas (n_candidatos x n_itens)
 * @param modelo Modelo TRI: 'Rasch', '2PL', '3PL', '3PL_ENEM'
 * @param ancoras Itens âncora (opcional)
 */
export async function calibrarItens(
  dados: number[][],
  modelo: string = 'Rasch',
  ancoras?: Array<{
    cod: string;
    a?: number;
    b: number;
    c?: number;
  }>
): Promise<CalibrationResult> {
  try {
    const response = await apiClient.post('/calibrar', {
      dados,
      modelo,
      ancoras: ancoras || [],
    });
    return handleResponse<CalibrationResult>(response);
  } catch (error) {
    handleError(error);
  }
}

/**
 * Calibra com itens âncora
 * @param dados Matriz de respostas
 * @param ancoras Lista de itens âncora
 * @param modelo Modelo TRI
 */
export async function calibrarComAncoras(
  dados: number[][],
  ancoras: Array<{
    cod: string;
    a?: number;
    b: number;
    c?: number;
  }>,
  modelo: string = 'Rasch'
): Promise<CalibrationResult> {
  return calibrarItens(dados, modelo, ancoras);
}

// ============================================
// ENDPOINTS DE SCORING
// ============================================

/**
 * Estima escores theta para candidatos
 * @param respostas Matriz ou vetor de respostas
 * @param itens Parâmetros dos itens calibrados
 * @param metodo Método: 'EAP', 'MAP', 'ML'
 */
export async function estimarEscores(
  respostas: number[] | number[][],
  itens: CalibratedItem[],
  metodo: string = 'EAP'
): Promise<ScoringResult[]> {
  try {
    const response = await apiClient.post('/scoring/estimar', {
      respostas,
      itens,
      metodo,
    });
    return handleResponse<ScoringResult[]>(response);
  } catch (error) {
    handleError(error);
  }
}

/**
 * Converte theta para escala ENEM (0-1000)
 * @param theta Valor de habilidade
 * @param media_enem Média da população ENEM (default: 500)
 * @param dp_enem Desvio-padrão ENEM (default: 100)
 */
export function thetaParaENEM(
  theta: number,
  media_enem: number = 500,
  dp_enem: number = 100
): number {
  // ENEM usa escala com média 500 e DP 100
  // Theta tipicamente varia de -4 a 4
  return Math.round(media_enem + theta * dp_enem);
}

// ============================================
// ENDPOINTS DE CAT
// ============================================

/**
 * Inicia uma sessão CAT
 * @param itens_disponiveis Lista de códigos de itens
 * @param modelo Modelo TRI
 * @param config Configurações do CAT
 */
export async function iniciarSessaoCAT(
  itens_disponiveis: string[],
  modelo: string = 'Rasch',
  config?: CATConfig
): Promise<CATSession> {
  try {
    const response = await apiClient.post('/cat/sessao/iniciar', {
      itens_disponiveis,
      modelo,
      config,
    });
    return handleResponse<CATSession>(response);
  } catch (error) {
    handleError(error);
  }
}

/**
 * Seleciona próximo item no CAT
 * @param sessao_id ID da sessão
 */
export async function selecionarProximoItem(
  sessao_id: string
): Promise<{ item_cod: string; theta_atual: number; erro_padrao: number }> {
  try {
    const response = await apiClient.post(`/cat/sessao/${sessao_id}/proximo_item`);
    return handleResponse(response);
  } catch (error) {
    handleError(error);
  }
}

/**
 * Registra resposta no CAT
 * @param sessao_id ID da sessão
 * @param item_cod Código do item
 * @param resposta 0 (erro) ou 1 (acerto)
 */
export async function responderItemCAT(
  sessao_id: string,
  item_cod: string,
  resposta: 0 | 1
): Promise<CATSession> {
  try {
    const response = await apiClient.post(`/cat/sessao/${sessao_id}/responder`, {
      item_cod,
      resposta,
    });
    return handleResponse<CATSession>(response);
  } catch (error) {
    handleError(error);
  }
}

// ============================================
// ENDPOINTS DE ESTATÍSTICAS
// ============================================

/**
 * Calcula estatísticas descritivas dos dados
 */
export async function calcularEstatisticas(dados: number[][]) {
  try {
    const response = await apiClient.post('/estatisticas/descritivas', { dados });
    return handleResponse(response);
  } catch (error) {
    handleError(error);
  }
}

/**
 * Calcula coeficiente alpha de Cronbach
 */
export async function calcularAlphaCronbach(dados: number[][]): Promise<number> {
  try {
    const response = await apiClient.post('/estatisticas/alpha', { dados });
    return handleResponse<number>(response);
  } catch (error) {
    handleError(error);
  }
}

// ============================================
// HEALTH CHECK
// ============================================

export async function healthCheck(): Promise<{ status: string; version: string }> {
  try {
    const response = await apiClient.get('/health');
    return handleResponse(response);
  } catch (error) {
    throw new Error('API não está respondendo. Verifique se o servidor R Plumber está rodando em http://localhost:8000');
  }
}

export default apiClient;
