'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  FileUp,
  BarChart3,
  Settings,
  Database,
  TrendingUp,
  HelpCircle,
  ChevronRight,
} from 'lucide-react';

interface NavItem {
  label: string;
  href: string;
  icon: React.ElementType;
}

const mainNavItems: NavItem[] = [
  { label: 'Upload de Dados', href: '/upload', icon: FileUp },
  { label: 'Dashboard', href: '/dashboard', icon: BarChart3 },
  { label: 'Análise TRI', href: '/analysis', icon: Database },
  { label: 'Comparativo ENEM', href: '/comparativo', icon: TrendingUp },
];

const secondaryNavItems: NavItem[] = [
  { label: 'Configurações', href: '/settings', icon: Settings },
  { label: 'Ajuda', href: '/help', icon: HelpCircle },
];

export function Sidebar() {
  const pathname = usePathname();
  
  return (
    <aside className="sidebar">
      {/* Logo */}
      <div className="p-4 mb-2">
        <Link href="/" className="flex items-center gap-3 px-2">
          <div className="w-8 h-8 rounded-lg bg-[var(--primary)] flex items-center justify-center">
            <span className="text-white font-bold text-sm">T</span>
          </div>
          <span className="font-semibold text-[var(--text-primary)] tracking-tight">
            TRI Analytics
          </span>
        </Link>
      </div>
      
      {/* Workspace Switcher */}
      <div className="px-4 mb-4">
        <button className="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-black/5 transition-colors text-sm text-[var(--text-secondary)]">
          <span>Workspace Padrão</span>
          <ChevronRight className="w-4 h-4" />
        </button>
      </div>
      
      {/* Main Navigation */}
      <nav className="flex-1 px-2">
        <div className="mb-6">
          <p className="px-3 mb-2 text-xs font-medium text-[var(--text-tertiary)] uppercase tracking-wider">
            Análise
          </p>
          {mainNavItems.map((item) => (
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
      <div className="p-4 border-t border-[var(--border-light)]">
        <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-[var(--primary-light)]">
          <div className="w-2 h-2 rounded-full bg-[var(--success)]" />
          <span className="text-xs font-medium text-[var(--primary)]">
            API Conectada
          </span>
        </div>
      </div>
    </aside>
  );
}
