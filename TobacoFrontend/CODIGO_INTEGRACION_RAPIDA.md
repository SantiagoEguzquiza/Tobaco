# 📋 Código Listo para Copiar y Pegar

## 🚀 Integración Rápida - Código Copy/Paste

### 1️⃣ Registrar Provider en main.dart

Busca el `MultiProvider` en tu `main.dart` y agrega este provider:

```dart
// Importar al inicio del archivo
import 'package:tobaco/Services/Entregas_Service/entregas_provider.dart';
import 'package:tobaco/Services/Entregas_Service/entregas_service.dart';
import 'package:tobaco/Services/Entregas_Service/ubicacion_service.dart';

// Dentro del MultiProvider, agregar:
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

---

### 2️⃣ Agregar Botón en el Menú

En `menu_screen.dart` (o donde tengas tu menú):

```dart
// Importar al inicio
import 'package:tobaco/Screens/Entregas/mapa_entregas_screen.dart';

// Agregar este ListTile en tu lista de opciones:
ListTile(
  leading: const Icon(Icons.map, color: Colors.blue),
  title: const Text('Mapa de Entregas'),
  subtitle: const Text('Ver entregas del día en el mapa'),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

---

### 3️⃣ Agregar en Drawer/NavigationRail (Alternativa)

Si usas un `Drawer`:

```dart
ListTile(
  leading: const Icon(Icons.map),
  title: const Text('Mapa de Entregas'),
  onTap: () {
    Navigator.pop(context); // Cerrar drawer
    Navigator.pushNamed(context, '/mapa-entregas');
  },
),
```

Y en tus rutas:

```dart
routes: {
  '/mapa-entregas': (context) => const MapaEntregasScreen(),
  // ... otras rutas
},
```

---

### 4️⃣ Agregar Card de Acceso Rápido

Para un acceso más visual:

```dart
Card(
  elevation: 3,
  margin: const EdgeInsets.all(16),
  child: InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MapaEntregasScreen(),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.map,
              size: 32,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Mapa de Entregas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ver y gestionar entregas del día',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 20),
        ],
      ),
    ),
  ),
),
```

---

### 5️⃣ Mostrar Contador de Entregas Pendientes

Widget para mostrar entregas pendientes en tiempo real:

```dart
class ContadorEntregasPendientes extends StatelessWidget {
  const ContadorEntregasPendientes({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EntregasProvider>(
      builder: (context, provider, child) {
        final pendientes = provider.entregasPendientes.length;
        
        if (pendientes == 0) return const SizedBox.shrink();
        
        return Badge(
          label: Text('$pendientes'),
          backgroundColor: Colors.red,
          child: IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapaEntregasScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Usar en tu AppBar:
AppBar(
  title: const Text('Inicio'),
  actions: [
    ContadorEntregasPendientes(),
  ],
)
```

---

### 6️⃣ Utilidad para Geocodificar Clientes

Crear archivo `lib/Utils/geocodificador_helper.dart`:

```dart
import 'package:tobaco/Services/Entregas_Service/ubicacion_service.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_service.dart';

class GeocodificadorHelper {
  final UbicacionService _ubicacionService = UbicacionService();
  final ClientesService _clientesService;

  GeocodificadorHelper(this._clientesService);

  /// Geocodifica un solo cliente
  Future<Map<String, double>?> geocodificarCliente(Cliente cliente) async {
    if (cliente.direccion == null || cliente.direccion!.isEmpty) {
      print('⚠️ ${cliente.nombre}: Sin dirección');
      return null;
    }

    try {
      // Agregar ", Paraguay" para mejor precisión
      final direccionCompleta = '${cliente.direccion}, Paraguay';
      
      final coords = await _ubicacionService.geocodificarDireccion(
        direccionCompleta,
      );

      if (coords != null) {
        print('✅ ${cliente.nombre}: ${coords['latitud']}, ${coords['longitud']}');
        return coords;
      } else {
        print('❌ ${cliente.nombre}: No se pudo geocodificar');
        return null;
      }
    } catch (e) {
      print('❌ ${cliente.nombre}: Error - $e');
      return null;
    }
  }

  /// Geocodifica múltiples clientes
  Future<Map<String, dynamic>> geocodificarClientes(
    List<Cliente> clientes, {
    Function(int total, int procesados)? onProgress,
  }) async {
    int exitosos = 0;
    int fallidos = 0;
    List<Map<String, dynamic>> resultados = [];

    for (int i = 0; i < clientes.length; i++) {
      final cliente = clientes[i];
      
      // Callback de progreso
      onProgress?.call(clientes.length, i + 1);

      final coords = await geocodificarCliente(cliente);

      if (coords != null) {
        exitosos++;
        resultados.add({
          'clienteId': cliente.id,
          'nombre': cliente.nombre,
          'latitud': coords['latitud'],
          'longitud': coords['longitud'],
          'exito': true,
        });

        // Aquí puedes actualizar el cliente en la BD
        // await _clientesService.actualizarCoordenadas(
        //   cliente.id!,
        //   coords['latitud']!,
        //   coords['longitud']!,
        // );
      } else {
        fallidos++;
        resultados.add({
          'clienteId': cliente.id,
          'nombre': cliente.nombre,
          'exito': false,
        });
      }

      // Pausa para no exceder límites de API (5 requests/segundo)
      await Future.delayed(const Duration(milliseconds: 250));
    }

    return {
      'total': clientes.length,
      'exitosos': exitosos,
      'fallidos': fallidos,
      'resultados': resultados,
    };
  }

  /// Exporta resultados a CSV
  String exportarACsv(Map<String, dynamic> resultado) {
    StringBuffer csv = StringBuffer();
    csv.writeln('Cliente ID,Nombre,Latitud,Longitud,Estado');

    for (var r in resultado['resultados']) {
      if (r['exito']) {
        csv.writeln(
          '${r['clienteId']},${r['nombre']},${r['latitud']},${r['longitud']},Exitoso',
        );
      } else {
        csv.writeln('${r['clienteId']},${r['nombre']},,,Fallido');
      }
    }

    return csv.toString();
  }
}
```

---

### 7️⃣ Pantalla Admin para Geocodificación

Crear `lib/Screens/Admin/geocodificar_clientes_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Utils/geocodificador_helper.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_service.dart';

class GeocodificarClientesScreen extends StatefulWidget {
  const GeocodificarClientesScreen({super.key});

  @override
  State<GeocodificarClientesScreen> createState() =>
      _GeocodificarClientesScreenState();
}

class _GeocodificarClientesScreenState
    extends State<GeocodificarClientesScreen> {
  bool _procesando = false;
  int _total = 0;
  int _procesados = 0;
  Map<String, dynamic>? _resultado;

  Future<void> _iniciarGeocoding() async {
    setState(() {
      _procesando = true;
      _total = 0;
      _procesados = 0;
      _resultado = null;
    });

    try {
      final clientesService =
          Provider.of<ClientesService>(context, listen: false);
      final clientes = await clientesService.obtenerTodosLosClientes();

      setState(() {
        _total = clientes.length;
      });

      final geocodificador = GeocodificadorHelper(clientesService);

      final resultado = await geocodificador.geocodificarClientes(
        clientes,
        onProgress: (total, procesados) {
          setState(() {
            _procesados = procesados;
          });
        },
      );

      setState(() {
        _resultado = resultado;
        _procesando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Geocodificación completada: ${resultado['exitosos']} exitosos, ${resultado['fallidos']} fallidos',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _procesando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geocodificar Clientes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Geocodificación de Clientes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Convierte las direcciones de tus clientes en coordenadas GPS para usar en el mapa de entregas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_procesando) ...[
              LinearProgressIndicator(
                value: _total > 0 ? _procesados / _total : 0,
              ),
              const SizedBox(height: 16),
              Text(
                'Procesando: $_procesados / $_total',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            if (_resultado != null) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Resultados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _ResultRow(
                        'Total procesados:',
                        '${_resultado!['total']}',
                      ),
                      _ResultRow(
                        'Exitosos:',
                        '${_resultado!['exitosos']}',
                        color: Colors.green,
                      ),
                      _ResultRow(
                        'Fallidos:',
                        '${_resultado!['fallidos']}',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _procesando ? null : _iniciarGeocoding,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar Geocodificación'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _ResultRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 8️⃣ Verificar Permisos antes de Abrir Mapa

Helper para verificar permisos:

```dart
import 'package:geolocator/geolocator.dart';

class PermisosHelper {
  static Future<bool> verificarYSolicitarPermisos(BuildContext context) async {
    // Verificar si el servicio está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _mostrarDialogoServicioDeshabilitado(context);
      return false;
    }

    // Verificar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _mostrarSnackBar(
          context,
          'Permisos de ubicación denegados',
          Colors.red,
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _mostrarDialogoPermisosPermanentes(context);
      return false;
    }

    return true;
  }

  static Future<void> _mostrarDialogoServicioDeshabilitado(
    BuildContext context,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS Deshabilitado'),
        content: const Text(
          'Por favor habilita el GPS en la configuración de tu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> _mostrarDialogoPermisosPermanentes(
    BuildContext context,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos Requeridos'),
        content: const Text(
          'Los permisos de ubicación están permanentemente denegados. '
          'Por favor habilítalos en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  static void _mostrarSnackBar(
    BuildContext context,
    String mensaje,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }
}

// Usar antes de abrir el mapa:
onTap: () async {
  final tienePermisos = await PermisosHelper.verificarYSolicitarPermisos(context);
  
  if (tienePermisos) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapaEntregasScreen(),
      ),
    );
  }
},
```

---

### 9️⃣ Widget de Estado de Sincronización

Mostrar estado de sync en tiempo real:

```dart
class EstadoSincronizacion extends StatelessWidget {
  const EstadoSincronizacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EntregasProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<int>(
          future: provider.sincronizar(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Sincronizando...'),
                ],
              );
            }

            if (snapshot.hasData && snapshot.data! > 0) {
              return Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text('${snapshot.data!} entregas sincronizadas'),
                ],
              );
            }

            return const Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.grey, size: 16),
                SizedBox(width: 8),
                Text('Todo sincronizado'),
              ],
            );
          },
        );
      },
    );
  }
}
```

---

## 🎉 ¡Listo!

Con estos códigos puedes integrar rápidamente el sistema de mapas en tu app.

**Archivos a crear:**
- `lib/Utils/geocodificador_helper.dart`
- `lib/Screens/Admin/geocodificar_clientes_screen.dart`
- `lib/Utils/permisos_helper.dart` (opcional)

**Archivos a modificar:**
- `lib/main.dart` - Agregar provider
- `lib/Screens/menu_screen.dart` - Agregar botón

¡Disfruta tu nuevo sistema de mapas! 🗺️

