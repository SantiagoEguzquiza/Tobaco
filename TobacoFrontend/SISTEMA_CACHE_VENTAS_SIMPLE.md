# Sistema de Caché de Ventas SIMPLE

## 🎯 Objetivo

Mostrar el listado de ventas incluso cuando el backend NO está disponible.

## ✅ Cómo Funciona

### 1. **Con Backend Disponible**
```
Usuario abre lista de ventas
    ↓
Obtiene ventas del servidor (timeout 8 segundos)
    ↓
Guarda en SQLite automáticamente
    ↓
Muestra las ventas
```

### 2. **Sin Backend (Offline)**
```
Usuario abre lista de ventas
    ↓
Intenta obtener del servidor (FALLA)
    ↓
Carga ventas del caché SQLite
    ↓
Muestra las ventas guardadas
```

## 📁 Archivos del Sistema

### 1. `ventas_cache_service.dart` (NUEVO)
- **Función**: Maneja el caché SQLite de forma simple
- **Tabla**: `ventas_cache` (guarda ventas como JSON)
- **Métodos**:
  - `guardarVentasEnCache()` - Guarda ventas del servidor
  - `obtenerVentasDelCache()` - Lee ventas guardadas
  - `resetearBaseDeDatos()` - Limpia todo

### 2. `ventas_provider.dart` (SIMPLIFICADO)
- **Función**: Obtiene ventas con fallback a caché
- **Lógica**:
```dart
try {
  // Intentar obtener del servidor
  ventas = await servidor.obtenerVentas();
  // Guardar en caché
  cache.guardar(ventas);
} catch {
  // Si falla, usar caché
  ventas = await cache.obtener();
}
```

### 3. `nuevaVenta_screen.dart` (SIMPLIFICADO)
- Crear venta ahora es simple: `bool success = await provider.crearVenta(venta)`
- Si tiene éxito, muestra resumen
- Si falla, muestra error

## 🧪 Cómo Probar

### Paso 1: Resetear Todo (IMPORTANTE)
```bash
# Desinstala la app completamente
# Esto elimina las bases de datos antiguas
```

### Paso 2: Instalar y Probar con Backend
```bash
# 1. Prende el backend
# 2. Instala la app
# 3. Ve a la lista de ventas
# 4. Deberías ver ventas del servidor
```

**En los logs verás:**
```
📡 VentasProvider: Intentando obtener ventas del servidor...
✅ VentasProvider: 5 ventas obtenidas del servidor
✅ VentasCacheService: 5 ventas guardadas en caché
```

### Paso 3: Probar Sin Backend (Modo Offline)
```bash
# 1. APAGA el backend
# 2. Cierra la app completamente
# 3. Abre la app de nuevo
# 4. Ve a la lista de ventas
# 5. Deberías ver las mismas ventas (del caché)
```

**En los logs verás:**
```
📡 VentasProvider: Intentando obtener ventas del servidor...
⚠️ VentasProvider: Error obteniendo del servidor: TimeoutException...
📦 VentasProvider: Cargando ventas del caché...
✅ VentasCacheService: 5 ventas obtenidas del caché
```

## 📊 Base de Datos

### Estructura Simple
```sql
CREATE TABLE ventas_cache (
  id INTEGER PRIMARY KEY,           -- ID de la venta del servidor
  venta_json TEXT NOT NULL,         -- Toda la venta en JSON
  cached_at TEXT NOT NULL           -- Cuándo se guardó
);
```

### Ubicación
- **Archivo**: `ventas_simple_cache.db`
- **Path**: En el directorio de bases de datos de la app
- **Tamaño**: ~1KB por venta (depende de cantidad de productos)

## 🔄 Actualización del Caché

El caché se actualiza automáticamente en estos casos:

1. **Al abrir lista de ventas** (si hay backend)
   - Obtiene ventas del servidor
   - Reemplaza todo el caché con las nuevas ventas

2. **Al crear una venta** (si hay backend)
   - Crea la venta en el servidor
   - Agrega la venta a la lista local
   - Guarda toda la lista actualizada en caché

## 🚨 Solución de Problemas

### Problema: No muestra ventas offline
**Solución:**
1. Desinstala la app
2. Instala de nuevo
3. CON backend prendido, abre la lista de ventas (para cachear)
4. Apaga el backend
5. Cierra y abre la app
6. Ahora debería mostrar del caché

### Problema: Muestra ventas viejas
**Solución:**
El caché se actualiza cada vez que abres la lista con backend disponible. Si ves ventas viejas, es porque el caché no se ha actualizado. Simplemente abre la lista con el backend prendido.

### Problema: Error de SQLite
**Solución:**
```dart
// En alguna pantalla temporal de debug:
import 'package:tobaco/Services/Cache/ventas_cache_service.dart';

ElevatedButton(
  onPressed: () async {
    final cache = VentasCacheService();
    await cache.resetearBaseDeDatos();
    print('✅ Caché reseteado');
  },
  child: Text('Resetear Caché'),
)
```

## 📝 Ventajas del Sistema Simple

✅ **Fácil de entender**: Solo un archivo de caché, una lógica clara
✅ **Sin complejidad**: No hay sincronización, estados, ni múltiples BDs
✅ **Funciona siempre**: Si antes viste ventas con backend, las verás offline
✅ **Actualización automática**: Cada vez que hay backend, se actualiza solo
✅ **Liviano**: Guarda todo como JSON, simple y rápido

## ⚠️ Limitaciones

- ❌ No permite crear ventas offline (solo ver)
- ❌ No sincroniza cambios automáticamente
- ❌ Solo muestra las últimas ventas que se vieron con backend

**Pero eso es exactamente lo que pediste:** Ver ventas offline, nada más.

## 🎯 Resumen

Este es un sistema **SIMPLE** y **FUNCIONAL** que hace exactamente lo que necesitas:
1. Guarda ventas cuando hay backend
2. Las muestra cuando NO hay backend
3. Sin complicaciones

Desinstala la app, reinstálala, y prueba. ¡Debería funcionar perfecto! 🚀

