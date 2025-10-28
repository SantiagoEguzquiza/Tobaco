# Sincronización Automática de Ventas Offline

## 🎯 Objetivo

Sincronizar automáticamente las ventas creadas offline cuando el backend vuelva a estar disponible.

## ⚡ Cómo Funciona

### 1. **Sincronización Automática (Cada 30 segundos)**

El servicio `SimpleSyncService` se ejecuta automáticamente:

```
App inicia
  ↓
SimpleSyncService.iniciar() (en main.dart)
  ↓
Timer cada 30 segundos
  ↓
¿Hay ventas offline pendientes?
  ↓ SI
Intenta enviar al servidor
  ↓
✅ Éxito → Marca como sincronizada
❌ Fallo → Reintenta en 30 seg
```

### 2. **Sincronización Manual**

El usuario puede sincronizar manualmente tocando el badge de ventas pendientes:

```
Badge muestra: 🔔 3
  ↓
Usuario toca el badge
  ↓
Sincroniza inmediatamente
  ↓
Muestra resultado: "3 ventas sincronizadas"
```

## 📁 Archivos del Sistema

### 1. `simple_sync_service.dart` ⭐ NUEVO
- **Función**: Sincroniza ventas offline automáticamente
- **Frecuencia**: Cada 30 segundos
- **Métodos**:
  - `iniciar()` - Inicia el servicio de sincronización
  - `sincronizarAhora()` - Sincroniza inmediatamente
  - `detener()` - Detiene el servicio

### 2. `main.dart` (ACTUALIZADO)
- Inicia `SimpleSyncService` al arrancar la app
- Se ejecuta antes de cargar la UI

### 3. `ventas_provider.dart` (ACTUALIZADO)
- Agregado método `sincronizarAhora()` para sincronización manual
- Agregado método `contarVentasPendientes()` para mostrar badge

### 4. `ventas_screen.dart` (ACTUALIZADO)
- Badge en AppBar muestra ventas pendientes
- Al tocar el badge, sincroniza manualmente
- Recarga la lista después de sincronizar

## 🔄 Flujo Completo

### Crear Venta Offline:
```
1. Usuario crea venta sin backend
2. Se guarda en ventas_offline.db ✅
3. Badge aparece: 🔔 1
```

### Sincronización Automática:
```
5 segundos después del inicio de la app:
  ↓
Intenta sincronizar

Cada 30 segundos:
  ↓
¿Hay pendientes? → Intenta sincronizar
```

### Cuando Backend Vuelve:
```
Backend está disponible
  ↓
Timer detecta (máximo 30 seg)
  ↓
Lee ventas_offline (synced = 0)
  ↓
Para cada venta:
  - Envía al servidor (timeout 5 seg)
  - Si éxito → Marca synced = 1
  - Si falla → Reintenta después
  ↓
Limpia ventas sincronizadas
  ↓
Badge desaparece ✅
```

## 📊 Estados de Sincronización

| Estado | Descripción | Campo en BD |
|---|---|---|
| **Pendiente** | Creada offline, esperando sincronización | `synced = 0` |
| **Sincronizada** | Enviada al servidor exitosamente | `synced = 1` |

## 🎨 UI - Badge de Ventas Pendientes

### Ubicación:
- **AppBar** de la pantalla de Ventas
- Esquina superior derecha

### Apariencia:
```
🔔 3  ← Badge con número de ventas pendientes
```

### Funcionalidad:
- **Ver**: Muestra cuántas ventas hay pendientes
- **Tocar**: Sincroniza inmediatamente
- **Desaparece**: Cuando no hay ventas pendientes

## 🧪 Cómo Probar

### Paso 1: Crear Ventas Offline
```bash
# 1. APAGA el backend
# 2. Crea 2-3 ventas
# 3. Verás el badge: 🔔 3
```

**Logs esperados:**
```
⚠️ VentasProvider: Error creando venta online: TimeoutException
📴 VentasProvider: Guardando venta offline...
✅ VentasOfflineCacheService: Venta guardada offline (ID: 1)
```

### Paso 2: Sincronización Automática
```bash
# 1. PRENDE el backend
# 2. Espera máximo 30 segundos
# 3. El badge desaparecerá automáticamente
```

**Logs esperados:**
```
🔄 SimpleSyncService: Obteniendo ventas pendientes...
📤 SimpleSyncService: 3 ventas pendientes de sincronizar
📤 SimpleSyncService: Sincronizando venta offline ID: 1
✅ SimpleSyncService: Venta 1 sincronizada exitosamente
✅ SimpleSyncService: Sincronización completada - 3 exitosas, 0 fallidas
🧹 SimpleSyncService: Ventas sincronizadas limpiadas
```

### Paso 3: Sincronización Manual
```bash
# 1. Con ventas pendientes
# 2. Toca el badge 🔔 3
# 3. Verás mensaje: "3 ventas sincronizadas"
# 4. El badge desaparece
```

## ⚙️ Configuración

### Frecuencia de Sincronización
```dart
// En simple_sync_service.dart, línea ~29
Timer.periodic(Duration(seconds: 30), ...);  // ← Cambiar aquí

// Opciones:
// - 10 segundos: Muy frecuente (más batería)
// - 30 segundos: Balanceado (recomendado)
// - 60 segundos: Menos frecuente (ahorra batería)
```

### Timeout de Sincronización
```dart
// En simple_sync_service.dart, línea ~72
.timeout(Duration(seconds: 5));  // ← Cambiar aquí

// Opciones:
// - 3 segundos: Rápido pero puede fallar con conexión lenta
// - 5 segundos: Balanceado (recomendado)
// - 10 segundos: Más tolerante pero más lento
```

## 📈 Estadísticas

El servicio lleva registro de:
- ✅ Ventas sincronizadas exitosamente
- ❌ Ventas que fallaron (se reintentarán)
- ⏱️ Tiempo de la última sincronización

## 🔔 Notificaciones

Actualmente:
- ✅ Badge visual en AppBar
- ✅ SnackBar al sincronizar manualmente

Puedes agregar:
- 🔔 Notificación push cuando se sincronice
- 📊 Pantalla de estadísticas de sincronización
- 📝 Log de sincronizaciones en configuración

## ⚠️ Manejo de Errores

### Si falla la sincronización:
1. **Timeout**: Reintenta en el próximo ciclo (30 seg)
2. **Error de red**: Reintenta en el próximo ciclo
3. **Error del servidor**: La venta queda pendiente

### Ventas que fallan repetidamente:
- Se quedan en estado `synced = 0`
- Se reintentarán indefinidamente
- Puedes agregar un límite de reintentos si quieres

## 🎉 Resumen

Ahora tienes sincronización automática completa:
1. ✅ Se inicia automáticamente al abrir la app
2. ✅ Sincroniza cada 30 segundos
3. ✅ Badge muestra ventas pendientes
4. ✅ Sincronización manual tocando el badge
5. ✅ Limpia ventas sincronizadas automáticamente
6. ✅ Reintenta ventas que fallan

¡Sistema offline completamente funcional! 🚀

