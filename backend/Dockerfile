FROM python:3.11-slim

WORKDIR /app

# Copiar requirements desde backend
COPY backend/requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar el código desde backend/app
COPY backend/app ./app

# Exponer el puerto
EXPOSE 8000

# Comando para ejecutar
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## ¿Cuál estructura tienes en GitHub?

Dime si tu repositorio se ve así:
```
AYERECIPES/
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
│       └── ...
└── ios-app/
```

O así:
```
AYERECIPES/
├── Dockerfile
├── requirements.txt
├── app/
│   └── ...
└── ios-app/