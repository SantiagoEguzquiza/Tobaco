# 🔍 Diagnóstico: No se muestran ventas

## 📋 **Pasos para Diagnosticar**

### **1. Verificar los Logs en Consola**

Cuando abras el listado de ventas, deberías ver estos logs:

```
🔄 VentasScreen: Iniciando carga de ventas...
🔄 VentasScreen: Inicializando provider...
🚀 VentasOfflineService: Inicializando...
🌐 ConnectivityService: Inicializando...
🔄 VentasScreen: Obteniendo ventas...
📦 VentasOfflineService: X ventas offline encontradas
📡 VentasOfflineService: X ventas online obtenidas
✅ VentasScreen: X ventas cargadas exitosamente
```

**¿Qué logs ves tú?** Copia los logs y me los pasas.

---

## 🐛 **Posibles Problemas**

### **Problema 1: Backend no tiene endpoint `/api/health`**

**Síntoma:**
```
⚠️ ConnectivityService: Backend no disponible
🔌 VentasOfflineService: Backend no disponible, retornando 0 ventas offline
```

**Solución:**
```bash
# Reinicia el backend
dotnet run
```

Verifica que puedas acceder a:
```
http://localhost:TU_PUERTO/api/health
```

### **Problema 2: No hay ventas en el backend**

**Síntoma:**
```
📡 VentasOfflineService: 0 ventas online obtenidas
✅ VentasScreen: 0 ventas cargadas exitosamente
```

**Solución:**
- Verifica que haya ventas creadas en el backend
- Crea una venta de prueba

### **Problema 3: Error de autenticación**

**Síntoma:**
```
❌ VentasScreen: Error al cargar las ventas: 401 Unauthorized
```

**Solución:**
- Verifica que estés logueado
- El token podría haber expirado

### **Problema 4: Error en la URL del backend**

**Síntoma:**
```
❌ Error: SocketException
```

**Solución:**
- Verifica la URL en `api_handler.dart`
- Asegúrate de que el backend esté corriendo

---

## 🧪 **Test Manual Paso a Paso**

### **Test 1: Verificar Backend**

```bash
# En navegador o Postman:
GET http://localhost:TU_PUERTO/api/health

# Debe responder:
{
  "status": "healthy",
  "timestamp": "...",
  "service": "TobacoBackend"
}
```

### **Test 2: Verificar Endpoint de Ventas**

```bash
# En navegador o Postman:
GET http://localhost:TU_PUERTO/api/Ventas
Authorization: Bearer TU_TOKEN

# Debe responder con array de ventas
```

### **Test 3: Verificar App**

1. **Abre la consola de debug en tu IDE**
2. **Corre la app:** `flutter run`
3. **Ve a la pantalla de Ventas**
4. **Observa los logs**
5. **Copia TODOS los logs y me los pasas**

---

## 💡 **Comandos para Debug**

### **Ver logs completos:**

```bash
flutter run --verbose
```

### **Limpiar y reconstruir:**

```bash
flutter clean
flutter pub get
flutter run
```

---

## 🔧 **Fix Rápido: Forzar uso de ventas del backend**

Si quieres probar que el backend funciona, puedes hacer esto temporalmente:

En `ventas_screen.dart`, cambia temporalmente:

```dart
// Test temporal - ir directo al backend
final ventasProvider = VentasProvider();
final data = await ventasProvider.obtenerVentasPaginadas(1, 100);
setState(() {
  ventas = List<Ventas>.from(data['ventas']);
  isLoading = false;
});
```

Esto te dirá si:
- ✅ El backend funciona → Problema en sistema offline
- ❌ El backend falla → Problema en backend

---

## 📊 **Checklist de Verificación**

Verifica CADA punto:

- [ ] Backend está corriendo (`dotnet run`)
- [ ] Endpoint `/api/health` responde
- [ ] Endpoint `/api/Ventas` responde
- [ ] Estás logueado en la app
- [ ] El token no expiró
- [ ] Hay ventas en la base de datos del backend
- [ ] La URL del backend es correcta en `api_handler.dart`
- [ ] Los logs muestran qué está pasando

---

## 🚀 **Siguiente Paso**

**POR FAVOR:**

1. Corre la app
2. Ve a la pantalla de Ventas
3. **Copia TODOS los logs de consola** que aparecen
4. Pégalos aquí

Con esos logs podré ver exactamente qué está fallando.

---

## 💬 **Ejemplo de logs que necesito ver:**

```
🔄 VentasScreen: Iniciando carga de ventas...
🔄 VentasScreen: Inicializando provider...
🚀 VentasOfflineService: Inicializando...
... (todos los logs que aparezcan)
```

---

**¿Puedes correr la app y pasarme los logs?** 🔍

