#!/bin/bash
# Script de backup para GitHub
cd "/Volumes/Kingston 1/apps/TRI"
git add -A
git commit -m "Backup: $(date +%Y-%m-%d_%H:%M:%S)"
git push origin main
echo "Backup concluído em: $(date)"
