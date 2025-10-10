# Sistema de Venta en Borrador

## Descripción

El sistema de venta en borrador permite que una venta en curso se mantenga activa incluso si el usuario navega a otras pantallas o cierra la aplicación. Esto evita la pérdida de datos y mejora significativamente la experiencia del usuario.

## Componentes

### 1. **VentaBorrador** (Modelo)
Ubicación: `lib/Models/VentaBorrador.dart`

Modelo de datos que representa una venta en estado borrador. Contiene:
- Cliente seleccionado
- Lista de productos seleccionados
- Precios especiales del cliente
- Fechas de creación y última modificación

### 2. **VentaBorradorService** (Servicio)
Ubicación: `lib/Services/VentaBorrador_Service/venta_borrador_service.dart`

Servicio que maneja la persistencia local usando `SharedPreferences`. Funciones principales:
- `guardarBorrador()`: Guarda el borrador en almacenamiento local
- `cargarBorrador()`: Recupera el borrador guardado
- `eliminarBorrador()`: Elimina el borrador del almacenamiento
- `existeBorrador()`: Verifica si existe un borrador guardado

### 3. **VentaBorradorProvider** (Estado)
Ubicación: `lib/Services/VentaBorrador_Service/venta_borrador_provider.dart`

Provider que gestiona el estado del borrador en la aplicación. Funciones principales:
- `cargarBorradorInicial()`: Carga el borrador al iniciar
- `actualizarCliente()`: Actualiza el cliente en el borrador
- `actualizarProductos()`: Actualiza los productos en el borrador
- `actualizarPreciosEspeciales()`: Actualiza los precios especiales
- `eliminarBorrador()`: Elimina el borrador completamente
- `limpiarYCrearNuevo()`: Descarta el borrador actual y crea uno nuevo

## Flujo de Trabajo

### Inicio de Nueva Venta
1. Al abrir la pantalla de nueva venta, se verifica si existe un borrador guardado
2. Si existe, se muestra un diálogo preguntando al usuario:
   - **Continuar**: Carga los datos del borrador
   - **Nueva Venta**: Descarta el borrador y comienza de cero

### Durante la Venta
- Cada vez que el usuario:
  - Selecciona un cliente
  - Agrega/edita/elimina productos
  - El borrador se guarda automáticamente en almacenamiento local

### Navegación
- El usuario puede navegar libremente a otras pantallas (clientes, productos, deudas)
- Al volver, todos los datos de la venta se mantienen intactos
- Si cierra la app, al volver se mostrará el diálogo de recuperación

### Confirmación de Venta
- Al confirmar la venta y procesarla exitosamente
- El borrador se elimina automáticamente del almacenamiento

### Cancelación de Venta
- El usuario puede cancelar la venta usando el botón de cancelar (ícono en el AppBar)
- Se muestra un diálogo de confirmación
- Si confirma, el borrador se elimina y se cierra la pantalla

## Características Implementadas

✅ Persistencia automática al modificar datos
✅ Recuperación al volver a abrir la app
✅ Diálogo de recuperación con información detallada
✅ Botón de cancelar venta visible cuando hay contenido
✅ Eliminación automática al confirmar venta
✅ Manejo de estados y navegación

## Criterios de Aceptación Cumplidos

✅ **La venta iniciada se mantiene en memoria aunque el usuario navegue a otras pantallas**
- El borrador se guarda automáticamente al modificar cualquier dato

✅ **Si el usuario cierra la app o el dispositivo se apaga, la venta se recupera automáticamente**
- Usa SharedPreferences para persistencia local
- Se recupera al volver a abrir la pantalla de nueva venta

✅ **Al confirmar la venta → se guarda definitivamente en la base de datos y se elimina el borrador**
- Implementado en el método `_confirmarVenta()`

✅ **Al cancelar la venta → se descarta el borrador completamente**
- Implementado con botón de cancelar y diálogo de confirmación

✅ **Si el usuario intenta iniciar una nueva venta mientras existe un borrador, mostrar un diálogo**
- Diálogo implementado en `_mostrarDialogoRecuperarBorrador()`
- Muestra información del cliente, productos y tiempo transcurrido
- Opciones: "Continuar" o "Nueva Venta"

## Uso

### Para Desarrolladores

1. El provider está registrado en `main.dart`:
```dart
ChangeNotifierProvider(create: (_) => VentaBorradorProvider()),
```

2. Para acceder al provider en cualquier pantalla:
```dart
final borradorProvider = Provider.of<VentaBorradorProvider>(context, listen: false);
```

3. Para guardar datos en el borrador:
```dart
await borradorProvider.actualizarBorrador(
  cliente: clienteSeleccionado,
  productos: productosSeleccionados,
  preciosEspeciales: preciosEspeciales,
);
```

4. Para verificar si existe un borrador:
```dart
bool existe = await borradorProvider.verificarExistenciaBorrador();
```

5. Para eliminar el borrador:
```dart
await borradorProvider.eliminarBorrador();
```

## Beneficios para el Negocio

- ✨ **Evita pérdida de tiempo**: Los empleados no tienen que reingresar datos
- 🎯 **Reduce errores**: Minimiza errores en la facturación
- 💼 **Experiencia profesional**: Da una sensación de aplicación robusta y confiable
- 🔄 **Flujo de trabajo flexible**: Permite consultar información sin perder el progreso
- 📱 **Recuperación ante interrupciones**: Protege contra cierres accidentales

## Notas Técnicas

- **Almacenamiento**: SharedPreferences (almacenamiento local clave-valor)
- **Serialización**: JSON para convertir el modelo a string
- **Estado**: Provider para gestión de estado reactivo
- **Persistencia**: Automática en cada cambio significativo
- **Limpieza**: Automática al confirmar o cancelar venta

## Testing

Para probar el sistema:
1. Inicia una nueva venta
2. Selecciona un cliente y agrega productos
3. Navega a otra pantalla (por ejemplo, clientes)
4. Vuelve a la pantalla de ventas
5. Verifica que la venta se haya mantenido

Para probar la recuperación:
1. Inicia una venta con cliente y productos
2. Cierra completamente la aplicación
3. Vuelve a abrir la app
4. Navega a nueva venta
5. Verifica que aparezca el diálogo de recuperación

Para probar la cancelación:
1. Inicia una venta con datos
2. Presiona el botón de cancelar (ícono X en AppBar)
3. Confirma la cancelación
4. Verifica que se cierre la pantalla y se elimine el borrador

