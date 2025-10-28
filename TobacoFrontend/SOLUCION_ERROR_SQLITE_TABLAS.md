# Solución Errores: "no such table" en SQLite

## 🔴 Problemas

Al intentar usar el sistema de ventas offline, aparecen errores:

### Error 1:
```
SqfliteDatabaseException (no such table: ventas_offline (code 1 SQLITE_ERROR)
```

### Error 2:
```
DatabaseException(no such table: ventas_cache (code 1 SQLITE_ERROR): , while compiling: DELETE FROM ventas_cache)
```

Estos errores ocurren cuando las bases de datos SQLite fueron creadas antes de implementar las tablas necesarias para el sistema offline.

## ✅ Solución Automática (Implementada)

El sistema ahora **verifica automáticamente** que las tablas existan antes de usarlas:

### Para `tobaco_offline.db` (ventas_offline):
1. **En `database_helper.dart`**: 
   - Agregado método `ensureTablesExist()` - Verifica si las tablas están creadas
   - Agregado método `resetDatabase()` - Resetea la BD si faltan tablas
2. **En `ventas_offline_service.dart`**: 
   - Se llama a `ensureTablesExist()` durante la inicialización

### Para `tobaco_cache.db` (ventas_cache):
1. **En `cache_manager.dart`**: 
   - Agregado método `ensureTablesExist()` - Verifica si las tablas están creadas
   - Agregado método `resetDatabase()` - Resetea la BD si faltan tablas
2. **En `ventas_offline_service.dart`**: 
   - Se llama a `ensureTablesExist()` antes de cachear o leer ventas

Si las tablas no existen, se **resetea automáticamente** la base de datos correspondiente y se crean las tablas correctas.

## 🔧 Solución Manual (Si la automática falla)

Si por alguna razón la solución automática no funciona, puedes resetear manualmente la base de datos:

### Opción 1: Desinstalar y reinstalar la app
1. Desinstala la aplicación completamente del dispositivo/emulador
2. Vuelve a instalar la aplicación
3. Las bases de datos se crearán desde cero con las tablas correctas

### Opción 2: Limpiar datos de la app (Android)
1. Ve a **Configuración** → **Aplicaciones**
2. Busca la app **Tobaco**
3. Toca **Almacenamiento**
4. Toca **Borrar datos** (esto eliminará las bases de datos)
5. Vuelve a abrir la app

### Opción 3: Usar método resetDatabase() (Desarrollo)

Si estás desarrollando, puedes agregar temporalmente un botón para resetear:

```dart
// En alguna pantalla de configuración/desarrollo:
import 'package:tobaco/Services/Cache/database_helper.dart';
import 'package:tobaco/Services/Cache/cache_manager.dart';

// Agregar un botón:
ElevatedButton(
  onPressed: () async {
    try {
      // Resetear base de datos offline
      final dbHelper = DatabaseHelper();
      await dbHelper.resetDatabase();
      
      // Resetear base de datos de caché
      final cacheManager = CacheManager();
      await cacheManager.resetDatabase();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Bases de datos reseteadas correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  },
  child: Text('Resetear BD'),
)
```

## 📦 Bases de datos en el sistema

El sistema usa **DOS bases de datos SQLite** diferentes:

### 1. `tobaco_offline.db` (DatabaseHelper)
- Maneja ventas creadas offline (pendientes de sincronización)
- Tablas:
  - `ventas_offline` - Ventas pendientes de subir al servidor
  - `ventas_productos_offline` - Productos de ventas offline
  - `ventas_pagos_offline` - Pagos de ventas offline

### 2. `tobaco_cache.db` (CacheManager)
- Caché de datos del servidor para uso offline
- Tablas:
  - `clientes_cache` - Clientes del servidor
  - `productos_cache` - Productos del servidor
  - `categorias_cache` - Categorías del servidor
  - `ventas_cache` - Ventas del servidor (para ver offline)
  - `ventas_cache_productos` - Productos de ventas cacheadas

## 🚀 Flujo del Sistema Offline

### Cuando hay conexión:
1. Se crea la venta en el servidor ✅
2. Se actualizan las ventas en `ventas_cache` (CacheManager) 💾
3. Se sincronizan ventas pendientes de `ventas_offline` (si hay) 🔄

### Cuando NO hay conexión:
1. Se guarda la venta en `ventas_offline` (DatabaseHelper) 💾
2. Se muestra mensaje: "Venta guardada localmente"
3. Se sincronizará automáticamente cuando haya conexión 🔄

### Al listar ventas:
1. Intenta obtener del servidor (timeout 5 segundos)
2. Si falla, usa `ventas_cache` 📦
3. Combina con ventas de `ventas_offline` 🔀

## ✅ Verificación

Después de aplicar la solución, verifica en los logs:

### Para ventas offline:
```
🔍 DatabaseHelper: Verificando tablas...
✅ DatabaseHelper: Tablas existen correctamente
✅ VentasOfflineService: Inicializado correctamente
📊 VentasOfflineService: Estado inicial - X pendientes, Y fallidas
```

### Para caché de ventas:
```
🔍 CacheManager: Verificando tablas...
✅ CacheManager: Tablas existen correctamente
💾 VentasOfflineService: Ventas guardadas en caché para uso offline
```

Si ves estos mensajes, ambas bases de datos están funcionando correctamente.

## ⚠️ IMPORTANTE

### Al resetear `tobaco_offline.db`:
- ❌ ELIMINA todas las ventas offline pendientes de sincronización
- ❌ ELIMINA historial de ventas sincronizadas/fallidas

### Al resetear `tobaco_cache.db`:
- ❌ ELIMINA caché de clientes, productos, categorías
- ❌ ELIMINA caché de ventas del servidor

### Antes de resetear:
Si tienes ventas importantes sin sincronizar:
1. Conecta el backend
2. Deja que se sincronicen automáticamente
3. Verifica que se sincronizaron (contador de pendientes = 0)
4. Luego resetea si es necesario

