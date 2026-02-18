import type { NextConfig } from "next";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";

const projectRoot = dirname(fileURLToPath(import.meta.url));

const nextConfig: NextConfig = {
  turbopack: {
    root: projectRoot,
  },

  // Configuração para desenvolvimento local
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: 'http://localhost:8000/:path*',
      },
    ];
  },
  
  // Configurações de imagem
  images: {
    unoptimized: true,
  },
  
  // Desabilitar strict mode temporariamente para evitar double fetch
  reactStrictMode: false,
};

export default nextConfig;
