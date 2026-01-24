#!/usr/bin/env python3
import asyncio
import os
import sys
from pathlib import Path

# Asegurar que dotenv se carga desde el directorio correcto
env_path = Path(__file__).parent / ".env"
from dotenv import load_dotenv
load_dotenv(dotenv_path=env_path)

# Importar después de cargar env
from motor.motor_asyncio import AsyncIOMotorClient

async def test_recipes():
    mongo_url = os.environ.get("MONGODB_URL")
    db_name = os.environ.get("DB_NAME")
    
    if not mongo_url:
        print("❌ MONGODB_URL no está configurada")
        return
        
    print(f"📦 Conectando a MongoDB...")
    try:
        client = AsyncIOMotorClient(mongo_url, serverSelectionTimeoutMS=5000)
        db = client[db_name]
        recipes = db.get_collection("recipes")
        
        # Ping para verificar conexión
        await client.admin.command('ping')
        print(f"✅ Conexión exitosa a MongoDB")
        
        result = await recipes.find().to_list(length=10)
        print(f"\n📋 Total de recetas: {len(result)}\n")
        
        for recipe in result:
            print(f"Título: {recipe.get('title')}")
            print(f"Image URL: {recipe.get('image_url')}")
            print("---")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_recipes())
