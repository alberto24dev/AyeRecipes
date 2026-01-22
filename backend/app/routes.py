from fastapi import APIRouter, Body, HTTPException, status, Depends
from fastapi.responses import Response
from typing import List
from bson import ObjectId
from pymongo import ReturnDocument

from app.database import recipe_collection, user_collection
from app.models import RecipeModel, UpdateRecipeModel
from app.auth import get_current_user

# Creamos el enrutador
router = APIRouter()

# --- Endpoint de Ping ---

@router.get("/ping", tags=["Test"])
async def ping():
    """
    Endpoint de prueba para verificar que la API está funcionando.
    """
    return {"message": "Pong!"}

# --- Endpoint de Prueba solicitado ---
@router.get("/db-test", tags=["Test"])
async def test_db_connection():
    """
    Verifica la conexión contando los documentos en la colección.
    """
    try:
        count = await recipe_collection.count_documents({})
        return {
            "status": "success",
            "message": "Conexión a la colección 'recipes' exitosa.",
            "total_recipes": count
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error de conexión: {str(e)}")

# --- Endpoints CRUD de Recetas ---

@router.post("/recipes", response_description="Añadir nueva receta", response_model=RecipeModel, status_code=status.HTTP_201_CREATED)
async def create_recipe(recipe: RecipeModel = Body(...), current_user_email: str = Depends(get_current_user)):
    """
    Crea una nueva receta en la base de datos ligada al usuario autenticado.
    """
    # Obtener el ID del usuario actual
    user = await user_collection.find_one({"email": current_user_email})
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    # Convertimos el modelo a diccionario, excluyendo nulos y el id (que genera Mongo)
    recipe_dict = recipe.model_dump(by_alias=True, exclude=["id"])
    
    # Agregamos el user_id
    recipe_dict["user_id"] = user["_id"]
    
    new_recipe = await recipe_collection.insert_one(recipe_dict)
    
    # Recuperamos la receta creada para devolverla completa con su ID
    created_recipe = await recipe_collection.find_one({"_id": new_recipe.inserted_id})
    return created_recipe

@router.get("/recipes", response_description="Listar todas las recetas del usuario", response_model=List[RecipeModel])
async def list_recipes(current_user_email: str = Depends(get_current_user)):
    """
    Obtiene una lista de las recetas del usuario autenticado (limitado a 100 por seguridad).
    """
    # Obtener el ID del usuario actual
    user = await user_collection.find_one({"email": current_user_email})
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    # Filtrar recetas por user_id
    recipes = await recipe_collection.find({"user_id": user["_id"]}).to_list(100)
    return recipes

@router.get("/recipes/{id}", response_description="Obtener una receta", response_model=RecipeModel)
async def show_recipe(id: str):
    """
    Busca una receta específica por ID.
    """
    if not ObjectId.is_valid(id):
         raise HTTPException(status_code=400, detail="ID no válido")
         
    if (recipe := await recipe_collection.find_one({"_id": ObjectId(id)})) is not None:
        return recipe

    raise HTTPException(status_code=404, detail=f"Receta {id} no encontrada")

@router.put("/recipes/{id}", response_description="Actualizar receta", response_model=RecipeModel)
async def update_recipe(id: str, recipe: UpdateRecipeModel = Body(...)):
    """
    Actualiza campos de una receta existente.
    """
    if not ObjectId.is_valid(id):
         raise HTTPException(status_code=400, detail="ID no válido")

    # Filtramos los campos que no sean None (solo actualizamos lo que se envía)
    recipe_dict = {k: v for k, v in recipe.model_dump().items() if v is not None}

    if len(recipe_dict) >= 1:
        update_result = await recipe_collection.find_one_and_update(
            {"_id": ObjectId(id)},
            {"$set": recipe_dict},
            return_document=ReturnDocument.AFTER
        )
        if update_result is not None:
            return update_result
    else:
        # Si no hay datos para actualizar, devolvemos la existente
        if (existing_recipe := await recipe_collection.find_one({"_id": ObjectId(id)})) is not None:
            return existing_recipe

    raise HTTPException(status_code=404, detail=f"Receta {id} no encontrada")

@router.delete("/recipes/{id}", response_description="Eliminar receta")
async def delete_recipe(id: str):
    """
    Elimina una receta por ID.
    """
    if not ObjectId.is_valid(id):
         raise HTTPException(status_code=400, detail="ID no válido")
         
    delete_result = await recipe_collection.delete_one({"_id": ObjectId(id)})

    if delete_result.deleted_count == 1:
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    raise HTTPException(status_code=404, detail=f"Receta {id} no encontrada")