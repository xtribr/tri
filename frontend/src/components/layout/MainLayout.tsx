'use client';

import React from 'react';
import { Sidebar } from './Sidebar';

interface MainLayoutProps {
  children: React.ReactNode;
}

export function MainLayout({ children }: MainLayoutProps) {
  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="main-content">
        {children}
      </main>
    </div>
  );
}
