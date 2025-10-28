# 📴 Sistema de Ventas Offline - Documentación Completa

## 📋 Descripción General

Sistema **offline-first** para la gestión de ventas que permite a los usuarios crear ventas sin conexión a internet o cuando el backend está caído. Las ventas se guardan localmente en SQLite y se sincronizan automáticamente cuando se restablece la conexión.

## 🎯 Características Principales

✅ **Modo Offline Completo**: Crea ventas sin conexión
✅ **Sincronización Automática**: Las ventas se envían al servidor cuando hay conexión
✅ **Sincronización Manual**: Botón para forzar sincronización
✅ **Manejo de Errores**: Reintento automático de ventas fallidas
✅ **Base de Datos Local**: SQLite para almacenamiento persistente
✅ **Detección de Conectividad**: Monitorea internet y disponibilidad del backend
✅ **UI Informativa**: Widgets visuales del estado de sincronización
✅ **Limpieza Automática**: Elimina ventas antiguas sincronizadas

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────┐
│           VentasProvider (UI Layer)             │
│  - Expone métodos a los Screens                │
│  - Notifica cambios con ChangeNotifier          │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│      VentasOfflineService (Business Logic)      │
│  - Decide: Online vs Offline                    │
│  - Coordina servicios                           │
└────┬─────────────┬──────────────┬───────────────┘
     │             │              │
┌────▼────┐  ┌─────▼─────┐  ┌────▼────────┐
│Ventas   │  │Sync       │  │Connectivity │
│Service  │  │Service    │  │Service      │
│(API)    │  │(Sync)     │  │(Monitor)    │
└─────────┘  └─────┬─────┘  └─────────────┘
                   │
         ┌─────────▼──────────┐
         │  DatabaseHelper    │
         │  (SQLite Local)    │
         └────────────────────┘
```

## 📂 Estructura de Archivos

```
lib/Services/
├── Ventas_Service/
│   ├── ventas_service.dart              # API calls al backend
│   ├── ventas_offline_service.dart      # Lógica offline-first ⭐
│   └── ventas_provider.dart             # Provider para UI ⭐
├── Connectivity/
│   └── connectivity_service.dart        # Monitoreo de conexión ⭐
├── Sync/
│   └── sync_service.dart                # Sincronización automática ⭐
└── Cache/
    └── database_helper.dart             # Base de datos SQLite ⭐

lib/Widgets/
└── sync_status_widget.dart              # Widgets UI para estado ⭐
```

## 🚀 Configuración e Instalación

### 1. Dependencias en `pubspec.yaml`

Ya están agregadas:
```yaml
dependencies:
  sqflite: ^2.3.0           # Base de datos local
  path: ^1.8.3              # Manejo de rutas
  connectivity_plus: ^5.0.2  # Detección de conectividad
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Inicializar en `main.dart`

```dart
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VentasProvider()..initialize(),
        ),
        // ... otros providers
      ],
      child: MyApp(),
    ),
  );
}
```

## 💻 Uso en el Código

### Crear una Venta (Offline-First)

```dart
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_offline_service.dart';

// En tu screen de nueva venta
Future<void> _guardarVenta() async {
  final ventasProvider = Provider.of<VentasProvider>(context, listen: false);
  
  // Crear objeto venta
  final venta = Ventas(
    clienteId: _cliente.id!,
    cliente: _cliente,
    ventasProductos: _productos,
    total: _calcularTotal(),
    fecha: DateTime.now(),
    metodoPago: _metodoPago,
    usuarioId: _usuarioActual.id,
  );

  try {
    // ⭐ Este método maneja automáticamente online/offline
    final result = await ventasProvider.crearVenta(venta);
    
    if (result.success) {
      if (result.isOffline) {
        // Venta guardada offline
        _mostrarMensaje(
          '✅ Venta guardada localmente. Se sincronizará cuando haya conexión.',
          Colors.orange,
        );
      } else {
        // Venta creada online
        _mostrarMensaje('✅ Venta creada exitosamente', Colors.green);
      }
      
      Navigator.pop(context);
    } else {
      _mostrarMensaje('❌ Error: ${result.message}', Colors.red);
    }
  } catch (e) {
    _mostrarMensaje('❌ Error: $e', Colors.red);
  }
}
```

### Mostrar Estado de Sincronización

```dart
import 'package:tobaco/Widgets/sync_status_widget.dart';

// En tu screen principal o de ventas
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Ventas'),
      actions: [
        // Badge en la barra de navegación
        SyncStatusBadge(),
        SizedBox(width: 16),
      ],
    ),
    body: Column(
      children: [
        // Widget de estado detallado
        SyncStatusWidget(showDetails: true),
        
        // Resto del contenido
        Expanded(
          child: _buildVentasList(),
        ),
      ],
    ),
  );
}
```

### Sincronización Manual

```dart
// Botón para sincronizar manualmente
ElevatedButton(
  onPressed: () async {
    final provider = Provider.of<VentasProvider>(context, listen: false);
    
    final result = await provider.sincronizarAhora();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  },
  child: Text('Sincronizar Ventas'),
)
```

### Monitorear Estado de Conexión

```dart
import 'package:provider/provider.dart';

// En tu widget
Widget build(BuildContext context) {
  return Consumer<VentasProvider>(
    builder: (context, ventasProvider, child) {
      final isConnected = ventasProvider.isConnected;
      final pendientes = ventasProvider.ventasPendientes;
      final fallidas = ventasProvider.ventasFallidas;
      
      return Column(
        children: [
          // Indicador de conexión
          Container(
            color: isConnected ? Colors.green : Colors.red,
            padding: EdgeInsets.all(8),
            child: Text(
              isConnected ? '✅ Conectado' : '❌ Sin conexión',
              style: TextStyle(color: Colors.white),
            ),
          ),
          
          // Estadísticas
          if (pendientes > 0)
            Text('📋 $pendientes ventas pendientes de sincronización'),
          if (fallidas > 0)
            Text('⚠️ $fallidas ventas con errores'),
        ],
      );
    },
  );
}
```

## 🔄 Flujo de Funcionamiento

### 1. Crear Venta con Conexión

```
Usuario crea venta
    ↓
¿Hay conexión? → Sí
    ↓
Enviar al backend
    ↓
¿Éxito? → Sí
    ↓
✅ Venta creada online
```

### 2. Crear Venta sin Conexión

```
Usuario crea venta
    ↓
¿Hay conexión? → No
    ↓
Guardar en SQLite local
    ↓
✅ Venta guardada offline
    ↓
(Cuando hay conexión)
    ↓
Sincronización automática
    ↓
Enviar al backend
    ↓
✅ Venta sincronizada
```

### 3. Error en Sincronización

```
Intento de sincronización
    ↓
❌ Error (timeout, 500, etc.)
    ↓
Marcar como "failed"
    ↓
Incrementar contador de intentos
    ↓
Esperar próximo ciclo de sync
    ↓
(Usuario puede forzar reintento)
```

## 🗄️ Esquema de Base de Datos SQLite

### Tabla: `ventas_offline`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | INTEGER | ID autoincremental local |
| `local_id` | TEXT | ID único local (ej: `local_1698765432000`) |
| `cliente_id` | INTEGER | ID del cliente |
| `cliente_json` | TEXT | JSON completo del cliente |
| `total` | REAL | Total de la venta |
| `fecha` | TEXT | Fecha ISO8601 |
| `sync_status` | TEXT | Estado: `pending`, `synced`, `failed` |
| `sync_attempts` | INTEGER | Número de intentos de sincronización |
| `error_message` | TEXT | Mensaje de error si falla |
| `created_at` | TEXT | Fecha de creación |
| `updated_at` | TEXT | Última actualización |

### Tabla: `ventas_productos_offline`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | INTEGER | ID autoincremental |
| `venta_local_id` | TEXT | FK a ventas_offline |
| `producto_id` | INTEGER | ID del producto |
| `nombre` | TEXT | Nombre del producto |
| `cantidad` | REAL | Cantidad vendida |
| `precio` | REAL | Precio unitario |
| `precio_final_calculado` | REAL | Precio con descuentos |

## 📊 Estados de Sincronización

| Estado | Descripción | Acción |
|--------|-------------|--------|
| `pending` | Pendiente de enviar | Se sincronizará automáticamente |
| `synced` | Sincronizada exitosamente | Se puede limpiar después de 30 días |
| `failed` | Falló la sincronización | Se puede reintentar manualmente |

## ⚙️ Configuración Avanzada

### Cambiar Intervalo de Sincronización

En `sync_service.dart`:
```dart
// Cambiar de 5 minutos a otro intervalo
_syncTimer = Timer.periodic(Duration(minutes: 10), (timer) async {
  // ...
});
```

### Cambiar Días de Retención

```dart
// Limpiar ventas sincronizadas después de 60 días
await ventasProvider.limpiarVentasAntiguas(dias: 60);
```

### Endpoint de Health Check

El `connectivity_service.dart` verifica la disponibilidad del backend en:
```
GET /api/health
```

**Necesitas agregar este endpoint en tu backend:**

```csharp
// En tu TobacoApi
[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new { status = "healthy" });
    }
}
```

## 🐛 Troubleshooting

### Problema: Ventas no se sincronizan

**Solución:**
1. Verificar que el backend tenga el endpoint `/api/health`
2. Verificar conectividad en el dispositivo
3. Ver logs en consola para errores específicos
4. Intentar sincronización manual

### Problema: Error "Database is locked"

**Solución:**
- SQLite solo permite una escritura a la vez
- El sistema ya maneja esto con transacciones
- Si persiste, reiniciar la aplicación

### Problema: Ventas duplicadas

**Solución:**
- El sistema previene duplicados con `local_id` único
- Si una venta se sincroniza, se marca como `synced`
- No se volverá a enviar

## 📱 Ejemplo Completo de Implementación

Ver el archivo `nuevaVenta_screen.dart` para un ejemplo completo de uso en una pantalla real.

## 🎨 Personalización de UI

### Colores del Widget de Estado

Editar `sync_status_widget.dart`:
```dart
Color _getBackgroundColor(int pendientes, int fallidas, bool isConnected) {
  if (fallidas > 0) return Colors.red.shade700;      // Error
  if (pendientes > 0 && !isConnected) return Colors.orange.shade700;  // Offline
  if (pendientes > 0 && isConnected) return Colors.blue.shade700;     // Sincronizando
  return Colors.green.shade700;  // Todo OK
}
```

## 🔐 Consideraciones de Seguridad

- ✅ Los tokens de autenticación se incluyen en cada sincronización
- ✅ Los datos locales están en el sandbox de la app
- ⚠️ Para datos muy sensibles, considerar encriptación de SQLite
- ✅ Las ventas offline usan el mismo modelo que online

## 📈 Métricas y Monitoreo

```dart
// Obtener estadísticas
final stats = await ventasProvider.obtenerEstadisticas();

print('Total: ${stats['total']}');
print('Pendientes: ${stats['pending']}');
print('Fallidas: ${stats['failed']}');
print('Sincronizadas: ${stats['synced']}');
```

## 🚀 Próximas Mejoras

- [ ] Encriptación de base de datos local
- [ ] Resolución de conflictos si se edita la misma venta online/offline
- [ ] Soporte para editar ventas offline
- [ ] Sincronización diferencial (solo cambios)
- [ ] Compresión de datos antes de sincronizar

## 📞 Soporte

Para preguntas o problemas, consultar:
- Logs de consola con prefijos: `🔄`, `💾`, `📡`, `✅`, `❌`
- Documentación de servicios individuales en sus archivos
- Error Handler Guide: `lib/Services/ERROR_HANDLING_GUIDE.md`

---

**¡El sistema está listo para funcionar 100% offline! 🎉**

