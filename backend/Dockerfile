FROM python:3.11-slim

WORKDIR /app

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación
COPY ./app ./app

# Exponer el puerto
EXPOSE 8000

# Comando para ejecutar la aplicación
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Y el **.dockerignore**:
```
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.venv
.env
.git
.gitignore
*.log
.DS_Store
.vscode
```

## Pasos para deploy en Railway:

1. **Sube tu código a GitHub** (asegúrate de que `backend/` contenga todo)

2. **Ve a Railway.app** y crea un nuevo proyecto

3. **Configura las variables de entorno:**
```
   MONGODB_URL=mongodb+srv://usuario:password@cluster.mongodb.net/ayerecipes
   SECRET_KEY=tu_clave_secreta_muy_segura