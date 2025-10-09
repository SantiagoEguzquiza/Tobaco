# Guía de Manejo de Errores de Conexión

Esta guía explica cómo se implementó el manejo de errores cuando el backend no responde o está apagado.

## 📋 Tabla de Contenidos

- [Resumen](#resumen)
- [Componentes Implementados](#componentes-implementados)
- [Cómo Usar](#cómo-usar)
- [Ejemplos](#ejemplos)

## Resumen

Se implementó un sistema centralizado para detectar y manejar errores de conexión con el backend. Cuando el servidor no responde, la aplicación muestra automáticamente un diálogo informativo al usuario.

## Componentes Implementados

### 1. **Diálogo de Servidor No Disponible** (`AppDialogs.showServerErrorDialog`)

Ubicación: `lib/Theme/dialogs.dart`

Un nuevo diálogo que muestra un mensaje amigable cuando el servidor no está disponible.

```dart
await AppDialogs.showServerErrorDialog(context: context);
```

### 2. **Detección de Errores de Conexión** (`Apihandler.isConnectionError`)

Ubicación: `lib/Helpers/api_handler.dart`

Método que detecta automáticamente los siguientes errores de conexión:
- `SocketException` - El servidor no está accesible
- `TimeoutException` - La petición tardó demasiado
- `HandshakeException` - Error de certificado SSL/TLS
- Errores de red comunes (Connection refused, timeout, etc.)

```dart
if (Apihandler.isConnectionError(error)) {
  // Es un error de conexión
}
```

### 3. **Manejador de Errores Centralizado** (`Apihandler.handleConnectionError`)

Ubicación: `lib/Helpers/api_handler.dart`

Método que maneja automáticamente los errores y muestra el diálogo apropiado:

```dart
await Apihandler.handleConnectionError(context, error);
```

Este método:
- Detecta si es un error de conexión → Muestra `showServerErrorDialog`
- Si es otro tipo de error → Muestra `showErrorDialog` con el mensaje del error

### 4. **Timeouts en Todos los Servicios**

Todos los servicios ahora tienen un timeout de **10 segundos** en sus peticiones HTTP:

**Servicios actualizados:**
- ✅ `ClienteService`
- ✅ `ProductoService`
- ✅ `VentasService`
- ✅ `CategoriaService`
- ✅ `UserService`
- ✅ `PrecioEspecialService`
- ✅ `AuthService`

## Cómo Usar

### Patrón Recomendado para Todas las Pantallas

Cuando hagas llamadas a servicios en tus pantallas, usa este patrón:

```dart
import '../../Helpers/api_handler.dart';  // Importar el helper
import '../../Theme/dialogs.dart';        // Importar los diálogos

// En tu método que llama al servicio:
try {
  // Tu llamada al servicio
  final data = await miServicio.obtenerDatos();
  
  setState(() {
    // Actualizar tu estado con los datos
  });
} catch (e) {
  // Verificar si es un error de conexión con el servidor
  if (mounted && Apihandler.isConnectionError(e)) {
    await Apihandler.handleConnectionError(context, e);
  } else if (mounted) {
    // Manejar otros tipos de errores
    await AppDialogs.showErrorDialog(
      context: context,
      message: 'Error: ${e.toString().replaceFirst('Exception: ', '')}',
    );
  }
}
```

### Puntos Importantes

1. **Verificar `mounted`**: Siempre verifica que el widget esté montado antes de mostrar diálogos
2. **Importar helpers**: Asegúrate de importar `api_handler.dart` en tus pantallas
3. **Await en diálogos**: Usa `await` al mostrar diálogos para mejores transiciones

## Ejemplos

### Ejemplo 1: Cargar Clientes

```dart
Future<void> _cargarClientes() async {
  setState(() {
    isLoading = true;
  });

  try {
    final clientes = await ClienteService().obtenerClientes();
    
    setState(() {
      this.clientes = clientes;
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    
    if (mounted && Apihandler.isConnectionError(e)) {
      await Apihandler.handleConnectionError(context, e);
    } else if (mounted) {
      await AppDialogs.showErrorDialog(
        context: context,
        message: 'Error al cargar clientes: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }
}
```

### Ejemplo 2: Crear Producto

```dart
Future<void> _crearProducto(Producto producto) async {
  try {
    await ProductoService().crearProducto(producto);
    
    if (mounted) {
      await AppDialogs.showSuccessDialog(
        context: context,
        message: 'Producto creado exitosamente',
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted && Apihandler.isConnectionError(e)) {
      await Apihandler.handleConnectionError(context, e);
    } else if (mounted) {
      await AppDialogs.showErrorDialog(
        context: context,
        message: 'Error al crear producto: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }
}
```

### Ejemplo 3: Login con Manejo Especial

```dart
Future<void> _login() async {
  try {
    final response = await AuthService.login(loginRequest);
    
    if (response != null && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  } catch (e) {
    if (mounted && Apihandler.isConnectionError(e)) {
      // Error de conexión - servidor no disponible
      await Apihandler.handleConnectionError(context, e);
    } else if (e.toString().contains('401')) {
      // Credenciales inválidas
      if (mounted) {
        await AppDialogs.showErrorDialog(
          context: context,
          title: 'Error de Autenticación',
          message: 'Usuario o contraseña incorrectos',
        );
      }
    } else if (mounted) {
      // Otros errores
      await AppDialogs.showErrorDialog(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
```

## 🔧 Personalización

### Cambiar el Timeout

Si necesitas cambiar el tiempo de espera, modifica la constante en cada servicio:

```dart
static const Duration _timeoutDuration = Duration(seconds: 10); // Cambiar según necesidad
```

### Personalizar el Mensaje del Diálogo

Puedes personalizar el mensaje del diálogo de servidor:

```dart
await AppDialogs.showServerErrorDialog(
  context: context,
  title: 'Sin Conexión',
  message: 'No se pudo conectar con el servidor. Verifica tu conexión a internet.',
  buttonText: 'OK',
);
```

## 📝 Notas

- Los servicios ya tienen implementados los timeouts, no necesitas agregarlos nuevamente
- El diálogo se muestra automáticamente al usuario cuando hay un error de conexión
- Si el servidor vuelve a estar disponible, las peticiones funcionarán normalmente
- Los errores se registran en la consola con `debugPrint` para facilitar el debugging

## 🚀 Próximos Pasos

Para aplicar este patrón a todas las pantallas:

1. Revisa cada pantalla que haga llamadas al backend
2. Actualiza los bloques `catch` con el patrón recomendado
3. Importa los helpers necesarios
4. Verifica que `mounted` antes de mostrar diálogos
5. Prueba apagando el backend para verificar que el diálogo se muestre correctamente

---

**Fecha de implementación**: 2025
**Versión**: 1.0

