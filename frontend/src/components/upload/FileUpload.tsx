'use client';

import React, { useCallback, useState } from 'react';
import { Upload, FileSpreadsheet, AlertCircle, CheckCircle2 } from 'lucide-react';
import Papa from 'papaparse';
import { useAppStore } from '@/lib/stores/appStore';
import type { DataUpload, ValidationResult } from '@/types';

interface FileUploadProps {
  onUploadComplete?: (data: DataUpload) => void;
}

export function FileUpload({ onUploadComplete }: FileUploadProps) {
  const [isDragging, setIsDragging] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [validation, setValidation] = useState<ValidationResult | null>(null);
  const setUpload = useAppStore((state) => state.setUpload);
  const setEtapa = useAppStore((state) => state.setEtapa);

  const validateData = (data: number[][]): ValidationResult => {
    const erros: string[] = [];
    const avisos: string[] = [];
    
    // Verificar dimensões
    if (data.length === 0) {
      erros.push('O arquivo está vazio');
    }
    
    if (data.length < 10) {
      avisos.push(`Amostra pequena: apenas ${data.length} candidatos. Recomendado: mínimo 100.`);
    }
    
    // Verificar valores binários
    let naoBinarios = 0;
    for (let i = 0; i < Math.min(data.length, 100); i++) {
      for (let j = 0; j < data[i].length; j++) {
        const val = data[i][j];
        if (val !== 0 && val !== 1) {
          naoBinarios++;
        }
      }
    }
    
    if (naoBinarios > 0) {
      erros.push(`Dados não binários detectados: ${naoBinarios} valores diferentes de 0/1`);
    }
    
    // Verificar itens com variância zero
    const nItens = data[0]?.length || 0;
    const itensZeroVariancia: number[] = [];
    
    for (let j = 0; j < nItens; j++) {
      const valores = data.map(row => row[j]);
      const unicos = [...new Set(valores)];
      if (unicos.length === 1) {
        itensZeroVariancia.push(j + 1);
      }
    }
    
    if (itensZeroVariancia.length > 0) {
      avisos.push(`Itens com variância zero (todos acertam/erram): #${itensZeroVariancia.slice(0, 5).join(', ')}${itensZeroVariancia.length > 5 ? '...' : ''}`);
    }
    
    // Calcular estatísticas básicas
    const nCandidatos = data.length;
    const totalRespostas = nCandidatos * nItens;
    const acertosTotais = data.reduce((sum, row) => sum + row.reduce((s, v) => s + v, 0), 0);
    const mediaAcertos = (acertosTotais / totalRespostas) * 100;
    
    return {
      valido: erros.length === 0,
      erros,
      avisos,
      preview: {
        headers: ['Candidato', ...Array.from({ length: Math.min(nItens, 10) }, (_, i) => `Q${i + 1}`)],
        rows: data.slice(0, 5).map((row, idx) => [
          `Candidato ${idx + 1}`,
          ...row.slice(0, 10).map(v => v.toString())
        ]),
      },
    };
  };

  const processFile = useCallback(async (file: File) => {
    setIsLoading(true);
    
    try {
      const result = await new Promise<Papa.ParseResult<Record<string, string>>>((resolve, reject) => {
        Papa.parse(file, {
          header: true,
          skipEmptyLines: true,
          complete: resolve,
          error: reject,
        });
      });
      
      // Extrair dados numéricos (ignorar colunas de identificação)
      const headers = result.meta.fields || [];
      const idColumns = ['nome', 'email', 'id', 'matricula', 'cpf'];
      const questionColumns = headers.filter(h => 
        !idColumns.includes(h.toLowerCase()) && 
        (h.toLowerCase().startsWith('q') || !isNaN(Number(h)))
      );
      
      const dados: number[][] = result.data.map((row: Record<string, string>) => 
        questionColumns.map(col => {
          const val = parseInt(row[col], 10);
          return isNaN(val) ? 0 : val;
        })
      );
      
      // Validar
      const validationResult = validateData(dados);
      setValidation(validationResult);
      
      if (validationResult.valido) {
        const uploadData: DataUpload = {
          nome: file.name,
          tipo: 'CSV',
          dados,
          candidatos: result.data.map((row: Record<string, string>, i) => 
            row['nome'] || row['email'] || `Candidato_${i + 1}`
          ),
          itens: questionColumns,
          n_candidatos: dados.length,
          n_itens: questionColumns.length,
          media_acertos: dados.reduce((sum, row) => sum + row.reduce((s, v) => s + v, 0), 0) / 
                        (dados.length * questionColumns.length) * 100,
        };
        
        setUpload(uploadData);
        onUploadComplete?.(uploadData);
        setEtapa('config');
      }
    } catch (error) {
      setValidation({
        valido: false,
        erros: [`Erro ao processar arquivo: ${error instanceof Error ? error.message : 'Erro desconhecido'}`],
        avisos: [],
        preview: { headers: [], rows: [] },
      });
    } finally {
      setIsLoading(false);
    }
  }, [onUploadComplete, setUpload, setEtapa]);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    
    const files = Array.from(e.dataTransfer.files);
    if (files.length > 0) {
      const file = files[0];
      if (file.name.endsWith('.csv')) {
        processFile(file);
      } else {
        setValidation({
          valido: false,
          erros: ['Por favor, envie um arquivo CSV'],
          avisos: [],
          preview: { headers: [], rows: [] },
        });
      }
    }
  }, [processFile]);

  const handleFileInput = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      processFile(file);
    }
  }, [processFile]);

  return (
    <div className="space-y-6">
      {/* Drop Zone */}
      <div
        className={`upload-zone ${isDragging ? 'dragover' : ''}`}
        onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
        onDragLeave={() => setIsDragging(false)}
        onDrop={handleDrop}
        onClick={() => document.getElementById('file-input')?.click()}
      >
        <input
          id="file-input"
          type="file"
          accept=".csv"
          className="hidden"
          onChange={handleFileInput}
        />
        
        {isLoading ? (
          <div className="animate-pulse">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-[var(--border-light)]" />
            <p className="text-[var(--text-secondary)]">Processando arquivo...</p>
          </div>
        ) : (
          <>
            <div className="upload-zone-icon">
              <FileSpreadsheet className="w-full h-full" />
            </div>
            <p className="upload-zone-text">
              Arraste um arquivo CSV ou clique para selecionar
            </p>
            <p className="upload-zone-hint">
              Formato esperado: colunas Q1, Q2... ou numéricas com valores 0/1
            </p>
          </>
        )}
      </div>

      {/* Validation Results */}
      {validation && (
        <div className={`p-4 rounded-lg border ${
          validation.valido 
            ? 'bg-[var(--success)]/5 border-[var(--success)]/20' 
            : 'bg-[var(--error)]/5 border-[var(--error)]/20'
        }`}>
          <div className="flex items-start gap-3">
            {validation.valido ? (
              <CheckCircle2 className="w-5 h-5 text-[var(--success)] flex-shrink-0 mt-0.5" />
            ) : (
              <AlertCircle className="w-5 h-5 text-[var(--error)] flex-shrink-0 mt-0.5" />
            )}
            <div className="flex-1">
              <h4 className={`font-medium ${validation.valido ? 'text-[var(--success)]' : 'text-[var(--error)]'}`}>
                {validation.valido ? 'Validação bem-sucedida' : 'Erros encontrados'}
              </h4>
              
              {validation.erros.length > 0 && (
                <ul className="mt-2 space-y-1">
                  {validation.erros.map((erro, i) => (
                    <li key={i} className="text-sm text-[var(--text-secondary)] flex items-center gap-2">
                      <span className="w-1 h-1 rounded-full bg-[var(--error)]" />
                      {erro}
                    </li>
                  ))}
                </ul>
              )}
              
              {validation.avisos.length > 0 && (
                <ul className="mt-2 space-y-1">
                  {validation.avisos.map((aviso, i) => (
                    <li key={i} className="text-sm text-[var(--warning)] flex items-center gap-2">
                      <span className="w-1 h-1 rounded-full bg-[var(--warning)]" />
                      {aviso}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Preview Table */}
      {validation?.valido && validation.preview.rows.length > 0 && (
        <div className="mt-6">
          <h4 className="text-sm font-medium text-[var(--text-secondary)] mb-3">
            Preview dos dados (primeiras 5 linhas)
          </h4>
          <div className="overflow-x-auto rounded-lg border border-[var(--border-light)]">
            <table className="data-table">
              <thead>
                <tr>
                  {validation.preview.headers.map((h, i) => (
                    <th key={i} className="whitespace-nowrap">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {validation.preview.rows.map((row, i) => (
                  <tr key={i}>
                    {row.map((cell, j) => (
                      <td key={j} className="text-sm">
                        <span className={j === 0 ? 'text-[var(--text-secondary)]' : (
                          cell === '1' ? 'text-[var(--success)] font-medium' : 
                          cell === '0' ? 'text-[var(--error)]' : ''
                        )}>
                          {cell}
                        </span>
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
