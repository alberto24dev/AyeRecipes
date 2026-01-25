# AyeRecipes iOS Architecture Guide

## 📋 Overview

AyeRecipes iOS app utiliza una arquitectura **MVVM (Model-View-ViewModel)** con separación clara de responsabilidades. Los archivos están organizados por funcionalidad (Feature-Based Structure) para mejorar mantenibilidad, escalabilidad y testabilidad.

---

## 📁 Estructura de Carpetas

```
AyeRecipes/
│
├── 🚀 App/                          # Punto de entrada y configuración global
│   ├── AyeRecipesApp.swift         # Main app entry point
│   └── ContentView.swift            # Root navigation (si aplica)
│   └── MainTabView.swift            # Tab navigation controller
│
├── 📋 Models/                       # Structs puros (data models)
│   └── Recipe.swift                # Datos de recetas
│   └── User.swift                  # Datos de usuario (opcional)
│
├── 🎨 Views/                        # Todo el código de UI
│   ├── Auth/                       # Flujo de autenticación
│   │   └── LoginView.swift
│   │   └── RegisterView.swift      # (Opcional)
│   │
│   ├── Recipes/                    # Gestión de recetas
│   │   ├── CreateRecipeView.swift
│   │   ├── RecipesListView.swift
│   │   └── RecipeDetailView.swift
│   │
│   ├── Home/                       # Vista principal
│   │   └── HomeView.swift
│   │
│   └── Components/                 # Componentes reutilizables
│       ├── RecipeSummaryCard.swift
│       └── (Otros componentes)
│
├── 🌐 Services/                     # Lógica de negocio y APIs
│   ├── AuthService.swift           # Manejo de autenticación
│   ├── RecipeService.swift         # Operaciones de recetas
│   ├── ImageService.swift          # Descarga y caché de imágenes
│   │
│   └── Providers/                  # Configuración de APIs
│       └── AyeRecipesAPI.swift    # Endpoints y URLs
│
├── 🔧 Managers/                     # Gestión de APIs del sistema
│   ├── HapticManager.swift         # Feedback háptico
│   └── PermissionManager.swift     # Permisos del sistema
│
├── 🛠️  Utils/                       # Utilidades y extensiones
│   ├── Extensions/                 # Extensiones de tipos (opcional)
│   │   ├── String+Extensions.swift
│   │   └── Date+Extensions.swift
│   │
│   └── Helpers/                    # Funciones de apoyo
│       └── Constants.swift         # Constantes globales
│
└── 📱 Resources/                    # Assets y configuración
    ├── Assets.xcassets
    └── Preview Content/
```

---

## 🎯 Responsabilidades por Carpeta

### **App/** - Punto de Entrada
- Inicialización de la aplicación
- Configuración global
- Navigation root

**Archivos:**
- `AyeRecipesApp.swift` - @main app entry point

### **Models/** - Datos Puros
- Structs Codable para API
- No contienen lógica de negocio
- Conforman protocolos como Identifiable, Codable

**Archivos:**
- `Recipe.swift` - Modelo de receta

### **Views/** - Interfaz de Usuario
Organizados por **características** (feature-based), no por tipo de vista.

**Sub-carpetas:**
- `Auth/` - Vistas de autenticación
- `Recipes/` - Operaciones con recetas
- `Home/` - Vista principal
- `Components/` - Componentes compartidos

**Características:**
- Contienen @StateObject, @EnvironmentObject
- Llaman a Services
- No contienen lógica de API

### **Services/** - Lógica de Negocio
Clases ObservableObject que manejan datos y API calls.

**Archivos:**
- `AuthService.swift` - Login, Register, Logout
- `RecipeService.swift` - CRUD de recetas
- `ImageService.swift` - Descarga y caché de imágenes

**Características:**
- @MainActor para thread-safety
- Async/await para network calls
- Manejo de errores y estados

### **Services/Providers/** - Configuración de APIs
Constantes y configuración de endpoints.

**Archivos:**
- `AyeRecipesAPI.swift` - URLs base y endpoints

### **Managers/** - APIs del Sistema
Gestión de hardware y sistemas del dispositivo.

**Archivos:**
- `HapticManager.swift` - Feedback háptico (vibración)
- `PermissionManager.swift` - Permisos del sistema (cámara, fotos)

**Características:**
- Singletons (@MainActor final class)
- Interfaz simplificada para sistemas complejos
- Manejo de errores de hardware

### **Utils/** - Utilidades Generales
Extensiones, helpers y constantes reutilizables.

**Sub-carpetas:**
- `Extensions/` - Métodos adicionales en tipos existentes
- `Helpers/` - Funciones de apoyo general

---

## 🔄 Flujo de Datos

```
View (UI) 
  ↓ (Llama a)
Service (Lógica) 
  ↓ (Usa)
Provider/Manager (APIs/Hardware)
  ↓ (Retorna)
Service (Modifica estado)
  ↓ (@Published)
View (Se actualiza)
```

### Ejemplo: Crear una Receta

1. **Vista** (`CreateRecipeView.swift`)
   ```swift
   @EnvironmentObject var recipeService: RecipeService
   
   await recipeService.createRecipe(...)
   ```

2. **Servicio** (`RecipeService.swift`)
   ```swift
   func createRecipe(...) async -> Bool {
       let url = "\(AyeRecipesAPI.baseURL)/recipes"
       // Lógica de creación
   }
   ```

3. **Proveedor** (`Providers/AyeRecipesAPI.swift`)
   ```swift
   static let baseURL = "https://fixedayerecipesapi.ayeapps.tech/api"
   ```

---

## 🏗️ Patrones Implementados

### **Singleton Pattern**
Managers y Services comparten instancias únicas:
```swift
HapticManager.shared  // Acceso global
RecipeService()       // Instancia por vista
```

### **ObservableObject + @Published**
Los Services publican cambios de estado:
```swift
@MainActor
class RecipeService: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
}
```

### **@MainActor**
Garantiza ejecución en Main Thread:
```swift
@MainActor
class AuthService: ObservableObject {
    // Todos los métodos corren en Main Thread
}
```

### **Async/Await**
Operaciones de red sin callbacks:
```swift
func fetchRecipes() async {
    let (data, response) = try await URLSession.shared.data(for: request)
}
```

### **Lazy Loading**
Permisos se solicitan bajo demanda:
```swift
// En PermissionManager
func requestCameraPermission() async -> Bool {
    // Solo solicita cuando es necesario
}
```

---

## 📦 Convenciones de Nombres

| Tipo | Sufijo | Ejemplo |
|------|--------|---------|
| Vista | `View` | `LoginView`, `RecipeDetailView` |
| Componente pequeño | `Card`, `Row`, `Cell` | `RecipeSummaryCard` |
| Servicio | `Service` | `RecipeService`, `AuthService` |
| Gestor | `Manager` | `HapticManager`, `PermissionManager` |
| Modelo | (Ninguno) | `Recipe`, `User` |
| Proveedor | `API` | `AyeRecipesAPI` |

---

## 🔐 Seguridad

### Token Management
```swift
// AuthService maneja tokens
private let tokenKey = "authToken"

// RecipeService los usa
if let token = authToken {
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}
```

### Manejo de Errores
```swift
@Published var errorMessage: String?

// En vistas
if let error = service.errorMessage {
    Text("Error: \(error)")
}
```

---

## 🧪 Testing

La estructura facilita testing:

```swift
// Mock Service para tests
class MockRecipeService: ObservableObject {
    @Published var recipes: [Recipe] = []
    
    func fetchRecipes() async {
        recipes = [Recipe(/* mock data */)]
    }
}

// En preview
#Preview {
    RecipesListView()
        .environmentObject(MockRecipeService())
}
```

---

## 📚 Referencias de Archivos

### **Core Services**
- [AuthService](Services/AuthService.swift) - Autenticación
- [RecipeService](Services/RecipeService.swift) - Recetas
- [ImageService](Services/ImageService.swift) - Imágenes

### **Managers**
- [HapticManager](Managers/HapticManager.swift) - Feedback háptico
- [PermissionManager](Managers/PermissionManager.swift) - Permisos

### **Providers**
- [AyeRecipesAPI](Services/Providers/AyeRecipesAPI.swift) - Endpoints

---

## 🚀 Mejores Prácticas

✅ **Hacer:**
- Separar lógica de UI en Services
- Usar @Published para cambios de estado
- Aplicar @MainActor para thread-safety
- Usar async/await para network calls
- Agrupar vistas por características

❌ **NO Hacer:**
- Lógica de API directamente en vistas
- Usar DispatchQueue.main.async innecesariamente
- Mezclar tipos en carpetas
- Hard-codeando URLs

---

## 📝 Guía de Adición de Nuevas Funcionalidades

### Para agregar una nueva pantalla:

1. **Crear Vista** → `Views/[Feature]/[FeatureName]View.swift`
2. **Crear Servicio** (si necesita datos) → `Services/[Feature]Service.swift`
3. **Crear Modelo** (si es necesario) → `Models/[Feature].swift`
4. **Vincular en Views** con `@EnvironmentObject`

### Para agregar un nuevo endpoint:

1. **Agregar URL** en `Providers/AyeRecipesAPI.swift`
2. **Crear método** en Service correspondiente
3. **Usar en Vista** mediante EnvironmentObject

---

## 🤝 Contribución

Para mantener consistencia:
- Sigue la estructura de carpetas
- Usa sufijos de nombres correctos
- Asigna @MainActor a clases que manejan UI state
- Documenta métodos públicos
- Usa async/await (no callbacks)

---

**Última actualización:** Enero 2026  
**Versión:** 1.0
