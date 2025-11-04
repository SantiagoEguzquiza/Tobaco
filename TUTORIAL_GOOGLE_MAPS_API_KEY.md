# 🗺️ Tutorial: Obtener Google Maps API Key GRATIS

## ⏱️ Tiempo Total: 15 minutos

---

## 📋 Paso 1: Acceder a Google Cloud Console (2 min)

1. **Ir a:** https://console.cloud.google.com/
2. **Iniciar sesión** con tu cuenta de Google (Gmail)
3. Si es primera vez:
   - Acepta los Términos de Servicio
   - Selecciona tu país
   - Acepta las notificaciones (opcional)

---

## 🎯 Paso 2: Crear Proyecto (3 min)

1. **Click en el selector de proyectos** (arriba a la izquierda, al lado de "Google Cloud")
2. **Click en "Nuevo Proyecto"** (botón arriba a la derecha)
3. **Configurar proyecto:**
   ```
   Nombre del proyecto: Tobaco App
   Organización: Sin organización
   ```
4. **Click en "Crear"**
5. **Esperar** 10-20 segundos a que se cree
6. **Seleccionar** el proyecto recién creado

---

## 🔌 Paso 3: Habilitar APIs (5 min)

1. En el menú lateral izquierdo, busca **"APIs y servicios"**
2. Click en **"Biblioteca"** (Library)
3. **Habilitar las siguientes APIs:**

### API 1: Maps SDK for Android
   - Buscar: "Maps SDK for Android"
   - Click en el resultado
   - Click en **"HABILITAR"**
   - Esperar unos segundos

### API 2: Maps SDK for iOS (opcional para desarrollo)
   - Buscar: "Maps SDK for iOS"
   - Click en el resultado
   - Click en **"HABILITAR"**

### API 3: Geocoding API (para convertir direcciones a coordenadas)
   - Buscar: "Geocoding API"
   - Click en el resultado
   - Click en **"HABILITAR"**

✅ **Listo!** Las APIs están habilitadas

---

## 🔑 Paso 4: Crear API Key (3 min)

1. En el menú lateral, ve a **"APIs y servicios"** → **"Credenciales"**
2. Click en **"+ CREAR CREDENCIALES"** (arriba)
3. Selecciona **"Clave de API"**
4. **¡Se creará tu API Key!** 🎉

### 📋 Copiar la API Key

Verás algo como:
```
AIzaSyDXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

**¡CÓPIALA AHORA!** Necesitarás pegarla en tu código.

### 🔐 Restricciones (Importante para Producción)

**Para desarrollo:** Puedes usarla sin restricciones

**Para producción (recomendado):**
1. Click en el nombre de la API Key que acabas de crear
2. En "Restricciones de aplicación":
   - Selecciona "Aplicaciones de Android"
   - Click en "Agregar una aplicación"
   - **Nombre del paquete:** `com.example.tobaco` (o el tuyo)
   - **SHA-1:** (ver cómo obtenerlo abajo)
3. En "Restricciones de API":
   - Selecciona "Restringir clave"
   - Marca: Maps SDK for Android, Maps SDK for iOS, Geocoding API
4. Click en **"GUARDAR"**

---

## 📱 Paso 5: Configurar en tu App Android (2 min)

### Abrir AndroidManifest.xml
```
Ruta: android/app/src/main/AndroidManifest.xml
```

### Buscar línea 47:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE" />
```

### Reemplazar con tu API Key:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyDXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" />
```

### ⚠️ IMPORTANTE:
- No compartas tu API Key públicamente
- No la subas a repositorios públicos de GitHub
- Si la subes por error, revócala y crea una nueva

---

## 🍎 Paso 6: Configurar en iOS (Opcional - 2 min)

Solo si vas a compilar para iOS:

### 6.1 Editar AppDelegate.swift

**Archivo:** `ios/Runner/AppDelegate.swift`

**Agregar al inicio:**
```swift
import GoogleMaps
```

**Modificar el método `application`:**
```swift
import UIKit
import Flutter
import GoogleMaps  // ← Agregar esto

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ⬇️ Agregar esta línea
    GMSServices.provideAPIKey("AIzaSyDXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 🧪 Paso 7: Probar (5 min)

### 7.1 Reconstruir la app
```bash
cd TobacoFrontend
flutter clean
flutter pub get
flutter run
```

### 7.2 Abrir Mapa de Entregas
- Inicia sesión en la app
- Ve al menú principal
- Click en "Mapa de Entregas" 🗺️

### 7.3 Verificar
✅ El mapa debería cargar correctamente (sin marca de agua)
✅ No más errores de timeout en la consola
✅ Puedes hacer zoom, mover el mapa, etc.

---

## 🎁 Beneficios de la Versión GRATIS

Google Maps ofrece **$200 USD de crédito GRATIS** cada mes, que incluye:

| Servicio | Crédito Gratis Mensual | Equivale a |
|----------|------------------------|------------|
| Maps SDK for Android | $200 USD | ~28,000 cargas de mapa |
| Geocoding API | $200 USD | ~40,000 geocodificaciones |
| Directions API | $200 USD | ~40,000 rutas |

**Para la mayoría de las apps pequeñas/medianas, esto es SUFICIENTE y SIEMPRE GRATIS.**

---

## 🛡️ Seguridad: Restricciones de API Key

### Para Desarrollo (Ahora):
- ✅ Sin restricciones
- ✅ Funciona inmediatamente
- ⚠️ No subir a GitHub público

### Para Producción (Más tarde):

#### Opción 1: Restricción por Aplicación Android
```
1. Obtener SHA-1 de tu app
2. Restringir por nombre de paquete + SHA-1
```

**Obtener SHA-1:**
```bash
cd android
./gradlew signingReport
```

Busca algo como:
```
SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
```

#### Opción 2: Restricción por IP (Si usas desde servidor)
```
1. Obtener IP estática de tu servidor
2. Agregar IPs permitidas
```

---

## 🆘 Problemas Comunes

### ❌ Problema 1: "This page can't load Google Maps correctly"
**Causa:** API Key no configurada o incorrecta  
**Solución:** 
- Verifica que copiaste la API Key completa
- Verifica que no hay espacios extras
- Verifica que está en la línea correcta del AndroidManifest.xml

### ❌ Problema 2: "API key not found"
**Causa:** AndroidManifest.xml no actualizado  
**Solución:**
- Verifica que guardaste el archivo
- Ejecuta: `flutter clean && flutter pub get`
- Recompila la app

### ❌ Problema 3: Mapa gris o en blanco
**Causa:** APIs no habilitadas en Google Cloud  
**Solución:**
- Ve a Google Cloud Console
- Verifica que "Maps SDK for Android" esté habilitado
- Espera 1-2 minutos para que se active

### ❌ Problema 4: "Esta API no está habilitada"
**Causa:** Proyecto incorrecto o API no habilitada  
**Solución:**
- Verifica que estás en el proyecto correcto (arriba a la izquierda)
- Habilita todas las APIs del Paso 3

---

## 💰 Monitoreo de Costos (Opcional)

Para estar tranquilo y monitorear el uso:

1. Ve a: https://console.cloud.google.com/billing
2. Selecciona tu proyecto
3. Ve a "Presupuestos y alertas"
4. Crea una alerta cuando gastes $50 (o lo que quieras)

**Nota:** Con $200 USD gratis al mes, es difícil pasarse a menos que tengas miles de usuarios.

---

## 🎯 Resumen Rápido (1 minuto)

Si no quieres leer todo, aquí está lo esencial:

```
1. Ir a: console.cloud.google.com
2. Crear proyecto "Tobaco App"
3. Habilitar "Maps SDK for Android"
4. Ir a Credenciales → Crear API Key
5. Copiar la API Key
6. Pegar en: android/app/src/main/AndroidManifest.xml línea 47
7. Reemplazar: YOUR_API_KEY_HERE con tu key
8. flutter clean && flutter run
9. ¡Listo! 🎉
```

---

## 📞 Links Útiles

- **Google Cloud Console:** https://console.cloud.google.com/
- **Documentación Google Maps:** https://developers.google.com/maps/documentation
- **Precios:** https://mapsplatform.google.com/pricing/
- **Calculadora de costos:** https://cloud.google.com/products/calculator

---

## ✅ Checklist Final

Antes de continuar, verifica:

- [ ] Tienes cuenta de Google (Gmail)
- [ ] Proyecto creado en Google Cloud
- [ ] Maps SDK for Android habilitado
- [ ] API Key creada y copiada
- [ ] API Key pegada en AndroidManifest.xml (línea 47)
- [ ] Archivo guardado
- [ ] `flutter clean` ejecutado
- [ ] App recompilada

**Si todos los checks están ✅, tu mapa funcionará perfectamente!** 🎉

---

**¡Éxito con tu implementación!** 🚀

