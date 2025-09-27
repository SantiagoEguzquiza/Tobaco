# Widgets de Carga Personalizados

## Descripción
Sistema de pantallas de carga personalizadas que mantienen la consistencia visual con el diseño de la aplicación.

## Componentes Disponibles

### 1. CustomLoadingWidget
Widget base para mostrar indicadores de carga personalizados.

```dart
CustomLoadingWidget(
  message: 'Cargando...',
  backgroundColor: Colors.white,
  showLogo: true,
  size: 100.0,
)
```

**Parámetros:**
- `message`: Mensaje a mostrar durante la carga
- `backgroundColor`: Color de fondo del widget
- `showLogo`: Si mostrar el logo de la aplicación
- `size`: Tamaño del logo (si se muestra)

### 2. FullScreenLoadingWidget
Pantalla completa de carga.

```dart
FullScreenLoadingWidget(
  message: 'Cargando datos...',
  backgroundColor: Colors.white,
)
```

### 3. DialogLoadingWidget
Diálogo de carga para operaciones específicas.

```dart
DialogLoadingWidget(
  message: 'Procesando...',
)
```

## Pantallas de Carga Especializadas

### 1. LoadingScreen
Pantalla de carga genérica.

```dart
LoadingScreen(
  message: 'Cargando...',
  backgroundColor: Colors.white,
  showLogo: true,
)
```

### 2. AuthLoadingScreen
Pantalla de carga para autenticación con gradiente de fondo.

```dart
AuthLoadingScreen(
  message: 'Verificando credenciales...',
)
```

### 3. DataLoadingScreen
Pantalla de carga para datos con fondo gris claro.

```dart
DataLoadingScreen(
  message: 'Cargando datos...',
)
```

### 4. OperationLoadingScreen
Pantalla de carga para operaciones sin logo.

```dart
OperationLoadingScreen(
  message: 'Procesando...',
)
```

## Utilidades de Carga

### LoadingUtils
Clase utilitaria para manejar pantallas de carga de forma sencilla.

#### Mostrar Diálogo de Carga
```dart
LoadingUtils.showLoadingDialog(
  context,
  message: 'Cargando...',
  barrierDismissible: false,
);
```

#### Ocultar Diálogo de Carga
```dart
LoadingUtils.hideLoadingDialog(context);
```

#### Mostrar Pantalla de Carga Completa
```dart
LoadingUtils.showFullScreenLoading(
  context,
  message: 'Cargando datos...',
  backgroundColor: Colors.white,
  showLogo: true,
);
```

#### Ejecutar Operación con Carga
```dart
final result = await LoadingUtils.executeWithLoading(
  context,
  () async {
    // Tu operación aquí
    return await someAsyncOperation();
  },
  loadingMessage: 'Procesando...',
);
```

#### Ejecutar Operación con Pantalla Completa
```dart
final result = await LoadingUtils.executeWithFullScreenLoading(
  context,
  () async {
    // Tu operación aquí
    return await someAsyncOperation();
  },
  loadingMessage: 'Cargando datos...',
  backgroundColor: Colors.white,
  showLogo: true,
);
```

## Ejemplos de Uso

### 1. En Pantalla de Login
```dart
// Mostrar diálogo de carga durante login
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => const DialogLoadingWidget(
    message: 'Iniciando sesión...',
  ),
);

// Realizar login
final success = await authProvider.login(username, password);

// Cerrar diálogo
Navigator.of(context).pop();
```

### 2. En Pantalla de Datos
```dart
// Mostrar pantalla de carga completa
LoadingUtils.showFullScreenLoading(
  context,
  message: 'Cargando clientes...',
);

// Cargar datos
await _cargarClientes();

// Cerrar pantalla de carga
Navigator.of(context).pop();
```

### 3. En Operaciones Asíncronas
```dart
// Ejecutar operación con carga automática
final result = await LoadingUtils.executeWithLoading(
  context,
  () async {
    return await _clienteService.obtenerClientes();
  },
  loadingMessage: 'Obteniendo clientes...',
);
```

## Características

### Animaciones
- **Rotación**: Spinner que rota continuamente
- **Pulso**: Logo que pulsa suavemente
- **Puntos**: Puntos animados que aparecen secuencialmente

### Colores
- **Primario**: Verde de la aplicación (`AppTheme.primaryColor`)
- **Secundario**: Verde oscuro (`Color(0xFF2E7D32)`)
- **Texto**: Negro (`AppTheme.textColor`)
- **Gris**: Gris claro (`AppTheme.textGreyColor`)

### Tipografía
- **Fuente**: Raleway (consistente con la aplicación)
- **Tamaños**: 18px para mensaje principal, 14px para secundario

### Responsive
- **Adaptable**: Se ajusta al tamaño de pantalla
- **Centrado**: Siempre centrado vertical y horizontalmente
- **Flexible**: Tamaños configurables

## Integración

### 1. Importar
```dart
import '../Widgets/custom_loading_widget.dart';
import '../Screens/Loading/loading_screen.dart';
import '../Utils/loading_utils.dart';
```

### 2. Usar en Widgets
```dart
// En lugar de CircularProgressIndicator
CustomLoadingWidget(
  message: 'Cargando...',
  showLogo: true,
)
```

### 3. Usar en Pantallas
```dart
// En lugar de mostrar loading en AppBar
LoadingUtils.showFullScreenLoading(
  context,
  message: 'Cargando datos...',
);
```

## Mejores Prácticas

1. **Mensajes Descriptivos**: Usa mensajes claros sobre lo que está pasando
2. **Tiempo Apropiado**: No muestres carga por menos de 500ms
3. **Manejo de Errores**: Siempre cierra la carga en caso de error
4. **Consistencia**: Usa el mismo estilo en toda la aplicación
5. **Accesibilidad**: Considera usuarios con discapacidades visuales

## Personalización

### Colores
```dart
CustomLoadingWidget(
  backgroundColor: Colors.blue.shade50,
  // El color primario se toma de AppTheme.primaryColor
)
```

### Tamaños
```dart
CustomLoadingWidget(
  size: 150.0, // Logo más grande
)
```

### Mensajes
```dart
CustomLoadingWidget(
  message: 'Sincronizando datos...',
)
```

## Troubleshooting

### Problema: La carga no se cierra
**Solución**: Asegúrate de llamar `Navigator.of(context).pop()` o usar `LoadingUtils.hideLoadingDialog(context)`

### Problema: Múltiples pantallas de carga
**Solución**: Verifica que no estés mostrando múltiples diálogos simultáneamente

### Problema: Animaciones lentas
**Solución**: Las animaciones están optimizadas para 60fps, verifica el rendimiento del dispositivo
