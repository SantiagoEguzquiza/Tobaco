# Guía de Migración del Módulo Cache

## Resumen de Cambios

El módulo Cache ha sido refactorizado para seguir el principio de Single Responsibility, separando las responsabilidades en servicios específicos.

## Nueva Estructura

```
Cache/
├── core/
│   ├── cache_interface.dart      # Interfaz base ICacheService
│   ├── database_helper.dart       # Helper genérico de SQLite (sin lógica de negocio)
│   └── cache_manager.dart         # Orquestador/fachada principal
│
├── data/
│   ├── clientes_cache_service.dart
│   ├── productos_cache_service.dart
│   ├── categorias_cache_service.dart
│   ├── ventas_cache_service.dart         # Ventas del servidor
│   └── ventas_offline_cache_service.dart # Ventas pendientes
│
└── sync/
    ├── sync_manager.dart
    ├── ventas_sync_service.dart
    └── sync_status_model.dart
```

## Cambios Principales

### 1. DatabaseHelper (core/database_helper.dart)
- **Antes**: Tenía lógica de negocio específica para ventas offline
- **Ahora**: Solo proporciona operaciones CRUD genéricas sin lógica de negocio

### 2. CacheManager (core/cache_manager.dart)
- **Antes**: Mezclaba múltiples responsabilidades y manejaba varias tablas
- **Ahora**: Actúa como fachada/orquestador que delega a servicios específicos

### 3. Servicios Específicos (data/)
- Cada servicio maneja UNA sola entidad
- Todos implementan `ICacheService<T>`
- Responsabilidad única y clara

### 4. Servicios de Sincronización (sync/)
- `SyncManager`: Orquestador de sincronización
- `VentasSyncService`: Maneja específicamente la sincronización de ventas

## Migración de Código

### Antes:
```dart
import 'package:tobaco/Services/Cache/cache_manager.dart';

// Usar métodos directos
await CacheManager().cacheClientes(clientes);
await CacheManager().cacheProductos(productos);
```

### Después:
```dart
import 'package:tobaco/Services/Cache/cache_exports.dart';

// Usar CacheManager como fachada (recomendado)
await CacheManager().cacheClientes(clientes);
await CacheManager().cacheProductos(productos);

// O usar servicios directamente si se necesita más control
final clientesService = ClientesCacheService();
await clientesService.saveAll(clientes);
```

### DatabaseHelper

**Antes:**
```dart
import 'package:tobaco/Services/Cache/database_helper.dart';

await DatabaseHelper().saveVentaOffline(venta);
await DatabaseHelper().getPendingVentas();
```

**Después:**
```dart
import 'package:tobaco/Services/Cache/cache_exports.dart';

// Usar VentasOfflineCacheService
final offlineService = VentasOfflineCacheService();
await offlineService.saveWithLocalId(venta);
await offlineService.getPendingVentas();

// O usar CacheManager
await CacheManager().saveVentaOffline(venta);
await CacheManager().getPendingVentas();
```

### Sincronización

**Antes:**
```dart
import 'package:tobaco/Services/Sync/simple_sync_service.dart';

await SimpleSyncService().sincronizarAhora();
```

**Después:**
```dart
import 'package:tobaco/Services/Cache/cache_exports.dart';

final syncManager = SyncManager();
await syncManager.syncAll();

// O usar VentasSyncService directamente
final ventasSync = VentasSyncService();
await ventasSync.syncPendingVentas();
```

## Archivos que Requieren Actualización

1. **main.dart**: Actualizar import de DatabaseHelper
2. **ventas_provider.dart**: Actualizar imports y uso de servicios
3. **ventas_offline_service.dart**: Actualizar imports y uso de servicios
4. **clientes_provider.dart**: Actualizar imports de DatosCacheService
5. **productos_provider.dart**: Actualizar imports de DatosCacheService
6. **categoria_provider.dart**: Actualizar imports de DatosCacheService
7. **entregas_provider.dart**: Actualizar imports de DatabaseHelper
8. **simple_sync_service.dart**: Actualizar para usar nuevos servicios

## Notas Importantes

1. Los archivos antiguos (`database_helper.dart`, `cache_manager.dart`, `datos_cache_service.dart`, etc.) en la raíz de Cache/ deben mantenerse temporalmente durante la migración para no romper el código existente.

2. La nueva estructura mantiene compatibilidad con las bases de datos existentes gracias al uso de `CREATE TABLE IF NOT EXISTS`.

3. Todos los servicios implementan `ICacheService<T>`, lo que permite tratarlos de manera uniforme.

4. El `CacheManager` actúa como fachada, manteniendo una API similar a la anterior para facilitar la migración.

## Estado de Migración

- ✅ Estructura de carpetas creada
- ✅ Interfaz ICacheService creada
- ✅ DatabaseHelper genérico creado
- ✅ Todos los servicios de datos creados
- ✅ CacheManager como orquestador creado
- ✅ Servicios de sincronización creados
- ⏳ Actualización de referencias en el código (en progreso)
- ⏳ Verificación y pruebas (pendiente)
