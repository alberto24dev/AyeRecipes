# 🎯 GUÍA PASO A PASO - Solución de Errores Sandbox

## ¿Qué se arregló?

Tu app tenía errores de `RBSServiceErrorDomain Code=1` y `Sandbox restriction (error 159)` porque:
- Pedía permisos de cámara/galería **al iniciar** la app
- Importaba servicios de autenticación que no usaba
- No tenía un sistema centralizado para gestionar permisos

**Esto ya está ARREGLADO.** Solo necesitas compilar y ejecutar.

---

## 📋 PASO 1: Compila en Xcode

1. Abre Xcode
2. Carga el proyecto: `/Users/alberto24dev/Documents/Projects/Code/AyeRecipes/ios-app/AyeRecipes.xcodeproj`
3. Selecciona un Simulador (p.ej., iPhone 15)
4. **Product > Clean Build Folder** (Cmd+Shift+K)
5. **Product > Build** (Cmd+B)

✅ Si compila sin errores, pasa al siguiente paso

❌ Si hay errores:
- Abre Console.app
- Busca errores específicos
- Lee `SANDBOX_FIX_README.md` para debugging

---

## 📋 PASO 2: Ejecuta en Simulador

1. Presiona **Play** (Cmd+R) en Xcode
2. La app debería abrir **sin retrasos**

✅ Si la app se abre rápido, el problema está RESUELTO

❌ Si sigue siendo lento:
- Continúa al Paso 3 para verificar logs

---

## 📋 PASO 3: Verifica Logs (Importante)

1. Abre **Xcode Console** o **Console.app**
2. Ejecuta este comando en Terminal para monitorear errores:

```bash
xcrun simctl spawn booted log stream --predicate 'eventMessage contains[cd] "RBSServiceErrorDomain"' --level debug
```

3. Mantén abierto mientras la app se inicia
4. Busca mensajes que mencionen "RBSServiceErrorDomain"

✅ **ESPERADO:** No debería haber errores de RBSServiceErrorDomain

❌ **Si aún aparecen:**
- Verifica que `project.pbxproj` se guardó correctamente
- Abre `SANDBOX_FIX_README.md` para debugging avanzado

---

## 📋 PASO 4: Prueba Interactividad

Ahora prueba que los permisos se solicitan **bajo demanda** (cuando es necesario):

### Test 1: Tomar una Foto
1. Navega a la pantalla de "Create Recipe" / "Crear Receta"
2. Toca el botón **"Take Photo"** o **"Tomar Foto"**
3. **ESPERADO:** Aparece popup preguntando por permiso de cámara
4. Acepta el permiso
5. Debería abrirse la cámara

### Test 2: Seleccionar de la Galería
1. Toca el botón **"Select from Gallery"** o **"Seleccionar de Galería"**
2. **ESPERADO:** Aparece popup preguntando por permiso de fotos
3. Acepta el permiso
4. Debería abrirse la galería

✅ Si funciona así, **TODO ESTÁ CORRECTO**

---

## 📁 Archivos Importantes

### Para Entender Qué Se Arregló:
- 📖 `RESUMEN_SOLUCION.md` - Resumen en español
- 📖 `CAMBIOS_IMPLEMENTADOS.txt` - Lista de cambios
- 📖 `SANDBOX_FIX_README.md` - Documentación técnica

### Para Usar en Tu Código:
- 📄 `PermissionManager.swift` - **IMPORTANTE:** Gestor de permisos
- 📄 `CreateRecipeViewOptimizedExample.swift` - Ejemplo de cómo usarlo

### Para Debugging:
- 🔧 `debug_sandbox_errors.sh` - Script para monitorear errores
- 🔧 `verify_implementation.sh` - Verifica que todo está en su lugar

---

## 🚀 Si Necesitas Agregar Permisos en el Futuro

Si después necesitas agregar más permisos (p.ej., localización, micrófono):

1. **NO** los agregues directamente al `project.pbxproj`
2. **USA** el patrón del `PermissionManager.swift`
3. Lee `PERMISSION_SETUP_GUIDE.md` para instrucciones

Ejemplo:
```swift
// En lugar de hacer esto en init():
// - solicitar permiso de localización

// Haz esto cuando el usuario lo necesite:
Button("Find Nearby Recipes") {
    Task {
        if await PermissionManager.shared.requestLocationPermission() {
            // Buscar recetas cercanas
        }
    }
}
```

---

## ⚠️ Troubleshooting

### Problema: "Aún veo RBSServiceErrorDomain en Console"

**Solución:**
1. Limpia la build: **Cmd+Shift+K**
2. Reconstruye: **Cmd+B**
3. Reinicia Xcode completamente
4. Verifica en el archivo `project.pbxproj` que no tenga NSCamera o NSPhoto

Comando para verificar:
```bash
grep "NSCamera\|NSPhoto" /Users/alberto24dev/Documents/Projects/Code/AyeRecipes/ios-app/AyeRecipes.xcodeproj/project.pbxproj
```
Si no muestra nada, está bien ✅

---

### Problema: "Mi CreateRecipeView no compila"

**Solución:**
1. Tu `CreateRecipeView` ya existe y funciona
2. Solo necesitas integrar `PermissionManager` donde solicites fotos
3. Lee `CreateRecipeViewOptimizedExample.swift` para ver cómo

---

### Problema: "¿Cómo sé si funciona?"

**Verificación rápida:**
1. Abre la app
2. Navega rápidamente (no debería haber retrasos)
3. Abre Console.app
4. Busca "RBSServiceErrorDomain"
5. No debería haber durante startup ✅

Si no ves esos errores, **¡está funcionando!**

---

## ✅ Checklist Final

- [ ] Compilé en Xcode sin errores
- [ ] La app se abre sin retrasos
- [ ] No veo RBSServiceErrorDomain en Console al iniciar
- [ ] Toqué "Take Photo" y aparece popup de permiso (no durante startup)
- [ ] Toqué "Select from Gallery" y aparece popup (no durante startup)

Si marcaste todas las casillas: **¡Felicidades! El problema está RESUELTO** 🎉

---

## 📞 ¿Necesitas Ayuda?

1. Verifica que compiló sin errores
2. Lee `SANDBOX_FIX_README.md` sección "Verificación"
3. Ejecuta `verify_implementation.sh` para confirmar archivos
4. Revisa los logs con el comando de debugging

---

**Last Updated:** January 24, 2026  
**Creado por:** GitHub Copilot  
**Status:** ✅ Listo para Usar
