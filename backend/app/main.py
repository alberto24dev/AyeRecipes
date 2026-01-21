from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.database import check_db_connection
from app.routes import router as recipe_router
from app.auth_routes import router as auth_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    await check_db_connection()
    yield

app = FastAPI(lifespan=lifespan)

# Configurar CORS para permitir peticiones desde tu app iOS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especifica tu dominio
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir las rutas
app.include_router(recipe_router, tags=["Recipes"], prefix="/api")
app.include_router(auth_router, prefix="/api")

@app.get("/")
async def root():
    return {"message": "API iniciada correctamente"}

@app.get("/health")
async def health():
    return {"status": "healthy"}