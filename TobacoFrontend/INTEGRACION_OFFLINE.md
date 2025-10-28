# 🚀 Guía Rápida de Integración - Modo Offline

## ✅ Paso 1: Instalar Dependencias

```bash
flutter pub get
```

## ✅ Paso 2: Inicializar en `main.dart`

Asegúrate de que `VentasProvider` se inicialice al arrancar la app:

```dart
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        // Inicializar el VentasProvider con el servicio offline
        ChangeNotifierProvider(
          create: (_) => VentasProvider()..initialize(),
        ),
        // ... tus otros providers
      ],
      child: MyApp(),
    ),
  );
}
```

## ✅ Paso 3: Actualizar Backend (Agregar Endpoint Health)

El archivo `HealthController.cs` ya está creado en:
```
TobacoApi\TobacoBackend\TobacoBackend\Controllers\HealthController.cs
```

**Necesitas reiniciar tu backend para que el endpoint esté disponible.**

## ✅ Paso 4: Actualizar `nuevaVenta_screen.dart`

### Opción A: Cambio Mínimo (Solo actualizar el método de guardar)

Busca el método donde guardas la venta y cámbialo de:

```dart
// ANTES
await ventasProvider.crearVenta(venta);
```

A:

```dart
// DESPUÉS
final result = await ventasProvider.crearVenta(venta);

if (result.success) {
  if (result.isOffline) {
    // Guardada offline
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Venta guardada localmente. Se sincronizará cuando haya conexión.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  } else {
    // Guardada online
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Venta creada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }
  Navigator.pop(context);
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('❌ Error: ${result.message}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

### Opción B: Agregar Indicador Visual (Recomendado)

En el `build` method de `nuevaVenta_screen.dart`, agrega el widget de estado:

```dart
import 'package:tobaco/Widgets/sync_status_widget.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Nueva Venta'),
    ),
    body: Column(
      children: [
        // ⭐ Agregar este widget
        SyncStatusWidget(showDetails: true),
        
        // Tu contenido existente
        Expanded(
          child: _tuContenidoActual(),
        ),
      ],
    ),
  );
}
```

## ✅ Paso 5: Agregar Badge en Pantalla Principal de Ventas

En `ventas_screen.dart`:

```dart
import 'package:tobaco/Widgets/sync_status_widget.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Ventas'),
      actions: [
        // ⭐ Badge compacto que muestra ventas pendientes
        SyncStatusBadge(),
        SizedBox(width: 16),
      ],
    ),
    body: _tuListaDeVentas(),
  );
}
```

## ✅ Paso 6: Probar el Sistema

### Prueba 1: Crear Venta Online
1. Asegúrate de tener conexión a internet
2. Backend debe estar corriendo
3. Crea una venta normal
4. Debería mostrar: "✅ Venta creada exitosamente" (verde)

### Prueba 2: Crear Venta Offline (Sin Internet)
1. Desactiva WiFi/Datos en tu dispositivo
2. Crea una venta
3. Debería mostrar: "✅ Venta guardada localmente..." (naranja)
4. Reactiva la conexión
5. Espera 5-30 segundos
6. La venta se sincronizará automáticamente

### Prueba 3: Crear Venta Offline (Backend Apagado)
1. Detén el backend (`Ctrl+C` en la terminal del backend)
2. Mantén internet activo
3. Crea una venta
4. Debería guardarse offline
5. Reinicia el backend
6. La venta se sincronizará automáticamente

### Prueba 4: Sincronización Manual
1. Crea varias ventas offline
2. Toca el botón de sincronización (⟳) en el widget de estado
3. O toca el badge en la AppBar
4. Verás un diálogo con opciones de sincronización

## 📊 Monitoreo de Ventas Pendientes

Puedes verificar el estado en cualquier momento:

```dart
final ventasProvider = Provider.of<VentasProvider>(context, listen: false);

// Obtener estadísticas
final stats = await ventasProvider.obtenerEstadisticas();
print('Pendientes: ${stats['pending']}');
print('Fallidas: ${stats['failed']}');
print('Sincronizadas: ${stats['synced']}');

// Verificar conexión
bool conectado = ventasProvider.isConnected;
print('Conexión: ${conectado ? 'Sí' : 'No'}');
```

## 🔍 Debugging

### Ver logs en consola

Todos los servicios imprimen logs con emojis:

- 🚀 VentasOfflineService
- 🔄 SyncService
- 🌐 ConnectivityService
- 📦 DatabaseHelper
- 💾 Guardado offline
- 📡 API calls
- ✅ Éxito
- ❌ Error

Ejemplo de output en consola:
```
🚀 VentasOfflineService: Inicializando...
🌐 ConnectivityService: Inicializando...
📦 DatabaseHelper: Inicializando base de datos...
✅ VentasOfflineService: Inicializado correctamente
💰 VentasOfflineService: Creando venta...
📴 VentasOfflineService: Sin conexión, guardando offline...
💾 DatabaseHelper: Guardando venta offline...
✅ DatabaseHelper: Venta offline guardada con ID: local_1698765432000
```

### Ver base de datos SQLite

La base de datos se guarda en:
```
Android: /data/data/com.tu.app/databases/tobaco_offline.db
iOS: Library/Application Support/tobaco_offline.db
```

Puedes usar herramientas como:
- DB Browser for SQLite (desktop)
- Android Studio Database Inspector
- VS Code extension: SQLite

### Verificar conectividad manualmente

```dart
final connectivityService = ConnectivityService();
await connectivityService.initialize();

bool tieneInternet = connectivityService.hasInternetConnection;
bool backendDisponible = connectivityService.isBackendAvailable;
bool conexionCompleta = connectivityService.isFullyConnected;

print('Internet: $tieneInternet');
print('Backend: $backendDisponible');
print('Conexión completa: $conexionCompleta');
```

## 🛠️ Configuración Opcional

### Cambiar intervalo de sincronización

Por defecto es cada 5 minutos. Para cambiarlo, edita `sync_service.dart`:

```dart
// Línea ~65
_syncTimer = Timer.periodic(Duration(minutes: 10), (timer) async {
  // ...
});
```

### Cambiar días de retención de ventas

Por defecto las ventas sincronizadas se mantienen 30 días. Para cambiar:

```dart
// Línea ~28 de database_helper.dart
Future<int> cleanOldSyncedVentas({int daysOld = 60}) async {
  // ...
}
```

### Limpiar ventas antiguas manualmente

Puedes agregar un botón en configuración:

```dart
ElevatedButton(
  onPressed: () async {
    final provider = Provider.of<VentasProvider>(context, listen: false);
    final eliminadas = await provider.limpiarVentasAntiguas(dias: 30);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$eliminadas ventas antiguas eliminadas')),
    );
  },
  child: Text('Limpiar Ventas Sincronizadas Antiguas'),
)
```

## ⚠️ Problemas Comunes

### "Backend no disponible" con internet activo

**Causa:** El endpoint `/api/health` no existe o el backend no está corriendo.

**Solución:**
1. Verifica que el archivo `HealthController.cs` esté en el proyecto
2. Reinicia el backend
3. Prueba acceder a `http://tu-servidor/api/health` en el navegador

### Ventas no se sincronizan automáticamente

**Causa:** Puede que el timer no esté corriendo o no haya conexión.

**Solución:**
1. Verifica logs en consola
2. Usa sincronización manual con el botón ⟳
3. Verifica el estado de conexión

### Error "Database is locked"

**Causa:** Múltiples accesos simultáneos a SQLite.

**Solución:**
- El sistema ya maneja esto con transacciones
- Si persiste, reinicia la app

### Ventas duplicadas

**No debería ocurrir:**
- Cada venta tiene un `local_id` único
- Las ventas sincronizadas se marcan como `synced`
- No se envían dos veces

Si ocurre, reporta el bug con logs.

## 📱 Testing en Dispositivo Real

### Android
```bash
flutter run -d <device-id>
```

### iOS
```bash
flutter run -d <device-id>
```

### Para probar offline:
1. Modo avión ON
2. O desconecta WiFi
3. O detén el backend

## 🎉 ¡Listo!

Tu aplicación ahora funciona 100% offline. Las ventas se crearán localmente y se sincronizarán automáticamente cuando haya conexión.

## 📚 Documentación Adicional

- **Documentación completa:** `lib/Services/Ventas_Service/OFFLINE_MODE_README.md`
- **Arquitectura:** Ver diagrama en README principal
- **Error handling:** `lib/Services/ERROR_HANDLING_GUIDE.md`

## 🆘 Soporte

Si encuentras problemas:

1. Revisa los logs en consola (tienen emojis para fácil identificación)
2. Verifica que el backend tenga el endpoint `/api/health`
3. Usa sincronización manual para diagnóstico
4. Consulta la documentación completa

---

**¡El sistema offline está listo! 🚀📴**

