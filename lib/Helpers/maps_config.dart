// Configuración de Google Maps/Directions
// 
// ⚠️ IMPORTANTE PARA DESARROLLADORES DESPUÉS DE PULL REQUEST:
// Si el mapa de entregas no abre, necesitas configurar tus propias API keys.
// 
// OPCIÓN 1 (Recomendada): Modificar este archivo directamente
// Reemplaza las keys de abajo con tus propias API keys de Google Maps
//
// OPCIÓN 2: Usar archivo local (ver maps_config.local.dart.example)
// 1. Copia "maps_config.local.dart.example" a "maps_config.local.dart"
// 2. Reemplaza las API keys en maps_config.local.dart
// 3. Descomenta y usa el import de abajo
//
// Para obtener tus API keys:
// 1. Ve a https://console.cloud.google.com/
// 2. Crea/selecciona un proyecto
// 3. Habilita "Maps SDK for Android" y "Directions API"
// 4. Ve a "Credenciales" → "Crear credenciales" → "Clave de API"
// 5. Configura restricciones: Package name + SHA-1 para Android
//
// También actualiza AndroidManifest.xml con tu googleMapsApiKey:
// android/app/src/main/AndroidManifest.xml → meta-data com.google.android.geo.API_KEY

// Descomenta esta línea si usas maps_config.local.dart:
// export 'maps_config.local.dart';

// Clave para Maps SDK (restringida por Android package + SHA1)
// ⚠️ REEMPLAZA CON TU PROPIA KEY
const String googleMapsApiKey = 'AIzaSyBlL9cN8XBrBN3MxdL47s8BXetJl89Jr2w';

// Clave separada para Directions Web Service (recomendado: SIN restricción de aplicación,
// pero restringida por API solo a "Directions API")
// ⚠️ REEMPLAZA CON TU PROPIA KEY
const String directionsApiKey = 'AIzaSyBprJG-DsdSH6Y8jSEHENDjiilaZwSJGvQ';
