# Sistema Offline Completo - Crear Ventas Sin Conexión

## 🎯 Objetivo

Permitir crear ventas **completamente offline** usando datos cacheados de clientes y productos.

## 📁 Archivos del Sistema

### 1. Servicios de Caché (3 bases de datos SQLite)

#### `datos_cache_service.dart` (NUEVO)
- **Base de datos**: `datos_cache.db`
- **Función**: Cachea clientes y productos para crear ventas offline
- **Tablas**:
  - `clientes_cache` - Clientes del servidor
  - `productos_cache` - Productos del servidor

#### `ventas_cache_service.dart`
- **Base de datos**: `ventas_simple_cache.db`
- **Función**: Cachea ventas del servidor para verlas offline
- **Tabla**:
  - `ventas_cache` - Ventas del servidor (solo lectura)

#### `ventas_offline_cache_service.dart` (NUEVO)
- **Base de datos**: `ventas_offline.db`
- **Función**: Guarda ventas creadas offline (pendientes de sincronización)
- **Tabla**:
  - `ventas_offline` - Ventas pendientes de subir al servidor

### 2. Providers Actualizados

#### `ClienteProvider` (SIMPLIFICADO)
```dart
obtenerClientes()
  ↓
Intenta servidor (timeout 3 seg)
  ↓
Si falla → Usa caché
  ↓
Retorna clientes
```

#### `ProductoProvider` (SIMPLIFICADO)
```dart
obtenerProductos()
  ↓
Intenta servidor (timeout 3 seg)
  ↓
Si falla → Usa caché
  ↓
Retorna productos
```

#### `VentasProvider` (MEJORADO)
```dart
crearVenta()
  ↓
Intenta crear online (timeout 3 seg)
  ↓
✅ Online: Guardar en servidor + actualizar caché
  ↓
❌ Offline: Guardar en ventas_offline
  ↓
Retorna {success, isOffline, message}
```

## 🔄 Flujo Completo

### Preparación (CON Backend):
```
1. Usuario abre lista de clientes
   → Cachea clientes automáticamente

2. Usuario abre lista de productos  
   → Cachea productos automáticamente

3. Usuario abre lista de ventas
   → Cachea ventas automáticamente
```

### Creación de Venta (SIN Backend):
```
1. Usuario va a "Nueva Venta"
   
2. Selecciona cliente
   → Se carga del caché ✅
   
3. Selecciona productos
   → Se cargan del caché ✅
   
4. Confirma la venta
   → Se guarda en ventas_offline ✅
   → Muestra mensaje: "Guardada offline" 📴
   
5. Muestra resumen de la venta ✅
```

### Sincronización (Cuando vuelva el backend):
```
⚠️ NOTA: Sincronización automática NO implementada aún
Necesitarás crear un servicio para:
1. Detectar cuando vuelve conexión
2. Leer ventas_offline
3. Enviar al servidor
4. Marcar como sincronizadas
```

## 🧪 Cómo Probar

### Paso 1: Cachear Datos (CON Backend)
```bash
# 1. Prende el backend
# 2. Abre la app
# 3. Ve a Clientes → Se cachean ✅
# 4. Ve a Productos → Se cachean ✅
# 5. Ve a Ventas → Se cachean ✅
```

**Logs esperados:**
```
✅ ClienteProvider: 50 clientes obtenidos del servidor
✅ DatosCacheService: 50 clientes guardados en caché

✅ ProductoProvider: 100 productos obtenidos del servidor
✅ DatosCacheService: 100 productos guardados en caché

✅ VentasProvider: 10 ventas obtenidas del servidor
✅ VentasCacheService: 10 ventas guardadas en caché
```

### Paso 2: Crear Venta Offline (SIN Backend)
```bash
# 1. APAGA el backend
# 2. Ve a "Nueva Venta"
# 3. Selecciona cliente (del caché) ✅
# 4. Selecciona productos (del caché) ✅
# 5. Confirma la venta
# 6. Verás mensaje: "Guardada offline" 📴
# 7. Se muestra el resumen ✅
```

**Logs esperados:**
```
⚠️ ClienteProvider: Error obteniendo del servidor: TimeoutException
✅ ClienteProvider: 50 clientes cargados del caché

⚠️ ProductoProvider: Error obteniendo del servidor: TimeoutException
✅ ProductoProvider: 100 productos cargados del caché

⚠️ VentasProvider: Error creando venta online: TimeoutException
📴 VentasProvider: Guardando venta offline...
✅ VentasOfflineCacheService: Venta guardada offline (ID: 1)
```

## 📊 Bases de Datos SQLite

### Resumen:
| Base de Datos | Propósito | Se actualiza cuando |
|---|---|---|
| `datos_cache.db` | Clientes y Productos para crear ventas offline | Al abrir lista de clientes/productos con backend |
| `ventas_simple_cache.db` | Ventas del servidor (solo ver) | Al abrir lista de ventas con backend |
| `ventas_offline.db` | Ventas creadas offline (pendientes) | Al crear venta sin backend |

## ⚠️ Limitaciones Actuales

1. ❌ **No hay sincronización automática** 
   - Las ventas offline NO se sincronizan automáticamente
   - Necesitas implementar un servicio de sincronización

2. ❌ **No hay indicador de ventas pendientes**
   - No se muestra cuántas ventas hay pendientes de sincronizar
   - Podrías agregar un badge en la UI

3. ❌ **No hay detección de conexión mejorada**
   - Solo usa timeout de 3 segundos
   - Podrías usar un connectivity checker más robusto

## 🚀 Características Actuales

✅ **Cacheo automático**: Clientes, productos y ventas se cachean automáticamente
✅ **Creación offline**: Puedes crear ventas sin backend
✅ **Resumen offline**: Se muestra el resumen de ventas offline
✅ **Mensajes claros**: Indica cuando la venta se guardó offline
✅ **Rápido**: Timeout de 3 segundos, carga rápida en offline
✅ **Robusto**: Si falla guardado offline, muestra error

## 💡 Próximos Pasos (Opcional)

### 1. Servicio de Sincronización Automática
```dart
// sync_service.dart
class SyncService {
  Future<void> sincronizarVentasPendientes() async {
    final pendientes = await offlineService.obtenerVentasPendientes();
    
    for (var ventaData in pendientes) {
      try {
        final venta = Ventas.fromJson(jsonDecode(ventaData['venta_json']));
        await ventasService.crearVenta(venta);
        await offlineService.marcarComoSincronizada(ventaData['id']);
      } catch (e) {
        print('Error sincronizando: $e');
      }
    }
  }
}
```

### 2. Badge de Ventas Pendientes
```dart
// En VentasScreen
FutureBuilder<int>(
  future: ventasProvider.contarVentasPendientes(),
  builder: (context, snapshot) {
    if (snapshot.data != null && snapshot.data! > 0) {
      return Badge(
        label: Text('${snapshot.data}'),
        child: Icon(Icons.cloud_off),
      );
    }
    return SizedBox.shrink();
  },
)
```

### 3. Botón Manual de Sincronización
```dart
IconButton(
  icon: Icon(Icons.sync),
  onPressed: () async {
    final count = await provider.contarVentasPendientes();
    if (count > 0) {
      // TODO: Sincronizar ventas pendientes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count ventas sincronizadas')),
      );
    }
  },
)
```

## 🎉 Resumen

Ahora tienes un sistema offline completo que permite:
1. ✅ Ver clientes, productos y ventas sin conexión
2. ✅ Crear ventas completamente offline
3. ✅ Las ventas se guardan localmente
4. ⏳ Sincronización manual (pendiente de implementar)

¡El sistema básico está funcional! 🚀

