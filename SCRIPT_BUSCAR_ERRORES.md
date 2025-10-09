# Script para Encontrar Lugares que Necesitan Manejo de Errores

## 🔍 Cómo encontrar todos los lugares que necesitan actualización

### Método 1: Búsqueda por Patrón (Recomendado)

Usa estos comandos en tu terminal dentro de la carpeta `TobacoFrontend`:

#### Buscar todos los catch sin manejo de conexión:
```bash
# PowerShell (Windows)
Get-ChildItem -Path "lib\Screens" -Filter "*.dart" -Recurse | Select-String -Pattern "catch \(e\)" | Select-Object Path, LineNumber

# Git Bash / Linux / Mac
grep -rn "catch (e)" lib/Screens/ --include="*.dart"
```

### Método 2: Búsqueda en VS Code / Cursor

1. Presiona `Ctrl + Shift + F` (búsqueda en todos los archivos)
2. Busca: `catch (e)`
3. Filtra por carpeta: `lib/Screens`
4. Extensión: `*.dart`

### Método 3: Lista Manual de Archivos a Revisar

Aquí está la lista completa de archivos que probablemente necesitan actualización:

## 📝 Lista de Archivos por Prioridad

### Alta Prioridad (Operaciones Críticas)

#### Auth
- [ ] `lib/Screens/Auth/login_screen.dart`
  - **Métodos a revisar**: Login, validación de token

#### Clientes
- [ ] `lib/Screens/Clientes/clientes_screen.dart`
  - **Métodos a revisar**: Cargar clientes, crear, editar, eliminar
- [ ] `lib/Screens/Clientes/detalleCliente_screen.dart`
  - **Métodos a revisar**: Cargar detalle, actualizar datos
- [x] `lib/Screens/Clientes/preciosEspeciales_screen.dart` ✅ YA ACTUALIZADO
  - **Métodos actualizados**: `_loadData()`, `_eliminarPrecioEspecial()`
- [ ] `lib/Screens/Clientes/editarPreciosEspeciales_screen.dart`
  - **Métodos a revisar**: Guardar precios especiales
- [ ] `lib/Screens/Clientes/historialVentas_screen.dart`
  - **Métodos a revisar**: Cargar historial de ventas
- [ ] `lib/Screens/Clientes/wizardNuevoCliente_screen.dart`
  - **Métodos a revisar**: Crear cliente
- [ ] `lib/Screens/Clientes/wizardEditarCliente_screen.dart`
  - **Métodos a revisar**: Editar cliente

#### Productos
- [ ] `lib/Screens/Productos/productos_screen.dart`
  - **Métodos a revisar**: Cargar productos, eliminar, activar/desactivar
- [ ] `lib/Screens/Productos/nuevoProducto_screen.dart`
  - **Métodos a revisar**: Crear producto
- [ ] `lib/Screens/Productos/editarProducto_screen.dart`
  - **Métodos a revisar**: Editar producto
- [ ] `lib/Screens/Productos/detalleProducto_screen.dart`
  - **Métodos a revisar**: Cargar detalle

#### Ventas
- [ ] `lib/Screens/Ventas/ventas_screen.dart`
  - **Métodos a revisar**: Cargar ventas, eliminar
- [ ] `lib/Screens/Ventas/nuevaVenta_screen.dart`
  - **Métodos a revisar**: Crear venta
- [ ] `lib/Screens/Ventas/detalleVentas_screen.dart`
  - **Métodos a revisar**: Cargar detalle de venta
- [ ] `lib/Screens/Ventas/resumenVenta_screen.dart`
  - **Métodos a revisar**: Mostrar resumen
- [ ] `lib/Screens/Ventas/seleccionarProducto_screen.dart`
  - **Métodos a revisar**: Cargar productos
- [ ] `lib/Screens/Ventas/seleccionarProductoConPreciosEspeciales_screen.dart`
  - **Métodos a revisar**: Cargar productos con precios
- [ ] `lib/Screens/Ventas/metodoPago_screen.dart`
  - **Métodos a revisar**: Procesar pago

### Prioridad Media

#### Admin
- [ ] `lib/Screens/Admin/categorias_screen.dart`
  - **Métodos a revisar**: Cargar categorías, crear, editar, eliminar, reordenar
- [ ] `lib/Screens/Admin/user_management_screen.dart`
  - **Métodos a revisar**: Cargar usuarios, crear, editar, eliminar

#### Otros
- [ ] `lib/Screens/Cotizaciones/cotizaciones_screen.dart`
  - **Métodos a revisar**: Cargar cotizaciones
- [ ] `lib/Screens/Deudas/deudas_screen.dart`
  - **Métodos a revisar**: Cargar deudas
- [ ] `lib/Screens/Loading/loading_screen.dart`
  - **Métodos a revisar**: Validación inicial
- [ ] `lib/Screens/menu_screen.dart`
  - **Métodos a revisar**: Cargar datos del usuario

## 🔧 Patrón a Aplicar en Cada Archivo

Para cada archivo que encuentres, busca bloques que se vean así:

### ❌ ANTES (Incorrecto):
```dart
try {
  final data = await servicio.obtenerDatos();
  // procesar datos...
} catch (e) {
  print('Error: $e');
  // o mostrar snackbar genérico
}
```

### ✅ DESPUÉS (Correcto):
```dart
try {
  final data = await servicio.obtenerDatos();
  // procesar datos...
} catch (e) {
  if (mounted && Apihandler.isConnectionError(e)) {
    await Apihandler.handleConnectionError(context, e);
  } else if (mounted) {
    await AppDialogs.showErrorDialog(
      context: context,
      message: 'Error: ${e.toString().replaceFirst('Exception: ', '')}',
    );
  }
}
```

### 📦 Import necesario:
```dart
import '../../Helpers/api_handler.dart';
```

## 📊 Checklist de Verificación

Para cada archivo que actualices:

- [ ] Importar `api_handler.dart`
- [ ] Buscar todos los bloques `catch (e)`
- [ ] Verificar que sea una operación de red
- [ ] Actualizar con el patrón correcto
- [ ] Verificar que se use `mounted` antes de mostrar diálogos
- [ ] Usar `await` en los diálogos
- [ ] Probar apagando el backend

## 🧪 Cómo Probar Cada Pantalla

1. **Apaga el backend** (TobacoApi)
2. **Navega a la pantalla** que actualizaste
3. **Realiza la acción** que hace la llamada al backend
4. **Verifica que aparezca** el diálogo "Servidor No Disponible"
5. **Enciende el backend**
6. **Presiona "Entendido"** en el diálogo
7. **Reintenta la acción** - debería funcionar normalmente

## 💡 Consejos Importantes

### 1. No todos los catch necesitan actualización
Solo actualiza los que hacen llamadas al backend. Por ejemplo:
- ✅ `await ClienteService().obtenerClientes()` - SÍ necesita
- ❌ `int.parse(texto)` - NO necesita (no es red)

### 2. Mantén consistencia
Usa siempre el mismo patrón para que el código sea predecible.

### 3. Prioriza por uso
Actualiza primero las pantallas que más se usan:
1. Login
2. Clientes
3. Ventas
4. Productos

### 4. Mantén los mensajes específicos
Personaliza el mensaje según la operación:
```dart
message: 'Error al cargar clientes: ...'  // Específico
message: 'Error al eliminar producto: ...' // Específico
message: 'Error: ...'                      // Genérico (evitar)
```

## 📈 Progreso

Lleva el registro de tu progreso:

```
Total de archivos: ~25
Completados: 1 (preciosEspeciales_screen.dart)
Pendientes: 24
Progreso: 4%
```

## 🚀 Script Automatizado (Opcional)

Si quieres un script que te ayude a encontrar los archivos, guarda esto como `find_catch_blocks.ps1`:

```powershell
# PowerShell Script
$screenPath = "lib\Screens"
$files = Get-ChildItem -Path $screenPath -Filter "*.dart" -Recurse

Write-Host "Buscando bloques catch en archivos .dart..." -ForegroundColor Green
Write-Host ""

foreach ($file in $files) {
    $matches = Select-String -Path $file.FullName -Pattern "catch \(e\)" -AllMatches
    
    if ($matches) {
        Write-Host "📄 $($file.Name)" -ForegroundColor Yellow
        Write-Host "   Ruta: $($file.FullName)" -ForegroundColor Gray
        Write-Host "   Catch blocks encontrados: $($matches.Count)" -ForegroundColor Cyan
        Write-Host ""
    }
}

Write-Host "Búsqueda completada!" -ForegroundColor Green
```

**Uso:**
```powershell
cd TobacoFrontend
.\find_catch_blocks.ps1
```

---

**Última actualización**: 8 de Octubre, 2025
**Estado**: Documento activo - actualizar según avances
