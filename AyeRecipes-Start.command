#!/bin/bash

echo "Iniciando AyeStock"

# --- 1. Base de Datos ---
echo "Lanzando MongoDB en nueva terminal..."
osascript -e "tell application \"Terminal\" to do script \"brew services start mongodb-community\""

# --- 2. Backend ---
echo "Lanzando Backend en nueva terminal..."
osascript -e "tell application \"Terminal\" to do script \"
cd /Users/alberto24dev/Documents/Projects/Code/AyeRecipes/backend && 
source AyeRecipes/bin/activate && 
python -m uvicorn app.main:app --reload --port 8000 --host 0.0.0.0\""

# --- 4. Abrir Navegador ---
echo "Servicios arrancando (15s)..."
sleep 10

# Abre la documentación del API y el Frontend
open "http://localhost:8000/docs"
open "http://127.0.0.1:8000"

echo "¡AyeStock iniciado!