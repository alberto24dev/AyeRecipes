# 🎯 QUICK REFERENCE: HapticManager

## El Problema en una Línea
```
❌ CHHapticEngine se crea múltiples veces → muere → "connection was invalidated" → 💥
```

## La Solución en una Línea
```
✅ HapticManager.shared crea el motor UNA SOLA VEZ → vive siempre → sin crashes
```

---

## Cómo Usarlo (Copia y Pega)

```swift
// En cualquier Button, TextField, etc.
Button("Mi Botón") {
    HapticManager.shared.playSimpleFeedback()
    // Tu código aquí
}

// Estados predefinidos:
HapticManager.shared.playSuccess()      // ✅ 3 pulsos crecientes
HapticManager.shared.playError()        // ❌ Vibración baja
HapticManager.shared.playSelection()    // 👆 Toque ligero
```

---

## Archivos Importantes

| Archivo | Qué es | Acción |
|---------|--------|--------|
| [HapticManager.swift](ios-app/AyeRecipes/HapticManager.swift) | El código | Usar en app |
| [CreateRecipeViewWithHaptics.swift](ios-app/AyeRecipes/Views/CreateRecipeViewWithHaptics.swift) | Ejemplo completo | Copiar patrón |
| [HAPTIC_FEEDBACK_GUIDE.md](ios-app/HAPTIC_FEEDBACK_GUIDE.md) | Docs técnicas | Leer si tienes dudas |
| [HAPTIC_TESTING_GUIDE.md](HAPTIC_TESTING_GUIDE.md) | Tests | Seguir si no funciona |

---

## Verificación Rápida

```bash
# Test automático
bash debug_haptic_feedback.sh

# Monitorear logs
xcrun simctl spawn booted log stream --predicate \
  'eventMessage contains[cd] "HapticManager"' --level debug
```

---

## Los 5 Problemas (y cómo se arreglan)

| # | Problema | Antes | Después |
|---|----------|-------|---------|
| 1️⃣ | Múltiples instancias | ❌ Motor 1, Motor 2, Motor 3... | ✅ Motor Único (Singleton) |
| 2️⃣ | Motor muere | ❌ Se destruye variable local | ✅ Vive en clase singleton |
| 3️⃣ | Race conditions | ❌ start() + stop() simultáneos | ✅ Cola serializada |
| 4️⃣ | Sin verificación | ❌ Crash en simulador | ✅ Verifica isAvailable |
| 5️⃣ | Sin reconexión | ❌ Crash permanente si falla | ✅ Auto-recovery automático |

---

## Estado del Motor

```swift
// Puedes verificar el estado:
HapticManager.shared.isAvailable      // ¿Hardware soporta?
HapticManager.shared.isEngineRunning  // ¿Motor activo?

// Ejemplo:
if HapticManager.shared.isAvailable {
    HapticManager.shared.playSuccess()
} else {
    print("Este dispositivo no soporta haptics")
}
```

---

## Ciclo de Vida (Visual)

```
App Init → HapticManager.shared → Motor creado UNA VEZ
                ↓
           Motor vivo durante toda sesión
                ↓
    Usuario tapa botón → playSimpleFeedback()
    Usuario tapa botón → playSimpleFeedback()  (reutiliza motor)
    Usuario tapa botón → playSimpleFeedback()  (reutiliza motor)
                ↓
           App cierra → Motor limpiado
                ↓
            ✅ Sin crashes
```

---

## Debugging en 30 Segundos

```bash
# Terminal 1: Ejecutar app en Xcode (Cmd+R)

# Terminal 2: Ver logs
xcrun simctl spawn booted log stream --predicate \
  'eventMessage contains[cd] "HapticManager"' --level debug

# Deberías ver:
# ✅ CHHapticEngine creado exitosamente
# ✅ Feedback háptico simple generado
# ❌ NO deberías ver: "connection was invalidated"
```

---

## Errores Comunes

```swift
// ❌ MALO:
func playHaptic() {
    let engine = try CHHapticEngine()  // Se destruye al terminar
    // Motor muere aquí
}

// ✅ BUENO:
func playHaptic() {
    HapticManager.shared.playSimpleFeedback()  // Motor permanente
}

// ❌ MALO:
for i in 0..<10 {
    let engine = try CHHapticEngine()  // 10 motores diferentes
}

// ✅ BUENO:
for i in 0..<10 {
    HapticManager.shared.playSimpleFeedback()  // Mismo motor
}
```

---

## Integración Rápida (3 pasos)

### 1. Importar
```swift
// Ya está en HapticManager.swift
import CoreHaptics
```

### 2. Usar
```swift
Button("Mi Botón") {
    HapticManager.shared.playSimpleFeedback()
}
```

### 3. Testear
```bash
bash debug_haptic_feedback.sh
```

---

## Specs Técnicas

```
Tipo:            Singleton Pattern
Motor:           CHHapticEngine (creado una sola vez)
Thread-safe:     ✅ @MainActor + DispatchQueue
Auto-recovery:   ✅ resetHandler
Métodos:         playSimpleFeedback(), playSuccess(), 
                 playError(), playSelection()
Logging:         ✅ os.log con nivel debug
Estado:          isAvailable, isEngineRunning
```

---

## Preguntas Frecuentes

**P: ¿Por qué mi simulador no vibra?**
R: El simulador no soporta haptic feedback. Usa `if isAvailable { ... }` para manejar esto.

**P: ¿Puedo usar múltiples motores?**
R: No, iOS solo soporta uno. HapticManager maneja todos los patrones con uno solo.

**P: ¿Qué pasa si crashea?**
R: HapticManager detecta la desconexión XPC y automáticamente se reconecta (resetHandler).

**P: ¿Es thread-safe?**
R: Sí, @MainActor garantiza que todo ocurre en el thread principal.

**P: ¿Consume mucha batería?**
R: No, el motor entra en standby automáticamente cuando no se usa.

---

## Testing Rápido

```swift
// Copiar y pegar en CreateRecipeView para testear:

Button("Test Haptic") {
    HapticManager.shared.playSimpleFeedback()
}
.onAppear {
    // Verifica que el singleton funciona
    let m1 = HapticManager.shared
    let m2 = HapticManager.shared
    print("Mismo objeto: \(m1 === m2)")  // true
}
```

---

## Mapa Mental

```
HapticManager.shared
    │
    ├─ Properties
    │   ├─ engine: CHHapticEngine?          (motor único)
    │   ├─ isAvailable: Bool                (soporta hardware)
    │   └─ isEngineRunning: Bool            (está activo)
    │
    ├─ Lifecycle
    │   ├─ init()                           (crea motor UNA VEZ)
    │   ├─ prepareHapticEngine()            (prepara)
    │   ├─ setupEngineCallbacks()           (auto-recovery)
    │   └─ deinit                           (limpieza)
    │
    ├─ Operations
    │   ├─ startEngine()                    (idempotente)
    │   ├─ stopEngine()                     (seguro)
    │   └─ reconnectEngine()                (auto-recovery)
    │
    └─ Public API
        ├─ playSimpleFeedback()             (toque único)
        ├─ playSuccess()                    (3 pulsos)
        ├─ playError()                      (vibración baja)
        └─ playSelection()                  (toque ligero)
```

---

## Deployment Checklist

```
☑️ HapticManager.swift compilable
☑️ No hay imports faltantes
☑️ @MainActor está presente
☑️ Métodos públicos implementados
☑️ Logging configurado
☑️ Test 1 pasa (singleton)
☑️ Test 2 pasa (múltiples taps)
☑️ Test 3 pasa (estados)
☑️ Console logs limpios
☑️ Cero crashes XPC
```

---

## Referencia Rápida de Métodos

```swift
// Iniciar sesión
_ = HapticManager.shared  // Singleton se inicializa

// Reproducir feedback
HapticManager.shared.playSimpleFeedback()
HapticManager.shared.playSimpleFeedback(intensity: 0.5)

// Estados predefinidos
HapticManager.shared.playSuccess()      // ✅ 
HapticManager.shared.playError()        // ❌
HapticManager.shared.playSelection()    // 👆

// Verificar estado
print(HapticManager.shared.isAvailable)
print(HapticManager.shared.isEngineRunning)

// Patrones personalizados
let events = [CHHapticEvent(...)]
HapticManager.shared.playPattern(events: events)
```

---

## Links Importantes

- **Código:** [HapticManager.swift](ios-app/AyeRecipes/HapticManager.swift)
- **Template:** [CreateRecipeViewWithHaptics.swift](ios-app/AyeRecipes/Views/CreateRecipeViewWithHaptics.swift)
- **Docs:** [HAPTIC_FEEDBACK_GUIDE.md](ios-app/HAPTIC_FEEDBACK_GUIDE.md)
- **Índice:** [INDICE_HAPTIC.md](INDICE_HAPTIC.md)

---

## Última Verificación

```bash
# Antes de hacer commit:

✅ Archivo HapticManager.swift existe
✅ Archivo CreateRecipeViewWithHaptics.swift existe
✅ Proyecto compila sin errores
✅ Tests pasan sin crashes
✅ Console.app muestra logs esperados
✅ No aparecen "connection invalidated"

# Listo para producción ✅
```

