from fastapi import APIRouter, HTTPException, status, Body
from typing import Optional
from app.database import user_collection
from app.models import LoginRequest, LoginResponse, RegisterRequest, UserModel
from app.auth import hash_password, verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=LoginResponse, status_code=status.HTTP_201_CREATED)
async def register(register_data: RegisterRequest = Body(...)):
    """
    Registra un nuevo usuario en la aplicación.
    """
    # Verificar si el usuario ya existe
    existing_user = await user_collection.find_one({"email": register_data.email})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El usuario ya existe"
        )
    
    # Crear nuevo usuario
    hashed_password = hash_password(register_data.password)
    new_user = {
        "email": register_data.email,
        "password": hashed_password,
        "name": register_data.name,
        "created_at": datetime.utcnow()
    }
    
    result = await user_collection.insert_one(new_user)
    
    # Crear token
    token = create_access_token(register_data.email)
    
    return LoginResponse(
        success=True,
        message="Usuario registrado exitosamente",
        user={"_id": str(result.inserted_id), "email": register_data.email, "name": register_data.name},
        token=token
    )

@router.post("/login", response_model=LoginResponse)
async def login(login_data: LoginRequest = Body(...)):
    """
    Autentica un usuario y retorna un token JWT.
    """
    # Buscar el usuario por email
    user = await user_collection.find_one({"email": login_data.email})
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o contraseña incorrectos"
        )
    
    # Verificar contraseña
    if not verify_password(login_data.password, user["password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o contraseña incorrectos"
        )
    
    # Crear token
    token = create_access_token(login_data.email)
    
    return LoginResponse(
        success=True,
        message="Login exitoso",
        user={"_id": str(user["_id"]), "email": user["email"], "name": user.get("name", "")},
        token=token
    )

@router.get("/verify")
async def verify_user(token: str):
    """
    Verifica que un token sea válido.
    """
    from app.auth import verify_token
    
    email = verify_token(token)
    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado"
        )
    
    user = await user_collection.find_one({"email": email})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )
    
    return {
        "success": True,
        "email": user["email"],
        "name": user.get("name", "")
    }


from datetime import datetime
