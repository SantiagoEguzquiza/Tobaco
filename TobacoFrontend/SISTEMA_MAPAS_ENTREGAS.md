# 🗺️ Sistema de Mapas y Entregas - Documentación Completa

## 📋 Índice
1. [Introducción](#introducción)
2. [Configuración Inicial](#configuración-inicial)
3. [Características Implementadas](#características-implementadas)
4. [Arquitectura del Sistema](#arquitectura-del-sistema)
5. [Guía de Uso](#guía-de-uso)
6. [API Backend Requerida](#api-backend-requerida)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Introducción

Sistema completo de mapas y gestión de entregas para repartidores, con funcionalidades offline y tracking en tiempo real.

### ✨ Funcionalidades Principales

✅ **Ver ubicación actual**
- Geolocalización en tiempo real con GPS
- Marcador "📍 Tú estás aquí"
- Actualización continua de posición

✅ **Mostrar clientes en el mapa**
- Marcadores visuales con colores según estado
- Info window con nombre y dirección
- Detalles completos al tocar marcador

✅ **Ruta optimizada**
- Algoritmo del vecino más cercano
- Polylines (líneas punteadas) mostrando ruta
- Cálculo de distancias y tiempos

✅ **Navegación inteligente**
- Botón "Siguiente cliente" automático
- Centrado automático en entregas
- Vista panorámica de todas las entregas

✅ **Resumen del día**
- Entregas completadas/pendientes
- Distancia total recorrida
- Tiempo estimado restante
- Porcentaje de completitud

✅ **Funcionalidad offline**
- Entregas guardadas en SQLite
- Sincronización automática cuando hay conexión
- Estados persistentes

---

## ⚙️ Configuración Inicial

### 1. Obtener API Key de Google Maps

#### Paso 1: Crear proyecto en Google Cloud Console
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Ve a "APIs & Services" → "Library"

#### Paso 2: Habilitar APIs necesarias
Habilita las siguientes APIs:
- ✅ Maps SDK for Android
- ✅ Maps SDK for iOS
- ✅ Geocoding API
- ✅ Geolocation API

#### Paso 3: Crear credenciales
1. Ve a "APIs & Services" → "Credentials"
2. Click en "Create Credentials" → "API Key"
3. Copia la API Key generada
4. **IMPORTANTE**: Restringe la API Key:
   - Para Android: agrega la huella SHA-1 y el package name
   - Para iOS: agrega el Bundle ID

### 2. Configurar API Key en la App

#### Android
Edita `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI" />
```

#### iOS
Edita `ios/Runner/AppDelegate.swift` y agrega:

```swift
import GoogleMaps

override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    GMSServices.provideAPIKey("TU_API_KEY_AQUI")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

### 3. Instalar Dependencias

```bash
flutter pub get
```

Las dependencias necesarias ya están en `pubspec.yaml`:
- `google_maps_flutter: ^2.5.0`
- `geolocator: ^13.0.1`
- `geocoding: ^3.0.0`
- `sqflite: ^2.3.0`

### 4. Permisos Configurados

#### Android (`AndroidManifest.xml`)
✅ ACCESS_FINE_LOCATION
✅ ACCESS_COARSE_LOCATION
✅ ACCESS_BACKGROUND_LOCATION
✅ INTERNET

#### iOS (`Info.plist`)
✅ NSLocationWhenInUseUsageDescription
✅ NSLocationAlwaysAndWhenInUseUsageDescription
✅ NSLocationAlwaysUsageDescription
✅ UIBackgroundModes (location)

---

## 🏗️ Características Implementadas

### 1️⃣ Modelos de Datos

#### `Entrega.dart`
```dart
class Entrega {
  int? id;
  int ventaId;
  Cliente cliente;
  double? latitud;
  double? longitud;
  EstadoEntrega estado;
  DateTime fechaAsignacion;
  DateTime? fechaEntrega;
  int? repartidorId;
  int orden;
  String? notas;
  double? distanciaDesdeUbicacionActual;
}
```

### 2️⃣ Servicios

#### `UbicacionService`
- `obtenerPosicionActual()` - GPS actual
- `iniciarSeguimientoUbicacion()` - Tracking continuo
- `calcularDistancia()` - Entre dos puntos
- `geocodificarDireccion()` - Dirección → Coordenadas
- `ordenarEntregasPorCercania()` - Ordenamiento inteligente
- `calcularRutaOptima()` - Algoritmo vecino más cercano

#### `EntregasService`
- `obtenerEntregasDelDia()` - Carga entregas (online/offline)
- `marcarComoEntregada()` - Completar entrega
- `actualizarEstadoEntrega()` - Cambiar estado
- `sincronizarEntregasPendientes()` - Sync con servidor
- `obtenerEstadisticasDelDia()` - Resumen diario

#### `EntregasProvider` (State Management)
- Gestión centralizada de estado con Provider
- Tracking de ubicación en tiempo real
- Cache local de entregas
- Sincronización automática

### 3️⃣ Base de Datos Local (SQLite)

Tabla `entregas_offline`:
```sql
CREATE TABLE entregas_offline (
  id INTEGER PRIMARY KEY,
  venta_id INTEGER NOT NULL,
  cliente_id INTEGER NOT NULL,
  cliente_nombre TEXT NOT NULL,
  cliente_direccion TEXT,
  latitud REAL,
  longitud REAL,
  estado INTEGER NOT NULL DEFAULT 0,
  fecha_asignacion TEXT NOT NULL,
  fecha_entrega TEXT,
  repartidor_id INTEGER,
  orden INTEGER NOT NULL DEFAULT 0,
  notas TEXT,
  distancia_desde_ubicacion_actual REAL,
  sync_status TEXT NOT NULL DEFAULT 'synced',
  pendiente_sincronizar INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### 4️⃣ Pantalla del Mapa

#### Componentes Visuales

**Mapa Principal**
- Google Maps integrado
- Marcadores de colores por estado:
  - 🔴 Rojo: No entregada
  - 🟠 Naranja: Parcial
  - 🟢 Verde: Entregada
  - 🔵 Azul: Ubicación actual

**Panel Superior**
- Contador de pendientes
- Contador de completadas
- Distancia total

**Botones Flotantes**
- 📍 Centrar en ubicación actual
- 🗺️ Ver todas las entregas
- 📊 Mostrar/ocultar resumen

**Botón Principal**
- "Siguiente cliente" - Navega a próxima entrega

**Panel de Resumen** (desplegable)
- Total entregas del día
- Completadas/Pendientes/Parciales
- Distancia total recorrida
- Tiempo estimado restante

**Sheet de Detalles** (modal)
- Información del cliente
- Dirección completa
- Distancia desde ubicación actual
- Campo de notas
- Botón "Marcar como Entregado"

---

## 📱 Guía de Uso

### Para Repartidores

#### 1. Iniciar Jornada
```dart
// En el main.dart o donde inicialices providers
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => EntregasProvider(
        entregasService: EntregasService(
          authService: authService,
          connectivityService: connectivityService,
          databaseHelper: DatabaseHelper(),
        ),
        ubicacionService: UbicacionService(),
      ),
    ),
  ],
  child: MyApp(),
)
```

#### 2. Navegar a Mapa de Entregas
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MapaEntregasScreen(),
  ),
);
```

#### 3. Flujo de Trabajo

**Paso 1**: El mapa carga automáticamente:
- Tu ubicación actual
- Entregas del día desde servidor/cache
- Ruta optimizada

**Paso 2**: Navegación
- Toca "Siguiente cliente" para ir a la próxima entrega
- O toca cualquier marcador para ver detalles

**Paso 3**: Completar Entrega
- Toca el marcador del cliente
- Revisa los detalles
- Agrega notas si es necesario
- Presiona "Marcar como Entregado"
- Confirma la acción

**Paso 4**: Continuar
- El sistema automáticamente te sugiere el siguiente cliente
- Repite hasta completar todas las entregas

**Paso 5**: Fin del Día
- Revisa el resumen completo
- Sincroniza entregas pendientes si hubo problemas de conexión

---

## 🔌 API Backend Requerida

### Endpoints Necesarios

#### 1. Obtener Entregas del Día
```
GET /api/Entregas/mis-entregas
Headers: Authorization: Bearer {token}

Response:
[
  {
    "id": 1,
    "ventaId": 123,
    "clienteId": 456,
    "cliente": {
      "id": 456,
      "nombre": "Supermercado Los Álamos",
      "direccion": "Av. España 1234",
      "telefono": 123456789
    },
    "latitud": -25.2812,
    "longitud": -57.6358,
    "estado": 0,
    "fechaAsignacion": "2024-01-15T08:00:00Z",
    "fechaEntrega": null,
    "repartidorId": 1,
    "orden": 1,
    "notas": null
  }
]
```

#### 2. Actualizar Estado de Entrega
```
PUT /api/Entregas/{id}/estado
Headers: Authorization: Bearer {token}
Content-Type: application/json

Body:
{
  "estado": 2,
  "fechaEntrega": "2024-01-15T10:30:00Z"
}

Response: 200 OK
```

#### 3. Completar Entrega
```
POST /api/Entregas/{id}/completar
Headers: Authorization: Bearer {token}
Content-Type: application/json

Body:
{
  "notas": "Cliente no estaba, se dejó con vecino",
  "fechaEntrega": "2024-01-15T10:30:00Z"
}

Response: 200 OK
```

#### 4. Agregar Notas
```
PUT /api/Entregas/{id}/notas
Headers: Authorization: Bearer {token}
Content-Type: application/json

Body:
{
  "notas": "Edificio con portero, tocar timbre 5B"
}

Response: 200 OK
```

### Modelo Backend (C#)

```csharp
public class Entrega
{
    public int Id { get; set; }
    public int VentaId { get; set; }
    public Venta Venta { get; set; }
    public int ClienteId { get; set; }
    public Cliente Cliente { get; set; }
    public double? Latitud { get; set; }
    public double? Longitud { get; set; }
    public EstadoEntrega Estado { get; set; }
    public DateTime FechaAsignacion { get; set; }
    public DateTime? FechaEntrega { get; set; }
    public int? RepartidorId { get; set; }
    public User? Repartidor { get; set; }
    public int Orden { get; set; }
    public string? Notas { get; set; }
}

public enum EstadoEntrega
{
    NoEntregada = 0,
    Parcial = 1,
    Entregada = 2
}
```

---

## 🐛 Troubleshooting

### Problema: El mapa no carga

**Solución 1**: Verificar API Key
- Asegúrate de que la API key esté correctamente configurada
- Verifica que las APIs estén habilitadas en Google Cloud Console
- Revisa las restricciones de la API key

**Solución 2**: Verificar permisos
```bash
# Android
adb shell pm list permissions | grep LOCATION

# iOS
Revisar en Configuración → Privacidad → Ubicación
```

### Problema: No se obtiene la ubicación

**Solución 1**: Verificar GPS
- Asegúrate de que el GPS esté habilitado en el dispositivo
- En emulador, simula una ubicación

**Solución 2**: Permisos en tiempo de ejecución
- La app solicitará permisos al usuario
- Asegúrate de aceptar cuando se solicite

### Problema: Entregas no se sincronizan

**Solución 1**: Verificar conectividad
```dart
final hasConnection = await connectivityService.hasConnection();
print('Conexión: $hasConnection');
```

**Solución 2**: Forzar sincronización
```dart
final provider = Provider.of<EntregasProvider>(context, listen: false);
int sincronizadas = await provider.sincronizar();
print('$sincronizadas entregas sincronizadas');
```

### Problema: Marcadores no aparecen

**Solución**: Verificar coordenadas
- Los clientes deben tener latitud y longitud válidas
- Usa geocodificación para convertir direcciones:

```dart
final coords = await ubicacionService.geocodificarDireccion(
  cliente.direccion
);
if (coords != null) {
  entrega.latitud = coords['latitud'];
  entrega.longitud = coords['longitud'];
}
```

---

## 📊 Métricas y Estadísticas

El sistema rastrea automáticamente:

- ✅ Total de entregas asignadas
- ✅ Entregas completadas
- ✅ Entregas pendientes
- ✅ Entregas parciales
- ✅ Distancia total recorrida
- ✅ Tiempo estimado de entrega
- ✅ Porcentaje de completitud

Estas métricas se pueden obtener con:

```dart
final stats = await provider.obtenerEstadisticas();
print('Completadas: ${stats['completadas']}');
print('Distancia: ${stats['distanciaTotal']} km');
print('Porcentaje: ${stats['porcentajeCompletado']}%');
```

---

## 🔄 Próximas Mejoras (Post-MVP)

- [ ] Integración con Google Directions API para rutas reales
- [ ] Optimización avanzada con algoritmos genéticos
- [ ] Notificaciones push al llegar cerca de cliente
- [ ] Chat con clientes
- [ ] Fotografías de comprobante de entrega
- [ ] Firma digital del cliente
- [ ] Historial de rutas realizadas
- [ ] Análisis de rendimiento del repartidor
- [ ] Predicción de tiempos con Machine Learning

---

## 📝 Notas Finales

### Rendimiento
- El tracking en tiempo real consume batería
- Considera pausar el tracking cuando no hay entregas activas
- La sincronización offline es eficiente y no duplica datos

### Seguridad
- La API key debe estar restringida por:
  - Aplicación (Bundle ID / Package Name)
  - SHA-1 fingerprint
  - IPs permitidas (si es servidor)

### Costos de Google Maps
- Google Maps API tiene cuota gratuita mensual
- Monitorea el uso en Google Cloud Console
- Considera implementar cache de geocodificación

---

## 🆘 Soporte

Si encuentras problemas:
1. Revisa los logs de la consola
2. Verifica la configuración de permisos
3. Asegúrate de que el backend esté funcionando
4. Revisa la conectividad de red

---

**Desarrollado para Tobaco App**  
Sistema de Gestión de Entregas v1.0  
Última actualización: Octubre 2024

