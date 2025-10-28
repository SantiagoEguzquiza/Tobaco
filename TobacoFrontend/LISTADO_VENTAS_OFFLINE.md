# 📋 Listado de Ventas con Indicadores Offline

## ✅ ¿Qué se corrigió?

Antes, las ventas offline **no aparecían** en el listado. Ahora:

1. ✅ **Con conexión**: Muestra ventas del servidor + ventas offline pendientes
2. ✅ **Sin conexión**: Muestra solo ventas offline
3. ✅ **Indicador visual**: Badge naranja para ventas pendientes de sincronización
4. ✅ **Indicador de error**: Badge rojo para ventas que fallaron al sincronizar

---

## 🔄 **Cómo Funciona Ahora**

### **Antes (❌ Problema):**
```
Usuario crea venta offline
↓
Venta se guarda en SQLite ✅
↓
Usuario ve listado de ventas
↓
❌ Venta offline NO aparece (problema)
```

### **Ahora (✅ Solución):**
```
Usuario crea venta offline
↓
Venta se guarda en SQLite ✅
↓
Usuario ve listado de ventas
↓
✅ Venta offline APARECE con badge "Pendiente"
↓
Cuando hay conexión
↓
✅ Se sincroniza y el badge desaparece
```

---

## 💻 **Cómo Usar en tu Pantalla de Ventas**

### **Ejemplo Completo:**

```dart
import 'package:tobaco/Widgets/venta_offline_badge.dart';

class VentasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<VentasProvider>(
      builder: (context, ventasProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Ventas'),
            actions: [
              // Badge de sincronización
              SyncStatusBadge(),
            ],
          ),
          body: Column(
            children: [
              // Widget de estado de sincronización
              SyncStatusWidget(showDetails: true),
              
              // Listado de ventas
              Expanded(
                child: ListView.builder(
                  itemCount: ventasProvider.ventas.length,
                  itemBuilder: (context, index) {
                    final venta = ventasProvider.ventas[index];
                    
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(venta.cliente.nombre[0]),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(venta.cliente.nombre),
                          ),
                          // ⭐ Badge si es offline
                          if (venta.id == null)
                            VentaOfflineBadge(
                              isPending: true,
                              compact: true,
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '\$${venta.total.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        _formatearFecha(venta.fecha),
                      ),
                      onTap: () {
                        // Ver detalle de venta
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleVentaScreen(venta: venta),
                          ),
                        );
                      },
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

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
```

---

## 🎨 **Variantes del Badge**

### **1. Versión Compacta (solo icono):**

```dart
VentaOfflineBadge(
  isPending: true,
  compact: true,  // ← Compacto
)
```

Resultado: `🟠` (solo icono naranja)

### **2. Versión Completa (con texto):**

```dart
VentaOfflineBadge(
  isPending: true,
  compact: false,  // ← Con texto
)
```

Resultado: `🟠 Pendiente` (icono + texto)

### **3. Venta con error:**

```dart
VentaOfflineBadge(
  isPending: false,
  isFailed: true,  // ← Error en sync
)
```

Resultado: `🔴 Error` (icono rojo + texto)

---

## 📊 **Identificar Ventas Offline**

### **Método 1: Por ID null**

```dart
final venta = ventasProvider.ventas[index];

if (venta.id == null) {
  // Es una venta offline
  print('Esta venta está pendiente de sincronización');
}
```

### **Método 2: Usando Extension**

```dart
import 'package:tobaco/Widgets/venta_offline_badge.dart';

final venta = ventasProvider.ventas[index];

if (venta.isOffline) {  // ← Extension helper
  // Es una venta offline
  print('Esta venta está pendiente de sincronización');
}
```

---

## 🎨 **Ejemplo con Card Personalizado**

```dart
Card(
  margin: EdgeInsets.all(8),
  child: Padding(
    padding: EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              venta.cliente.nombre,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // ⭐ Badge de estado
            if (venta.id == null)
              VentaOfflineBadge(
                isPending: true,
                compact: false,
              ),
          ],
        ),
        SizedBox(height: 8),
        Text('Total: \$${venta.total.toStringAsFixed(2)}'),
        Text('Fecha: ${_formatearFecha(venta.fecha)}'),
        
        // Mensaje adicional si es offline
        if (venta.id == null) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se sincronizará cuando haya conexión',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  ),
)
```

---

## 🔍 **Logs que Verás**

### **Con conexión:**

```
📦 VentasOfflineService: 2 ventas offline encontradas
📡 VentasOfflineService: 45 ventas online obtenidas
✅ VentasOfflineService: Total ventas: 47 (2 offline + 45 online)
```

### **Sin conexión:**

```
📦 VentasOfflineService: 2 ventas offline encontradas
📴 VentasOfflineService: Sin conexión, solo ventas offline
✅ VentasOfflineService: Total ventas: 2 (2 offline + 0 online)
```

### **Después de sincronizar:**

```
🔄 SyncService: Obteniendo ventas pendientes...
📤 SyncService: Enviando venta local_1234567890 al servidor...
✅ SyncService: Venta local_1234567890 sincronizada correctamente
📦 VentasOfflineService: 0 ventas offline encontradas
📡 VentasOfflineService: 47 ventas online obtenidas
✅ VentasOfflineService: Total ventas: 47 (0 offline + 47 online)
```

---

## 🎯 **Orden de las Ventas**

Las ventas se muestran en este orden:

1. **Primero**: Ventas offline (pendientes/fallidas)
2. **Después**: Ventas online (sincronizadas)

Esto asegura que las ventas pendientes sean **fáciles de identificar** al inicio de la lista.

---

## ✨ **Ejemplo Completo con Filtros**

```dart
class VentasScreen extends StatefulWidget {
  @override
  _VentasScreenState createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  bool _mostrarSoloPendientes = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<VentasProvider>(
      builder: (context, ventasProvider, child) {
        // Filtrar ventas si es necesario
        List<dynamic> ventasAMostrar = _mostrarSoloPendientes
            ? ventasProvider.ventas.where((v) => v.id == null).toList()
            : ventasProvider.ventas;

        return Scaffold(
          appBar: AppBar(
            title: Text('Ventas'),
            actions: [
              // Toggle para mostrar solo pendientes
              IconButton(
                icon: Icon(_mostrarSoloPendientes 
                  ? Icons.filter_list_off 
                  : Icons.filter_list
                ),
                onPressed: () {
                  setState(() {
                    _mostrarSoloPendientes = !_mostrarSoloPendientes;
                  });
                },
                tooltip: _mostrarSoloPendientes 
                  ? 'Mostrar todas' 
                  : 'Solo pendientes',
              ),
              // Badge de sincronización
              SyncStatusBadge(),
            ],
          ),
          body: Column(
            children: [
              // Widget de estado
              SyncStatusWidget(showDetails: true),
              
              // Chip de filtro activo
              if (_mostrarSoloPendientes)
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.orange.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 16),
                      SizedBox(width: 8),
                      Text('Mostrando solo ventas pendientes'),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _mostrarSoloPendientes = false;
                          });
                        },
                        child: Text('Limpiar'),
                      ),
                    ],
                  ),
                ),
              
              // Listado
              Expanded(
                child: ventasAMostrar.isEmpty
                    ? Center(
                        child: Text(
                          _mostrarSoloPendientes
                              ? 'No hay ventas pendientes'
                              : 'No hay ventas',
                        ),
                      )
                    : ListView.builder(
                        itemCount: ventasAMostrar.length,
                        itemBuilder: (context, index) {
                          final venta = ventasAMostrar[index];
                          return _buildVentaTile(venta);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVentaTile(dynamic venta) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(venta.cliente.nombre[0]),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(venta.cliente.nombre),
          ),
          if (venta.id == null)
            VentaOfflineBadge(
              isPending: true,
              compact: true,
            ),
        ],
      ),
      subtitle: Text('\$${venta.total.toStringAsFixed(2)}'),
    );
  }
}
```

---

## 🎉 **Resumen**

### **Lo que cambió:**

1. ✅ `obtenerVentas()` ahora **combina** ventas online + offline
2. ✅ Las ventas offline **siempre** aparecen en el listado
3. ✅ Las ventas offline van **primero** (fáciles de ver)
4. ✅ Badge visual para identificarlas
5. ✅ Logs claros para debugging

### **Cómo identificar venta offline:**

```dart
// Opción 1
if (venta.id == null) { ... }

// Opción 2
if (venta.isOffline) { ... }
```

### **Cómo mostrar badge:**

```dart
// Compacto
VentaOfflineBadge(isPending: true, compact: true)

// Completo
VentaOfflineBadge(isPending: true)
```

---

**¡Ahora tu listado de ventas funciona perfectamente offline! 🎉**

