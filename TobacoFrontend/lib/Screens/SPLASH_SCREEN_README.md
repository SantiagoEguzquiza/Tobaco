# Splash Screen - Pantalla de Introducción

## Descripción
Sistema completo de splash screen (pantalla de introducción) con dos niveles:

### 1. Splash Nativo (Nivel Sistema Operativo)
Se muestra **inmediatamente** al abrir la app, antes de que Flutter inicie.

**Características:**
- ✅ Color de fondo verde (#4CAF50)
- ✅ Logo centrado de la app
- ✅ Soporte para modo oscuro (#1A1A1A)
- ✅ Compatible con Android 12+
- ✅ Configurado para Android e iOS

### 2. Splash Animado (Nivel Flutter)
Se muestra después del splash nativo, con animaciones profesionales.

**Características:**
- ✅ Animación de fade-in (entrada suave)
- ✅ Animación de scale (crecimiento del logo)
- ✅ Logo en círculo blanco con sombra
- ✅ Nombre "TOBACO" con estilo
- ✅ Subtítulo "Sistema de Gestión"
- ✅ Indicador de carga circular
- ✅ Duración: 2.5 segundos
- ✅ Transición suave a la siguiente pantalla

## Archivos Implementados

### Frontend
1. **`lib/Screens/splash_screen.dart`**
   - Widget de splash con animaciones
   - Manejo de transiciones
   - Temporización automática

2. **`lib/main.dart`** (modificado)
   - Configurado para mostrar splash al inicio
   - Usa AuthWrapper para decidir siguiente pantalla

3. **`pubspec.yaml`** (modificado)
   - Dependencia: `flutter_native_splash: ^2.3.10`
   - Configuración de colores y logo

### Recursos Generados Automáticamente
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-night/launch_background.xml`
- `android/app/src/main/res/values-v31/styles.xml`
- `android/app/src/main/res/values-night-v31/styles.xml`
- Múltiples archivos de imágenes en diferentes resoluciones
- Archivos iOS correspondientes

## Configuración del Splash Nativo

### Colores
```yaml
flutter_native_splash:
  color: "#4CAF50"          # Verde (modo claro)
  color_dark: "#1A1A1A"     # Gris oscuro (modo oscuro)
```

### Logo
- Ubicación: `Assets/images/Appicon/icon.png`
- Se escala automáticamente para diferentes pantallas
- Centrado en la pantalla

### Android 12+
- Soporte específico para Android 12 splash screens
- Maneja transición nativa del sistema

## Cómo Personalizar

### Cambiar Colores
Editar en `pubspec.yaml`:
```yaml
flutter_native_splash:
  color: "#TU_COLOR_HEXADECIMAL"
  color_dark: "#TU_COLOR_OSCURO"
```

Luego ejecutar:
```bash
dart run flutter_native_splash:create
```

### Cambiar Logo
1. Reemplaza `Assets/images/Appicon/icon.png` con tu nuevo logo
2. Ejecuta: `dart run flutter_native_splash:create`

### Cambiar Duración del Splash Animado
En `lib/Screens/splash_screen.dart`:
```dart
// Cambiar esta línea:
Timer(const Duration(milliseconds: 2500), () { ... });
```

### Cambiar Texto del Splash
En `lib/Screens/splash_screen.dart`, busca:
```dart
const Text(
  'TOBACO',  // ← Cambiar aquí
  ...
),
...
const Text(
  'Sistema de Gestión',  // ← Y aquí
  ...
),
```

### Modificar Animaciones
En `lib/Screens/splash_screen.dart`:
```dart
_controller = AnimationController(
  duration: const Duration(milliseconds: 1500), // ← Duración de animación
  vsync: this,
);

_fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeIn), // ← Curva
  ),
);
```

## Flujo de la Aplicación

```
1. Usuario toca el ícono de la app
   ↓
2. Splash Nativo (Sistema Operativo)
   - Fondo verde con logo
   - Instantáneo
   ↓
3. Flutter inicia
   ↓
4. Splash Animado (Flutter)
   - Animaciones de entrada
   - Duración: 2.5 segundos
   ↓
5. AuthWrapper
   - Verifica si hay sesión activa
   ↓
6a. Si tiene sesión → MenuScreen
6b. Si no tiene sesión → LoginScreen
```

## Comandos Útiles

### Regenerar Splash Nativo
```bash
cd TobacoFrontend
dart run flutter_native_splash:create
```

### Eliminar Splash Nativo (Volver a Default)
```bash
dart run flutter_native_splash:remove
```

### Hot Reload (No funciona con splash nativo)
Para ver cambios en el splash **nativo**, necesitas:
```bash
flutter run
```

Para ver cambios en el splash **animado de Flutter**, puedes usar hot reload normal.

## Notas Técnicas

### Rendimiento
- El splash nativo NO afecta el rendimiento
- El splash animado es muy ligero (solo animaciones básicas)
- Duración total: ~2.5-3 segundos

### Compatibilidad
- ✅ Android 5.0+ (API 21+)
- ✅ iOS 12+
- ✅ Soporte completo para modo oscuro
- ✅ Android 12+ splash screen API

### Recursos
- Logo: 512x512px recomendado
- Formato: PNG con transparencia
- Peso: < 100KB recomendado

## Resolución de Problemas

### El splash no se muestra
1. Verificar que el logo existe en: `Assets/images/Appicon/icon.png`
2. Ejecutar: `flutter clean`
3. Ejecutar: `dart run flutter_native_splash:create`
4. Ejecutar: `flutter run`

### El splash se ve pixelado
- Usar un logo de mayor resolución (mínimo 512x512px)
- Regenerar con: `dart run flutter_native_splash:create`

### El splash dura demasiado
- Modificar el Timer en `splash_screen.dart`
- Reducir la duración de las animaciones

### Quiero quitar el splash animado
En `main.dart`, cambiar:
```dart
home: SplashScreen(
  nextScreen: const AuthWrapper(),
),
```

Por:
```dart
home: const AuthWrapper(),
```

## Estado Actual

✅ **COMPLETAMENTE IMPLEMENTADO**
- Splash nativo generado
- Splash animado creado
- Integrado en main.dart
- Sin errores de compilación
- Listo para usar

---

**Última actualización**: 17 de Octubre, 2025

