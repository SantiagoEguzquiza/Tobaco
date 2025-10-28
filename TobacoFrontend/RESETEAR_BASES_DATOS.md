# 🔧 Resetear Bases de Datos SQLite

## 🎯 **Solución al Error: "no such table: ventas_offline"**

La base de datos no se creó correctamente. Necesitas resetearla.

---

## ✅ **Opción 1: Desinstalar y Reinstalar la App (RECOMENDADO)**

Esto elimina todas las bases de datos y las recrea:

### **Android:**
```bash
# Desinstalar completamente
flutter clean
adb uninstall com.example.tobaco

# Reinstalar
flutter run
```

### **iOS:**
```bash
# Desinstalar desde el simulador/dispositivo
# Luego:
flutter clean
flutter run
```

---

## ✅ **Opción 2: Eliminar Bases de Datos Manualmente**

### **Android (Emulador):**

```bash
# Conectar al emulador
adb shell

# Ir a la carpeta de datos de la app
cd /data/data/com.example.tobaco/databases/

# Listar bases de datos
ls

# Eliminar las bases de datos
rm tobaco_offline.db
rm tobaco_offline.db-shm
rm tobaco_offline.db-wal
rm tobaco_cache.db
rm tobaco_cache.db-shm
rm tobaco_cache.db-wal

# Salir
exit
```

Luego reinicia la app.

---

## ✅ **Opción 3: Forzar Recreación en el Código**

Voy a agregar un método para forzar la recreación de la base de datos.

---

## 🚀 **RECOMENDACIÓN: Desinstalar la App**

El método más simple y seguro:

```bash
# 1. Detén la app
flutter clean

# 2. Desinstala la app del dispositivo/emulador
adb uninstall com.example.tobaco

# 3. Reinstala
flutter run
```

Esto garantiza que las bases de datos se creen desde cero correctamente.

---

## 📋 **Después de Reinstalar**

Deberías ver estos logs al abrir la app:

```
📦 DatabaseHelper: Inicializando base de datos...
📦 DatabaseHelper: Creando tablas...
✅ DatabaseHelper: Tablas creadas correctamente
🗄️ CacheManager: Inicializando base de datos de caché...
🗄️ CacheManager: Creando tablas de caché...
✅ CacheManager: Tablas de caché creadas correctamente
```

---

## 🔍 **Verificar que Funcionó**

Después de reinstalar:

1. Abre la app
2. Ve a Ventas
3. Los logs deben mostrar:
   ```
   ✅ VentasService: X ventas recibidas del backend
   ```

---

**Por favor, desinstala la app y reinstálala. Eso debería arreglar el error de base de datos.** 🔧

