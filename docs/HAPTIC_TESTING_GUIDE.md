# 🧪 Testing Práctico: Verificación de HapticManager

## 📋 Quick Reference

```bash
# Ver todos los logs de HapticManager
xcrun simctl spawn booted log stream --predicate \
  'eventMessage contains[cd] "HapticManager"' --level debug

# Ver errores de XPC haptic
xcrun simctl spawn booted log stream --predicate \
  'eventMessage contains[cd] "hapticd"' --level debug

# Ver logs de CHHapticEngine
xcrun simctl spawn booted log stream --predicate \
  'eventMessage contains[cd] "CHHapticEngine"' --level debug

# Todos los logs relacionados con haptics
xcrun simctl spawn booted log stream --predicate \
  'eventMessage contains[cd] "haptic"' --level debug
```

---

## ✅ Test 1: Verificación de Creación Única

### Código de Test

```swift
struct HapticDebugView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Test: Singleton")
                .font(.headline)
            
            Button("Verificar Singleton") {
                let manager1 = HapticManager.shared
                let manager2 = HapticManager.shared
                let manager3 = HapticManager.shared
                
                print("Manager1 === Manager2: \(manager1 === manager2)")
                print("Manager2 === Manager3: \(manager2 === manager3)")
                print("Todas son la misma instancia: \(manager1 === manager2 && manager2 === manager3)")
                
                // Esperado: true (la misma instancia siempre)
            }
            .buttonStyle(.bordered)
            .padding()
            
            Divider()
            
            Text("Status del Motor")
                .font(.subheadline)
            
            HStack {
                Text("Available:")
                Spacer()
                Text("\(HapticManager.shared.isAvailable ? "✅" : "❌")")
            }
            .padding()
            
            HStack {
                Text("Running:")
                Spacer()
                Text("\(HapticManager.shared.isEngineRunning ? "✅" : "❌")")
            }
            .padding()
        }
    }
}
```

### Resultado Esperado

```
Manager1 === Manager2: true      // ✅ Mismo objeto
Manager2 === Manager3: true      // ✅ Mismo objeto
Todas son la misma instancia: true

Status del Motor:
Available: ✅                    // ✅ Hardware soporta
Running: ❌                      // ✅ Standby (no en uso)
```

---

## ✅ Test 2: Múltiples Reproducciones

### Código de Test

```swift
struct HapticMultiplePlayTest: View {
    @State private var testCount = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Test: Múltiples Reproducciones")
                .font(.headline)
            
            Text("Cuenta: \(testCount)")
                .font(.title2)
            
            Button("Tapa (Simple Feedback)") {
                testCount += 1
                HapticManager.shared.playSimpleFeedback()
            }
            .buttonStyle(.bordered)
            
            Button("Tapa x10 Rápido") {
                for _ in 0..<10 {
                    testCount += 1
                    HapticManager.shared.playSimpleFeedback()
                }
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.red)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Pruebas:")
                    .font(.subheadline)
                    .bold()
                
                Text("1. Tapa el botón simple varias veces (2 segundos entre taps)")
                    .font(.caption)
                    .lineLimit(2)
                
                Text("2. Tapa el botón 'x10 Rápido' para enviar 10 comandos simultáneamente")
                    .font(.caption)
                    .lineLimit(2)
                
                Text("3. Abre Console.app y monitorea:")
                    .font(.caption)
                    .lineLimit(1)
                
                Text("xcrun simctl spawn booted log stream --predicate 'eventMessage contains[cd] \"Feedback háptico\"' --level debug")
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(3)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}
```

### Resultado Esperado

```
Console Output:
✅ Feedback háptico simple generado (x10 veces)
❌ NO deberías ver: "connection to service was invalidated"
❌ NO deberías ver: "CHHapticEngine error"

Comportamiento:
✓ 10 taps rápidos funcionan sin problemas
✓ Sin delays o congelamiento
✓ El motor se reutiliza cada vez
✓ Sin crear nuevas instancias
```

---

## ✅ Test 3: Estados Predefinidos

### Código de Test

```swift
struct HapticPresetTest: View {
    var body: some View {
        VStack(spacing: 15) {
            Text("Test: Estados Predefinidos")
                .font(.headline)
            
            Button(action: {
                HapticManager.shared.playSimpleFeedback()
            }) {
                Label("Simple Feedback", systemImage: "hand.tap.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            Button(action: {
                HapticManager.shared.playSuccess()
            }) {
                Label("Success (3 pulsos)", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            
            Button(action: {
                HapticManager.shared.playError()
            }) {
                Label("Error (vibración baja)", systemImage: "xmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            
            Button(action: {
                HapticManager.shared.playSelection()
            }) {
                Label("Selection (toque)", systemImage: "hand.thumbsup.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Instrucciones:")
                    .font(.subheadline)
                    .bold()
                
                Text("1. Prueba cada botón uno por uno")
                    .font(.caption)
                
                Text("2. Siente las diferencias de vibración:")
                    .font(.caption)
                    .bold()
                
                HStack {
                    Text("• Simple: Un pulso único")
                        .font(.caption)
                }
                
                HStack {
                    Text("• Success: 3 pulsos crecientes")
                        .font(.caption)
                }
                
                HStack {
                    Text("• Error: Vibración prolongada baja")
                        .font(.caption)
                }
                
                HStack {
                    Text("• Selection: Pulso muy ligero")
                        .font(.caption)
                }
                
                Text("3. Monitorea Console para ver qué tipo de evento se generó")
                    .font(.caption)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}
```

### Resultado Esperado

```
Console Output:
✅ Feedback de éxito generado        (playSuccess)
✅ Feedback de error generado        (playError)
✅ Feedback de selección generado    (playSelection)
✅ Feedback háptico simple generado  (playSimpleFeedback)

Sensación en el dispositivo:
✓ Simple: 1 vibración fuerte
✓ Success: 3 vibraciones pequeñas progresivas (tap-tap-tap ↑)
✓ Error: 1 vibración prolongada más suave
✓ Selection: 1 vibración muy ligera
```

---

## ✅ Test 4: Verificación de Logging

### Código de Monitoreo

```bash
#!/bin/bash

# Abrir múltiples consolas monitoreando diferentes aspectos

echo "🎯 HapticManager Testing Suite"
echo "═════════════════════════════════════════"
echo ""
echo "Abre las siguientes consolas en terminales diferentes:"
echo ""

echo "Terminal 1 - HapticManager logs:"
echo "xcrun simctl spawn booted log stream --predicate 'eventMessage contains[cd] \"HapticManager\"' --level debug"
echo ""

echo "Terminal 2 - CHHapticEngine logs:"
echo "xcrun simctl spawn booted log stream --predicate 'eventMessage contains[cd] \"CHHapticEngine\"' --level debug"
echo ""

echo "Terminal 3 - Todos los haptic logs:"
echo "xcrun simctl spawn booted log stream --predicate 'eventMessage contains[cd] \"haptic\"' --level debug"
echo ""

echo "Luego ejecuta el app en Xcode y prueba los botones."
echo ""
```

### Logs Esperados

```
✅ CORRECTO:
───────────────────────────────────────────────
CHHapticEngine creado exitosamente
CHHapticEngine iniciado
Feedback háptico simple generado
✅ CHHapticEngine iniciado
Feedback de éxito generado
Feedback de error generado
✅ CHHapticEngine detenido
```

```
❌ INCORRECTO (No deberías ver esto):
───────────────────────────────────────────────
Error creando CHHapticEngine
connection to service was invalidated
AVHapticClient error
RBSServiceErrorDomain
XPC timeout
service crashed unexpectedly
```

---

## ✅ Test 5: Stress Test

### Código de Test (Extremo)

```swift
struct HapticStressTest: View {
    @State private var isRunning = false
    @State private var feedbackCount = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("⚠️  STRESS TEST")
                .font(.headline)
                .foregroundStyle(.red)
            
            Text("Cuenta: \(feedbackCount)")
                .font(.title2)
                .monospacedDigit()
            
            if isRunning {
                ProgressView()
                Text("Enviando feedback rápidamente...")
                    .font(.caption)
            }
            
            Button(isRunning ? "Parar" : "Iniciar Stress Test") {
                if isRunning {
                    isRunning = false
                } else {
                    runStressTest()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(isRunning ? .red : .orange)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Este test envía 100 comandos de haptic feedback lo más rápido posible.")
                    .font(.caption)
                
                Text("Si el sistema es estable:")
                    .font(.caption)
                    .bold()
                
                Text("✅ Todos los 100 se completarán")
                    .font(.caption)
                
                Text("✅ No habrá crashes XPC")
                    .font(.caption)
                
                Text("✅ El motor se reutilizará constantemente")
                    .font(.caption)
                
                Text("❌ Si NO es estable:")
                    .font(.caption)
                    .bold()
                
                Text("❌ Se verá 'connection invalidated' en logs")
                    .font(.caption)
                
                Text("❌ La app crasheará")
                    .font(.caption)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func runStressTest() {
        isRunning = true
        feedbackCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<100 {
                HapticManager.shared.playSimpleFeedback(
                    intensity: Float.random(in: 0.3...1.0)
                )
                
                Task { @MainActor in
                    feedbackCount = i + 1
                }
                
                // Delay variable para simular uso real
                usleep(UInt32.random(in: 10000...50000))
            }
            
            Task { @MainActor in
                isRunning = false
            }
        }
    }
}
```

### Resultado Esperado

```
✅ ÉXITO:
───────────────────────────────────────────────
Cuenta: 100                      (todos completados)
Console: Sin errores XPC        (solo logs normales)
App: Responsiva durante test    (sin congelamiento)

❌ FALLO:
───────────────────────────────────────────────
Cuenta: 45 (se quedó en medio)
Console: "connection invalidated"
App: Se congela o crashea
```

---

## ✅ Test 6: Dispositivo vs Simulador

### En Simulador

```bash
# El simulador actual NO soporta haptic feedback
# Por eso verás:

Console Output:
⚠️  Haptic feedback no soportado en este dispositivo
isAvailable = false

Comportamiento:
✅ Sin crashes (HapticManager los maneja)
✅ Los botones responden pero sin vibración
✅ Logs limpios (sin errores)
```

### En Dispositivo Físico

```bash
# En un iPhone/iPad CON haptic engine

Console Output:
✅ CHHapticEngine creado exitosamente
✅ CHHapticEngine iniciado
✅ Feedback háptico simple generado
isAvailable = true

Comportamiento:
✅ Vibraciones claras y consistentes
✅ Sin crashes
✅ Respuesta inmediata
```

---

## 📋 Checklist de Verificación

### ☑️ Pre-implementación

- [ ] HapticManager.swift existe en ios-app/AyeRecipes/
- [ ] CreateRecipeViewWithHaptics.swift existe en ios-app/AyeRecipes/Views/
- [ ] HAPTIC_FEEDBACK_GUIDE.md documentado
- [ ] El proyecto compila sin errores

### ☑️ Compilación

- [ ] Compilar en Xcode (Cmd+B)
- [ ] Sin errores de sintaxis
- [ ] Sin warnings relacionados con haptics
- [ ] Sin linker errors

### ☑️ Runtime

- [ ] App se abre sin crashes
- [ ] Botones responden a taps
- [ ] Si device soporta haptics: vibraciones presentes
- [ ] Si simulator: isAvailable=false (correcto)

### ☑️ Logging

- [ ] Console.app muestra logs de HapticManager
- [ ] Sin errores de XPC
- [ ] Sin "connection invalidated"
- [ ] Sin "AVHapticClient error"

### ☑️ Funcionalidad

- [ ] Test 1: Singleton funciona (manager1 === manager2)
- [ ] Test 2: Múltiples taps no causan crashes
- [ ] Test 3: playSuccess/Error/Selection funcionan
- [ ] Test 4: Logs son limpios y informativos
- [ ] Test 5: Stress test (100 taps) no causa crashes

### ☑️ Integración

- [ ] Importar en MainTabView
- [ ] Integrar en botones principales
- [ ] Feedback en éxito/error de operaciones
- [ ] Testing final en dispositivo

---

## 🐛 Debugging si algo no funciona

### Problema: "No veo ningún log"

```bash
# Verifica que estés ejecutando el stream correcto
xcrun simctl spawn booted log stream --predicate \
  'eventMessage contains[cd] "Haptic"' --level debug

# Asegúrate de que el simulador esté corriendo
xcrun simctl list | grep Booted
```

### Problema: "isAvailable = false en dispositivo"

```swift
// Verificar soporte en tu dispositivo
let capabilities = CHHapticEngine.capabilitiesForHardware()
print("Supports haptics: \(capabilities.supportsHaptics)")

// iPhones sin haptic engine:
// - iPhone 5/5s/5c/6/6+
// - iPhone XR (tiene Taptic Engine pero limitado)

// iPhones con haptic engine completo:
// - iPhone 6s y posteriores
// - Todos los iPhone 7+
```

### Problema: "Crashes intermitentes"

```
Posible causa: No estás usando HapticManager.shared
Solución: Reemplazar TODAS las instancias de:

❌ let engine = try CHHapticEngine()
✅ HapticManager.shared.playSimpleFeedback()
```

### Problema: "Lag o delays"

```swift
// Verifica que no tengas operaciones pesadas:

// ❌ NO HAGAS:
HapticManager.shared.playSimpleFeedback()
let largeComputation = performExpensiveCalculation()

// ✅ HAZ:
HapticManager.shared.playSimpleFeedback()
// Los logs dicen que se reproduce sin delays
```

---

## 📊 Template de Reporte de Problemas

Si algo no funciona, recopila:

```
HapticManager Diagnostic Report
═════════════════════════════════════════════

Device:
- [ ] Simulador / Dispositivo
- [ ] Modelo: _______________
- [ ] iOS: _______________

Estado del Motor:
- [ ] isAvailable: true / false
- [ ] isEngineRunning: true / false

Error Observado:
───────────────────────────────────────────
[Copiar/pegar el error exacto aquí]

Console Logs:
───────────────────────────────────────────
[Copiar/pegar los últimos 20 líneas de logs]

Acciones Realizadas:
───────────────────────────────────────────
1. [ ] Test 1: Singleton verificado
2. [ ] Test 2: Múltiples taps funcionan
3. [ ] Test 3: Estados predefinidos OK
4. [ ] Test 4: Logging visible
5. [ ] Test 5: Stress test completado

Pasos para reproducir:
───────────────────────────────────────────
1. _______________
2. _______________
3. _______________

Comportamiento esperado:
───────────────────────────────────────────
[Describir]

Comportamiento observado:
───────────────────────────────────────────
[Describir]

Screenshots/Videos:
───────────────────────────────────────────
[Adjuntar si es posible]
```

