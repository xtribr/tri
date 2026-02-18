'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  BarChart3,
  TrendingUp,
  Target,
  Settings,
  School,
  GraduationCap,
  ChevronRight,
  Brain,
} from 'lucide-react';

interface NavItem {
  label: string;
  href: string;
  icon: React.ElementType;
  badge?: string;
}

const mainNavItems: NavItem[] = [
  { label: 'Dashboard ENEM', href: '/dashboard', icon: BarChart3, badge: '2024' },
  { label: 'Tabela 2024 (Real)', href: '/tabela2024', icon: Target, badge: 'NOVO' },
  { label: 'Análise TRI 3PL', href: '/analise-tri', icon: Brain },
  { label: 'Tabela Histórica', href: '/tabela', icon: Target },
  { label: 'Comparativo Anual', href: '/comparativo', icon: TrendingUp },
  { label: 'Análise por Escola', href: '/escolas', icon: School },
];

const secondaryNavItems: NavItem[] = [
  { label: 'Configurações', href: '/settings', icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();
  
  return (
    <aside className="sidebar">
      {/* Logo */}
      <div className="p-4 mb-2">
        <Link href="/" className="flex items-center gap-3 px-2">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[var(--primary)] to-[#5856D6] flex items-center justify-center shadow-lg">
            <GraduationCap className="w-6 h-6 text-white" />
          </div>
          <div>
            <span className="font-bold text-[var(--text-primary)] tracking-tight block leading-tight">
              ENEM Analytics
            </span>
            <span className="text-[10px] text-[var(--text-tertiary)] uppercase tracking-wider">
              Análise de Dados INEP
            </span>
          </div>
        </Link>
      </div>
      
      {/* Ano Selector */}
      <div className="px-4 mb-6">
        <div className="flex items-center justify-between px-3 py-2 rounded-lg bg-[var(--bg-tertiary)] border border-[var(--border-light)]">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-[var(--success)] animate-pulse" />
            <span className="text-sm font-medium text-[var(--text-primary)]">ENEM 2024</span>
          </div>
          <ChevronRight className="w-4 h-4 text-[var(--text-tertiary)]" />
        </div>
      </div>
      
      {/* Main Navigation */}
      <nav className="flex-1 px-2">
        <div className="mb-6">
          <p className="px-3 mb-2 text-xs font-medium text-[var(--text-tertiary)] uppercase tracking-wider">
            Análise Principal
          </p>
          {mainNavItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`sidebar-item ${pathname === item.href ? 'active' : ''}`}
            >
              <item.icon className="w-4 h-4" />
              <span className="flex-1">{item.label}</span>
              {item.badge && (
                <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-[var(--primary)]/10 text-[var(--primary)]">
                  {item.badge}
                </span>
              )}
            </Link>
          ))}
        </div>
        
        <div>
          <p className="px-3 mb-2 text-xs font-medium text-[var(--text-tertiary)] uppercase tracking-wider">
            Sistema
          </p>
          {secondaryNavItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`sidebar-item ${pathname === item.href ? 'active' : ''}`}
            >
              <item.icon className="w-4 h-4" />
              <span>{item.label}</span>
            </Link>
          ))}
        </div>
      </nav>
      
      {/* Status Footer */}
      <div className="p-4 border-t border-[var(--border-light)] space-y-3">
        <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-[var(--success)]/10">
          <div className="w-2 h-2 rounded-full bg-[var(--success)]" />
          <span className="text-xs font-medium text-[var(--success)]">
            Dados 2024 Carregados
          </span>
        </div>
        <p className="text-[10px] text-[var(--text-tertiary)] px-3">
          {new Date().toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' })}
        </p>
      </div>
    </aside>
  );
}
