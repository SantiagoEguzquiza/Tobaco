# 🚀 Guía Rápida de Integración - Sistema de Mapas

## ⚡ Setup en 5 Minutos

### 1. Instalar dependencias
```bash
cd TobacoFrontend
flutter pub get
```

### 2. Configurar Google Maps API Key

#### Obtener API Key (2 minutos)
1. Ve a https://console.cloud.google.com/
2. Habilita "Maps SDK for Android" y "Maps SDK for iOS"
3. Crea una API Key en "Credentials"

#### Configurar en Android
Edita `android/app/src/main/AndroidManifest.xml` línea 47:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI" />  <!-- ⬅️ CAMBIAR ESTO -->
```

#### Configurar en iOS (Opcional para producción)
Edita `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("TU_API_KEY_AQUI")  // ⬅️ CAMBIAR ESTO
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 3. Registrar el Provider en tu app

En `main.dart`:
```dart
import 'package:tobaco/Services/Entregas_Service/entregas_provider.dart';
import 'package:tobaco/Services/Entregas_Service/entregas_service.dart';
import 'package:tobaco/Services/Entregas_Service/ubicacion_service.dart';

// En tu MultiProvider, agrega:
ChangeNotifierProvider(
  create: (context) => EntregasProvider(
    entregasService: EntregasService(
      authService: Provider.of<AuthService>(context, listen: false),
      connectivityService: Provider.of<ConnectivityService>(context, listen: false),
      databaseHelper: DatabaseHelper(),
    ),
    ubicacionService: UbicacionService(),
  ),
),
```

### 4. Agregar botón en el menú

En `menu_screen.dart` o donde tengas el menú:
```dart
ListTile(
  leading: const Icon(Icons.map),
  title: const Text('Mapa de Entregas'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapaEntregasScreen(),
      ),
    );
  },
),
```

### 5. Importar la pantalla
```dart
import 'package:tobaco/Screens/Entregas/mapa_entregas_screen.dart';
```

---

## 🧪 Probar sin Backend (Datos de Prueba)

Si todavía no tienes el backend listo, puedes probar con datos mock:

### Crear datos de prueba

Crea `lib/Services/Entregas_Service/entregas_mock_service.dart`:
```dart
import 'package:tobaco/Models/Entrega.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';

class EntregasMockService {
  static List<Entrega> obtenerEntregasMock() {
    return [
      Entrega(
        id: 1,
        ventaId: 1,
        clienteId: 1,
        cliente: Cliente(
          id: 1,
          nombre: 'Supermercado Los Álamos',
          direccion: 'Av. España 1234, Asunción',
        ),
        latitud: -25.2812,
        longitud: -57.6358,
        estado: EstadoEntrega.noEntregada,
        fechaAsignacion: DateTime.now(),
        repartidorId: 1,
        orden: 1,
      ),
      Entrega(
        id: 2,
        ventaId: 2,
        clienteId: 2,
        cliente: Cliente(
          id: 2,
          nombre: 'Despensa Don Pedro',
          direccion: 'Palma 456, Asunción',
        ),
        latitud: -25.2900,
        longitud: -57.6400,
        estado: EstadoEntrega.noEntregada,
        fechaAsignacion: DateTime.now(),
        repartidorId: 1,
        orden: 2,
      ),
      Entrega(
        id: 3,
        ventaId: 3,
        clienteId: 3,
        cliente: Cliente(
          id: 3,
          nombre: 'Kiosco La Esquina',
          direccion: 'Mariscal López 789, Asunción',
        ),
        latitud: -25.2750,
        longitud: -57.6300,
        estado: EstadoEntrega.entregada,
        fechaAsignacion: DateTime.now().subtract(const Duration(hours: 2)),
        fechaEntrega: DateTime.now().subtract(const Duration(hours: 1)),
        repartidorId: 1,
        orden: 3,
      ),
    ];
  }
}
```

Modifica temporalmente `entregas_service.dart`:
```dart
Future<List<Entrega>> _obtenerEntregasDelServidor() async {
  // Temporalmente, devolver datos mock
  return EntregasMockService.obtenerEntregasMock();
  
  // Código real para más tarde:
  // final token = authService.token;
  // ...
}
```

---

## 🗺️ Geocodificar Direcciones Existentes

Si tus clientes ya existen pero no tienen coordenadas, usa este helper:

### Script de Geocodificación

```dart
import 'package:tobaco/Services/Entregas_Service/ubicacion_service.dart';
import 'package:tobaco/Models/Cliente.dart';

class GeocodificadorHelper {
  final UbicacionService ubicacionService = UbicacionService();

  Future<void> geocodificarClientes(List<Cliente> clientes) async {
    for (var cliente in clientes) {
      if (cliente.direccion != null && cliente.direccion!.isNotEmpty) {
        print('Geocodificando: ${cliente.nombre}...');
        
        final coords = await ubicacionService.geocodificarDireccion(
          '${cliente.direccion}, Paraguay',  // Agregar país para mejor precisión
        );

        if (coords != null) {
          print('✅ ${cliente.nombre}: ${coords['latitud']}, ${coords['longitud']}');
          
          // Aquí deberías actualizar el cliente en tu base de datos
          // await clientesService.actualizarCoordenadas(
          //   cliente.id,
          //   coords['latitud']!,
          //   coords['longitud']!,
          // );
        } else {
          print('❌ ${cliente.nombre}: No se pudo geocodificar');
        }

        // Pausa para no exceder límites de API
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }
}
```

Usar en una pantalla administrativa:
```dart
ElevatedButton(
  onPressed: () async {
    final geocodificador = GeocodificadorHelper();
    final clientes = await clientesService.obtenerTodosLosClientes();
    await geocodificador.geocodificarClientes(clientes);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geocodificación completada')),
    );
  },
  child: const Text('Geocodificar Clientes'),
),
```

---

## 🎯 Casos de Uso Comunes

### 1. Abrir mapa en una entrega específica

```dart
void irAEntrega(BuildContext context, int entregaId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const MapaEntregasScreen(),
    ),
  ).then((_) {
    // Después de que carga el mapa
    final provider = Provider.of<EntregasProvider>(context, listen: false);
    final entrega = provider.entregas.firstWhere((e) => e.id == entregaId);
    
    // Centrar en esa entrega
    // (esto se puede mejorar pasando el ID como parámetro)
  });
}
```

### 2. Notificar al llegar cerca del cliente

```dart
class EntregasProvider with ChangeNotifier {
  void _verificarProximidad() {
    if (_posicionActual == null) return;

    for (var entrega in entregasPendientes) {
      if (entrega.tieneCoordenadasValidas) {
        double distancia = ubicacionService.calcularDistanciaDesdeActual(
          entrega.latitud!,
          entrega.longitud!,
        ) ?? double.infinity;

        // Si está a menos de 100 metros
        if (distancia < 0.1) {
          _notificarProximidad(entrega);
        }
      }
    }
  }

  void _notificarProximidad(Entrega entrega) {
    // Aquí puedes mostrar una notificación local
    print('📍 Estás cerca de ${entrega.nombreCliente}');
  }
}
```

### 3. Ver historial de entregas completadas

```dart
class HistorialEntregasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Entregas')),
      body: Consumer<EntregasProvider>(
        builder: (context, provider, child) {
          final completadas = provider.entregasCompletadas;
          
          return ListView.builder(
            itemCount: completadas.length,
            itemBuilder: (context, index) {
              final entrega = completadas[index];
              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(entrega.nombreCliente),
                subtitle: Text(
                  'Entregado: ${_formatFecha(entrega.fechaEntrega!)}',
                ),
                trailing: entrega.distanciaDesdeUbicacionActual != null
                    ? Text('${entrega.distanciaDesdeUbicacionActual!.toStringAsFixed(1)} km')
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}
```

---

## 🔧 Personalización

### Cambiar colores de marcadores

En `mapa_entregas_screen.dart`:
```dart
Marker _crearMarcadorEntrega(Entrega entrega) {
  double hue;
  
  switch (entrega.estado) {
    case EstadoEntrega.entregada:
      hue = BitmapDescriptor.hueGreen;    // Verde
      break;
    case EstadoEntrega.parcial:
      hue = BitmapDescriptor.hueOrange;   // Naranja
      break;
    default:
      hue = BitmapDescriptor.hueRed;      // Rojo
  }
  
  // Cambiar a hueViolet, hueCyan, etc.
  
  return Marker(...);
}
```

### Cambiar estilo del mapa

```dart
GoogleMap(
  mapType: MapType.normal,  // normal, satellite, hybrid, terrain
  // ...
)
```

O con JSON personalizado:
```dart
String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#242f3e"}]
  }
]
''';

void _onMapCreated(GoogleMapController controller) {
  controller.setMapStyle(_mapStyle);
}
```

### Ajustar velocidad de tracking

En `ubicacion_service.dart`:
```dart
Stream<Position> iniciarSeguimientoUbicacion() {
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,  // Cambiar a 5 para más frecuente, 20 para menos
  );
  // ...
}
```

---

## 📱 Testing

### En Emulador Android Studio

1. Abrir Extended Controls (⋮ en el emulador)
2. Ir a "Location"
3. Ingresar coordenadas manualmente o usar un GPX route

Coordenadas de prueba (Asunción):
- Centro: -25.2637, -57.5759
- Shopping: -25.2812, -57.6358
- Aeropuerto: -25.2406, -57.5194

### En Dispositivo Real

1. Habilitar GPS en configuración
2. Permitir permisos de ubicación cuando la app lo solicite
3. Salir al exterior para mejor señal GPS

---

## ⚠️ Checklist Pre-Producción

Antes de liberar a producción:

- [ ] API Key de Google Maps configurada y restringida
- [ ] Permisos de ubicación funcionando en Android e iOS
- [ ] Backend implementado con endpoints de entregas
- [ ] Sincronización offline probada
- [ ] Geocodificación de todos los clientes existentes
- [ ] Pruebas con conexión intermitente
- [ ] Optimización de batería verificada
- [ ] Testing en dispositivos reales
- [ ] Documentación para repartidores
- [ ] Plan de monitoreo de costos de Google Maps

---

## 🆘 FAQ

**P: ¿Funciona sin conexión a internet?**  
R: Sí, las entregas se guardan en SQLite y se sincronizan cuando hay conexión. Sin embargo, el mapa de Google requiere conexión (se puede implementar cache de tiles para offline completo).

**P: ¿Consume mucha batería?**  
R: El tracking continuo consume batería. Se puede optimizar deteniendo el tracking cuando no hay entregas activas.

**P: ¿Cuánto cuesta Google Maps API?**  
R: Tiene $200 USD de crédito gratis mensual, suficiente para ~28,000 cargas de mapa al mes.

**P: ¿Cómo geocodificar clientes sin coordenadas?**  
R: Usa el script de geocodificación incluido en esta guía o implementa un proceso batch en el backend.

**P: ¿Puedo usar otro proveedor de mapas?**  
R: Sí, se puede adaptar para usar OpenStreetMap, Mapbox, etc., pero requeriría cambiar google_maps_flutter.

---

**¡Listo para usar! 🎉**

Si tienes problemas, revisa `SISTEMA_MAPAS_ENTREGAS.md` para documentación completa.

