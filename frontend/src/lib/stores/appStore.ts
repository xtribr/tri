/**
 * Zustand Store - Gerenciamento de Estado Global
 * Design: Centralizado e tipado para todo o fluxo TRI
 */

import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import type {
  AppState,
  DataUpload,
  PresetConfig,
  TRIModel,
  CalibrationResult,
  ScoringResult,
  CATSession,
  AnalysisReport,
} from '@/types';

interface AppStore extends AppState {
  // Actions
  setUpload: (upload: DataUpload | null) => void;
  setPreset: (preset: PresetConfig | null) => void;
  setModelo: (modelo: TRIModel) => void;
  setCalibracao: (calibracao: CalibrationResult | null) => void;
  setEscores: (escores: ScoringResult[] | null) => void;
  setCatSession: (session: CATSession | null) => void;
  setEtapa: (etapa: AppState['etapa_atual']) => void;
  setLoading: (loading: boolean) => void;
  setErro: (erro: string | null) => void;
  reset: () => void;
}

const initialState: AppState = {
  upload: null,
  preset: null,
  modelo: 'Rasch',
  calibracao: null,
  escores: null,
  cat_session: null,
  etapa_atual: 'upload',
  is_loading: false,
  erro: null,
};

export const useAppStore = create<AppStore>()(
  devtools(
    persist(
      (set) => ({
        ...initialState,
        
        setUpload: (upload) => set({ upload, erro: null }),
        
        setPreset: (preset) => set({ preset, erro: null }),
        
        setModelo: (modelo) => set({ modelo }),
        
        setCalibracao: (calibracao) => set({ calibracao }),
        
        setEscores: (escores) => set({ escores }),
        
        setCatSession: (cat_session) => set({ cat_session }),
        
        setEtapa: (etapa_atual) => set({ etapa_atual }),
        
        setLoading: (is_loading) => set({ is_loading }),
        
        setErro: (erro) => set({ erro }),
        
        reset: () => set(initialState),
      }),
      {
        name: 'tri-app-storage',
        partialize: (state) => ({
          preset: state.preset,
          modelo: state.modelo,
        }),
      }
    )
  )
);

// Selectors otimizados
export const selectUpload = (state: AppStore) => state.upload;
export const selectPreset = (state: AppStore) => state.preset;
export const selectCalibracao = (state: AppStore) => state.calibracao;
export const selectEscores = (state: AppStore) => state.escores;
export const selectEtapa = (state: AppStore) => state.etapa_atual;
export const selectIsLoading = (state: AppStore) => state.is_loading;
export const selectErro = (state: AppStore) => state.erro;
