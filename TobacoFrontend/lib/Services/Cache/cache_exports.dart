/// Archivo de exportación centralizado para el módulo Cache
/// Facilita las importaciones en el resto de la aplicación
library;

// Core
export 'core/cache_interface.dart';
export 'core/database_helper.dart';
export 'core/cache_manager.dart';

// Data Services
export 'data/clientes_cache_service.dart';
export 'data/productos_cache_service.dart';
export 'data/categorias_cache_service.dart';
export 'data/ventas_cache_service.dart';
export 'data/ventas_offline_cache_service.dart';

// Sync Services
export 'sync/sync_manager.dart';
export 'sync/ventas_sync_service.dart';
export 'sync/sync_status_model.dart';
