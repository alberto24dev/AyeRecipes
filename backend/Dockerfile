FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY ./app ./app

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Pasos para debuggear:

1. **Haz clic en "Build Logs"** (segunda pestaña arriba) y muéstrame qué dice

2. Mientras tanto, verifica en tu repositorio de GitHub que:
   - ✅ `backend/Dockerfile` existe
   - ✅ `backend/requirements.txt` existe
   - ✅ `backend/app/main.py` existe

3. Si no ves los logs, intenta hacer un **nuevo deploy manual**:
   - Ve a **Deployments** (primera pestaña)
   - Haz clic en los 3 puntos `...` al lado derecho
   - Selecciona **"Redeploy"**

4. También revisa que tu `.gitignore` **NO esté bloqueando** estos archivos:
```
   backend/Dockerfile        ← NO debe estar ignorado
   backend/requirements.txt  ← NO debe estar ignorado
   backend/app/*.py          ← NO debe estar ignorado