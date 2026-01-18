from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.database import check_db_connection
# [NUEVO] Importamos los routers desde los archivos de rutas
from app.routes import router as recipe_router
from app.auth_routes import router as auth_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    await check_db_connection()
    yield

app = FastAPI(lifespan=lifespan)

# [NUEVO] Incluimos las rutas en la aplicación principal
app.include_router(recipe_router, tags=["Recipes"], prefix="/api")
app.include_router(auth_router, prefix="/api")

@app.get("/")
async def root():
    return {"message": "API iniciada correctamente"}