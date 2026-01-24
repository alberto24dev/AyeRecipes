from pydantic import BaseModel, Field, BeforeValidator, EmailStr
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
    image_url: Optional[str] = None
    user_id: Optional[PyObjectId] = Field(default=None)
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
    image_url: Optional[str] = None

# --- Modelos de Autenticación ---

class UserModel(BaseModel):
    id: Optional[PyObjectId] = Field(alias="_id", default=None)
    email: EmailStr = Field(..., unique=True)
    password: str = Field(..., min_length=6)
    name: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.now)

    class Config:
        populate_by_name = True
        json_schema_extra = {
            "example": {
                "email": "usuario@example.com",
                "password": "password123",
                "name": "Juan Pérez"
            }
        }

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class LoginResponse(BaseModel):
    success: bool
    message: str
    user: Optional[dict] = None
    token: Optional[str] = None

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str