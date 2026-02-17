import type { NextConfig } from "next";

const nextConfig: NextConfig = {
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
