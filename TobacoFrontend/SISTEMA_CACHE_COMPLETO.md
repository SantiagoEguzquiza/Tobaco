# 📦 Sistema de Caché Completo - Funcionamiento Offline Total

## 🎯 ¿Qué se implementó?

Se ha creado un **sistema de caché híbrido completo** que permite que la app funcione 100% offline:

### ✅ **Caché de Datos Maestros**
- **Clientes**: Se guardan localmente para selección offline
- **Productos**: Se guardan localmente para agregar a ventas offline
- **Categorías**: Se guardan para organización offline

### ✅ **Sincronización Automática**
- Con conexión: Datos del servidor → SQLite (caché)
- Sin conexión: Datos de SQLite (caché) → UI

### ✅ **Ventas Offline**
- Las ventas creadas offline usan clientes/productos de caché
- Se sincronizan cuando hay conexión

---

## 🔄 **Flujo del Sistema**

### **Primera vez (CON conexión):**
```
1. Usuario abre app
2. App obtiene clientes del servidor
3. App guarda clientes en SQLite (caché)
4. App obtiene productos del servidor
5. App guarda productos en SQLite (caché)
6. Usuario puede usar la app normalmente
```

### **Segunda vez (SIN conexión):**
```
1. Usuario abre app sin internet
2. App detecta: NO HAY CONEXIÓN
3. App lee clientes desde SQLite (caché)
4. App lee productos desde SQLite (caché)
5. Usuario puede crear ventas offline
6. Ventas se guardan localmente
7. Cuando vuelve conexión → Todo se sincroniza
```

---

## 📊 **Arquitectura de Caché**

```
┌─────────────────────────────────────────┐
│         PROVIDERS (UI Layer)            │
│  - ClienteProvider                      │
│  - ProductoProvider                     │
│  - VentasProvider                       │
└──────────────┬──────────────────────────┘
               │
    ¿Hay conexión?
               │
        ┌──────┴──────┐
        │             │
    ✅ SÍ         ❌ NO
        │             │
        ▼             ▼
┌──────────────┐  ┌────────────┐
│   BACKEND    │  │   CACHÉ    │
│   (API)      │  │  (SQLite)  │
└──────┬───────┘  └─────┬──────┘
       │                 │
       └────────┬────────┘
                │
         Guardar en caché
                │
                ▼
        ┌──────────────┐
        │ CacheManager │
        │  (SQLite)    │
        └──────────────┘
```

---

## 🗄️ **Base de Datos de Caché**

### **Archivo:** `tobaco_cache.db`

### **Tablas:**

1. **`clientes_cache`**
   ```sql
   - id (PK)
   - nombre
   - direccion
   - telefono
   - deuda
   - descuento_global
   - precios_especiales_json
   - cached_at
   - updated_at
   ```

2. **`productos_cache`**
   ```sql
   - id (PK)
   - nombre
   - precio
   - stock
   - categoria_id
   - categoria_nombre
   - half
   - activo
   - cached_at
   - updated_at
   ```

3. **`categorias_cache`**
   ```sql
   - id (PK)
   - nombre
   - orden
   - activa
   - cached_at
   - updated_at
   ```

---

## 💻 **Código de Ejemplo**

### **Uso en ClienteProvider:**

```dart
// CON CONEXIÓN
final clientes = await obtenerClientes();
// → Obtiene del backend
// → Guarda en SQLite
// → Retorna clientes

// SIN CONEXIÓN
final clientes = await obtenerClientes();
// → Lee de SQLite
// → Retorna clientes cached
```

### **Uso en UI:**

```dart
// En tu screen
final clienteProvider = Provider.of<ClienteProvider>(context);

// Mostrar indicador si está usando caché
if (clienteProvider.isUsingCache) {
  // Mostrar banner: "Datos en caché (offline)"
}

// Los clientes funcionan igual, online u offline
final clientes = await clienteProvider.obtenerClientes();
```

---

## 🎨 **Widgets Disponibles**

### **1. CacheIndicator** (Para mostrar estado)

```dart
import 'package:tobaco/Widgets/cache_indicator_widget.dart';

// Versión completa
CacheIndicator(
  isUsingCache: clienteProvider.isUsingCache,
)

// Versión compacta (para AppBar)
CacheIndicator(
  isUsingCache: clienteProvider.isUsingCache,
  compact: true,
)
```

### **2. SyncStatusWidget** (Para ventas)

```dart
import 'package:tobaco/Widgets/sync_status_widget.dart';

// Muestra estado de sincronización de ventas
SyncStatusWidget(showDetails: true)
```

---

## 🚀 **Cómo Funciona en la Práctica**

### **Escenario 1: Usuario con conexión normal**

1. Abre app → Datos del servidor
2. Se guardan en SQLite automáticamente
3. Crea una venta → Se envía al servidor
4. Todo funciona normal

### **Escenario 2: Usuario pierde conexión**

1. Abre app → Detecta sin conexión
2. Carga clientes/productos de SQLite
3. Muestra indicador "Datos en caché"
4. Puede seleccionar clientes de la caché
5. Puede agregar productos de la caché
6. Crea venta → Se guarda offline
7. Cuando vuelve conexión → Se sincroniza

### **Escenario 3: Usuario siempre offline (repartidor en zona sin señal)**

1. Primera vez CON señal: Sincroniza todo
2. Sale a repartir SIN señal
3. Durante todo el día:
   - Ve clientes (caché)
   - Ve productos (caché)
   - Crea ventas (offline)
4. Al final del día CON señal:
   - Todas las ventas se sincronizan
   - Se actualiza la caché

---

## 📱 **Ejemplos de Uso**

### **En pantalla de clientes:**

```dart
@override
Widget build(BuildContext context) {
  return Consumer<ClienteProvider>(
    builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Clientes'),
          actions: [
            // Indicador de caché
            if (provider.isUsingCache)
              CacheIndicator(
                isUsingCache: true,
                compact: true,
              ),
          ],
        ),
        body: Column(
          children: [
            // Banner de caché
            CacheIndicator(isUsingCache: provider.isUsingCache),
            
            // Lista de clientes (funciona igual online/offline)
            Expanded(
              child: ListView.builder(
                itemCount: provider.clientes.length,
                itemBuilder: (context, index) {
                  final cliente = provider.clientes[index];
                  return ListTile(
                    title: Text(cliente.nombre),
                    subtitle: Text(cliente.direccion ?? ''),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
```

---

## 🔍 **Logs de Debug**

El sistema imprime logs claros para debugging:

### **Con conexión:**
```
📡 ClienteProvider: Obteniendo clientes del servidor...
💾 CacheManager: Guardando 50 clientes en caché...
✅ CacheManager: Clientes guardados en caché
✅ ClienteProvider: 50 clientes obtenidos y guardados en caché
```

### **Sin conexión:**
```
📴 ClienteProvider: Sin conexión, usando caché local...
📦 CacheManager: 50 clientes obtenidos de caché
📦 ClienteProvider: 50 clientes obtenidos de caché
```

### **Error online, usa caché:**
```
❌ ClienteProvider Error: TimeoutException...
⚠️  ClienteProvider: Error online, intentando con caché...
📦 CacheManager: 50 clientes obtenidos de caché
```

---

## ⚙️ **API del CacheManager**

### **Clientes:**
```dart
final cacheManager = CacheManager();

// Guardar clientes
await cacheManager.cacheClientes(listaClientes);

// Obtener todos
final clientes = await cacheManager.getClientesFromCache();

// Buscar por nombre
final resultados = await cacheManager.buscarClientesEnCache('Juan');

// Actualizar uno
await cacheManager.upsertCliente(cliente);
```

### **Productos:**
```dart
// Guardar productos
await cacheManager.cacheProductos(listaProductos);

// Obtener todos
final productos = await cacheManager.getProductosFromCache();

// Por categoría
final productosCat = await cacheManager.getProductosPorCategoriaFromCache(1);

// Actualizar uno
await cacheManager.upsertProducto(producto);
```

### **Utilidades:**
```dart
// Verificar qué hay en caché
final hasCached = await cacheManager.hasCachedData();
// { 'clientes': true, 'productos': true, 'categorias': false }

// Fecha de última actualización
final lastUpdate = await cacheManager.getLastCacheUpdate();
// { 'clientes': DateTime(...), 'productos': DateTime(...) }

// Limpiar caché
await cacheManager.clearAllCache();
```

---

## 🧪 **Pruebas Recomendadas**

### **Test 1: Flujo completo online → offline → online**

1. **Online**: Abre app, sincroniza clientes/productos
2. **Verifica**: Los datos se guardaron en SQLite
3. **Offline**: Activa modo avión
4. **Verifica**: Puedes ver clientes/productos
5. **Verifica**: Puedes crear venta
6. **Online**: Desactiva modo avión
7. **Verifica**: Venta se sincroniza

### **Test 2: Primera vez sin conexión**

1. **Offline**: Activa modo avión antes de abrir app
2. **Abre** app
3. **Verifica**: Muestra mensaje "No hay datos en caché"
4. **Online**: Desactiva modo avión
5. **Recarga**: Datos se sincronizan
6. **Offline**: Activa modo avión otra vez
7. **Verifica**: Ahora sí funciona offline

### **Test 3: Crear venta con caché**

1. **Online**: Sincroniza datos
2. **Offline**: Activa modo avión
3. **Crea venta**: Selecciona cliente de caché
4. **Agrega productos**: De caché
5. **Guarda venta**: Se guarda offline
6. **Verifica**: Aparece en lista con indicador offline
7. **Online**: Venta se sincroniza

---

## 🎯 **Beneficios del Sistema**

### **Para el Usuario:**
- ✅ App funciona siempre, con o sin internet
- ✅ No pierde tiempo esperando conexión
- ✅ Puede trabajar en cualquier lugar
- ✅ Los datos se sincronizan automáticamente

### **Para el Negocio:**
- ✅ Continuidad operativa 24/7
- ✅ Vendedores pueden trabajar en zonas sin señal
- ✅ Repartidores pueden cerrar ventas en ruta
- ✅ Cero pérdida de ventas por problemas de conexión

### **Técnicos:**
- ✅ Arquitectura sólida y escalable
- ✅ Código limpio y bien documentado
- ✅ Fácil debugging con logs claros
- ✅ Mantenible y extensible

---

## 📊 **Estadísticas del Sistema**

Puedes obtener estadísticas de caché:

```dart
final cacheManager = CacheManager();

// Verificar qué hay en caché
final hasCached = await cacheManager.hasCachedData();
print('Clientes en caché: ${hasCached['clientes']}');
print('Productos en caché: ${hasCached['productos']}');

// Última actualización
final lastUpdate = await cacheManager.getLastCacheUpdate();
final clientesUpdate = lastUpdate['clientes'];
if (clientesUpdate != null) {
  final diff = DateTime.now().difference(clientesUpdate);
  print('Caché de clientes actualizada hace ${diff.inHours} horas');
}
```

---

## 🔮 **Próximas Mejoras (Futuro)**

- [ ] Sincronización diferencial (solo cambios)
- [ ] Comprimir caché para ahorrar espacio
- [ ] Caché con TTL (tiempo de vida)
- [ ] Pre-carga inteligente de datos
- [ ] Sincronización en background
- [ ] Notificaciones de sincronización

---

## 📚 **Archivos Relacionados**

1. **CacheManager**: `lib/Services/Cache/cache_manager.dart`
2. **ConnectivityService**: `lib/Services/Connectivity/connectivity_service.dart`
3. **ClienteProvider**: `lib/Services/Clientes_Service/clientes_provider.dart`
4. **ProductoProvider**: `lib/Services/Productos_Service/productos_provider.dart`
5. **Widgets**: `lib/Widgets/cache_indicator_widget.dart`

---

## ✨ **Resumen**

**Tu app ahora:**
- 📦 **Guarda clientes y productos en caché**
- 📴 **Funciona 100% offline**
- 🔄 **Sincroniza automáticamente**
- 💾 **Las ventas offline usan datos de caché**
- 🎨 **Muestra indicadores claros al usuario**

**Todo funciona transparentemente. El usuario no necesita hacer nada especial.**

---

**¡Sistema de caché completo implementado! 🎉**

