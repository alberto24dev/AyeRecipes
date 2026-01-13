from pydantic import BaseModel, Field, BeforeValidator
from typing import Optional, List, Annotated
from datetime import datetime

# Helper para manejar ObjectId como string
PyObjectId = Annotated[str, BeforeValidator(str)]

class RecipeModel(BaseModel):
    # El id es opcional al crear, pero mongo lo genera. Lo mapeamos a _id en la BD.
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    title: str = Field(..., min_length=1)
    description: Optional[str] = None
    ingredients: List[str] = []
    steps: List[str] = []
    created_at: datetime = Field(default_factory=datetime.now)

    class Config:
        populate_by_name = True
        json_schema_extra = {
            "example": {
                "title": "Yogurt con Linaza",
                "description": "Desayuno rápido",
                "ingredients": ["1 taza yogurt", "2 cdas linaza"],
                "steps": ["Servir", "Mezclar"],
            }
        }

class UpdateRecipeModel(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    ingredients: Optional[List[str]] = None
    steps: Optional[List[str]] = None