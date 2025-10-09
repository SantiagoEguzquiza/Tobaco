# Nueva Venta - Arquitectura Modular

## 📁 Estructura

```
NuevaVenta/
├── widgets/
│   ├── cliente_section.dart          # Muestra información del cliente seleccionado
│   ├── agregar_producto_button.dart  # Botón para agregar productos
│   ├── line_item_tile.dart           # Item individual de producto con controles
│   ├── line_items_list.dart          # Lista de productos agregados
│   ├── empty_state_venta.dart        # Estado vacío cuando no hay productos
│   ├── confirmar_venta_footer.dart   # Footer con botón de confirmar venta
│   └── widgets.dart                  # Archivo barrel (exports)
└── README.md                         # Esta documentación
```

## 🎯 Componentes

### 1. ClienteSection
**Propósito:** Muestra la información del cliente seleccionado con su deuda y descuento global.

**Props:**
- `cliente`: Cliente seleccionado
- `onCambiarCliente`: Callback para cambiar de cliente
- `mostrarDescuentoGlobal`: (Opcional) Mostrar banner de descuento

**Características:**
- ✅ Adapta colores según modo claro/oscuro
- ✅ Muestra deuda si tiene
- ✅ Banner de descuento global automático
- ✅ Botón para cambiar cliente
- ✅ Diseño consistente con otros headers

---

### 2. AgregarProductoButton
**Propósito:** Botón grande y prominente para navegar a la pantalla de selección de productos.

**Props:**
- `onPressed`: Callback al presionar el botón
- `enabled`: (Opcional) Habilitar/deshabilitar el botón

**Características:**
- ✅ Diseño responsive
- ✅ Estados enabled/disabled
- ✅ Ícono de carrito de compras
- ✅ Color verde distintivo

---

### 3. LineItemTile
**Propósito:** Muestra un producto individual en la lista con todos sus controles.

**Props:**
- `producto`: ProductoSeleccionado a mostrar
- `onEliminar`: Callback para eliminar el producto
- `precioEspecial`: (Opcional) Precio especial si aplica
- `descuentoGlobal`: (Opcional) Descuento global del cliente

**Características:**
- ✅ Swipe-to-delete con Slidable
- ✅ Muestra cantidad (solo lectura)
- ✅ Muestra precio original tachado si hay descuento
- ✅ Indicador de precio especial
- ✅ Calcula subtotal automáticamente
- ✅ Adapta colores según tema
- ⚠️ **Para editar cantidades, usar SeleccionarProductosScreen**

---

### 4. LineItemsList
**Propósito:** Contenedor para la lista de productos, mapea cada producto a un LineItemTile.

**Props:**
- `productos`: Lista de ProductoSeleccionado
- `onEliminar`: Callback con index del producto a eliminar
- `preciosEspeciales`: Map de precios especiales por producto
- `descuentoGlobal`: (Opcional) Descuento global del cliente

**Características:**
- ✅ Gestión de índices automática
- ✅ Propagación de callbacks
- ✅ Sin lógica de negocio (widget "tonto")

---

### 5. EmptyStateVenta
**Propósito:** Muestra un mensaje amigable cuando no hay productos seleccionados.

**Props:** Ninguna (stateless simple)

**Características:**
- ✅ Ícono de carrito vacío
- ✅ Mensaje claro y directo
- ✅ Altura fija para centrado correcto
- ✅ Adapta colores según tema

---

### 6. ConfirmarVentaFooter
**Propósito:** Footer fijo con resumen y botón de confirmación.

**Props:**
- `onConfirmar`: Callback al confirmar venta
- `enabled`: Si el botón está habilitado
- `total`: Total de la venta
- `cantidadProductos`: Cantidad de productos
- `descuento`: (Opcional) Monto de descuento aplicado

**Características:**
- ✅ SafeArea para evitar notch/bordes
- ✅ Manejo de teclado (no tapa contenido)
- ✅ Muestra subtotal y descuento si aplica
- ✅ Formato de precio con decimales
- ✅ Adapta colores según tema
- ✅ No se muestra si no hay productos

---

## 🔄 Flujo de Datos

```
NuevaVentaScreen (Orquestador)
       │
       ├──> ClienteSection
       │     └── onCambiarCliente() → setState en screen
       │
       ├──> AgregarProductoButton
       │     └── onPressed() → Navigate a SeleccionarProductosScreen
       │
       ├──> LineItemsList
       │     └──> LineItemTile (múltiples)
       │           ├── onCantidadChanged() → setState en screen
       │           └── onEliminar() → setState en screen
       │
       ├──> EmptyStateVenta (cuando lista vacía)
       │
       └──> ConfirmarVentaFooter
             └── onConfirmar() → Procesa venta en screen
```

## 📊 Beneficios de la Refactorización

### Mantenibilidad ✅
- Cada componente tiene una responsabilidad única
- Código más fácil de entender y modificar
- Menos líneas por archivo (~150-200 vs 1300+)

### Reutilización ✅
- Widgets pueden usarse en otras pantallas
- `LineItemTile` puede usarse en resumen de venta
- `ClienteSection` puede usarse en otras funcionalidades

### Testing ✅
- Cada widget se puede testear independientemente
- Más fácil de hacer unit tests
- Props claramente definidas

### Rendimiento ✅
- Solo se reconstruyen los widgets necesarios
- Menos rebuilds innecesarios al cambiar cantidades
- Mejor uso de memoria

### Escalabilidad ✅
- Fácil agregar nuevas funcionalidades
- Estructura clara para futuros desarrolladores
- Preparado para cupones, notas, etc.

## 🎨 Consistencia de Diseño

Todos los widgets siguen las siguientes convenciones:

- ✅ Usan `AppTheme` para colores y estilos
- ✅ Soporte completo de modo claro/oscuro
- ✅ BorderRadius de 12-20px para consistencia
- ✅ Padding y spacing estandarizados
- ✅ Elevación y sombras según el tema

## 🚀 Uso

```dart
import 'NuevaVenta/widgets/widgets.dart';

// En el build method:
ClienteSection(
  cliente: clienteSeleccionado!,
  onCambiarCliente: cambiarCliente,
)

LineItemsList(
  productos: productosSeleccionados,
  onCantidadChanged: (index, cantidad) { ... },
  onEliminar: (index) { ... },
  preciosEspeciales: preciosEspeciales,
  descuentoGlobal: clienteSeleccionado?.descuentoGlobal,
)

ConfirmarVentaFooter(
  onConfirmar: _confirmarVenta,
  enabled: !isProcessingVenta,
  total: _calcularTotalConDescuento(),
  cantidadProductos: productosSeleccionados.length,
  descuento: _calcularDescuento() > 0 ? _calcularDescuento() : null,
)
```

## 📝 Notas

- El widget `DiscountBanner` fue integrado directamente en `ClienteSection` para simplificar
- La lógica de negocio permanece en `NuevaVentaScreen` 
- Los widgets son "tontos" (presentational) y reciben datos vía props
- Se eliminaron ~200 líneas de código duplicado del archivo principal

