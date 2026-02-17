import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { MainLayout } from "@/components/layout/MainLayout";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

export const metadata: Metadata = {
  title: "TRI Analytics - Análise Psicométrica",
  description: "Sistema de análise psicométrica usando Teoria de Resposta ao Item (TRI)",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pt-BR">
      <body className={`${inter.variable} font-sans`}>
        <MainLayout>
          {children}
        </MainLayout>
      </body>
    </html>
  );
}
