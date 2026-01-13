import os
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

# Cargar variables del .env
load_dotenv()

# Obtener URL y Nombre de la BD
MONGO_URL = os.environ.get("MONGODB_URL")
DB_NAME = os.environ.get("DB_NAME")

client = AsyncIOMotorClient(MONGO_URL)
database = client[DB_NAME]
recipe_collection = database.get_collection("recipes")

# Función auxiliar para verificar conexión (opcional, útil para debug)
async def check_db_connection():
    try:
        await client.admin.command('ping')
        print("✅ Conexión exitosa a MongoDB Atlas")
    except Exception as e:
        print(f"❌ Error conectando a MongoDB: {e}")