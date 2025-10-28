# Sistema de Registro de Asistencia

## Descripción
Este módulo implementa un sistema completo de registro de asistencia para empleados, permitiendo marcar entrada y salida del trabajo con registro de ubicación GPS y fecha/hora.

## Características

### 1. Registro de Entrada
- **Botón**: "Registrar Entrada"
- **Funcionalidad**: Marca la entrada del empleado al trabajo
- **Datos Capturados**:
  - Fecha y hora de entrada (automática)
  - Ubicación GPS (latitud, longitud)
  - Dirección aproximada (mediante geocodificación)
  - ID del usuario

### 2. Registro de Salida
- **Botón**: "Registrar Salida"
- **Funcionalidad**: Marca la salida del empleado del trabajo
- **Datos Capturados**:
  - Fecha y hora de salida (automática)
  - Ubicación GPS (latitud, longitud)
  - Dirección aproximada
  - Cálculo automático de horas trabajadas

### 3. Historial de Asistencias
- **Vista**: Lista de las últimas 10 asistencias del usuario
- **Información Mostrada**:
  - Fecha del registro
  - Hora de entrada
  - Hora de salida (si aplica)
  - Horas trabajadas (si la asistencia está completa)
  - Estado (activa/completada)

### 4. Estado en Tiempo Real
- Visualización del estado actual de asistencia
- Información de entrada activa con tiempo transcurrido
- Indicadores visuales con colores:
  - Verde: Entrada registrada
  - Azul: Sin registro activo
  - Rojo: Para registrar salida

## Permisos Necesarios

### Android
Agregar en `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS
Agregar en `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para registrar tu asistencia</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para registrar tu asistencia</string>
```

## Estructura de Archivos

### Frontend
- **Modelo**: `lib/Models/Asistencia.dart`
- **Servicio**: `lib/Services/Asistencia_Service/asistencia_service.dart`
- **Pantalla**: `lib/Screens/Config/config_screen.dart`

### Backend
- **Modelo**: `Domain/Models/Asistencia.cs`
- **DTO**: `DTOs/AsistenciaDTO.cs`
- **Repositorio**: `Repositories/AsistenciaRepository.cs`
- **Servicio**: `Services/AsistenciaService.cs`
- **Controlador**: `Controllers/AsistenciaController.cs`

## Endpoints de API

### Registrar Entrada
```
POST /api/Asistencia/registrar-entrada
Body: {
  "userId": 1,
  "ubicacionEntrada": "Calle 123, Ciudad",
  "latitudEntrada": "-34.603722",
  "longitudEntrada": "-58.381592"
}
```

### Registrar Salida
```
POST /api/Asistencia/registrar-salida
Body: {
  "asistenciaId": 1,
  "ubicacionSalida": "Calle 123, Ciudad",
  "latitudSalida": "-34.603722",
  "longitudSalida": "-58.381592"
}
```

### Obtener Asistencia Activa
```
GET /api/Asistencia/activa/{userId}
```

### Obtener Historial
```
GET /api/Asistencia/usuario/{userId}
```

### Obtener por Rango de Fechas
```
GET /api/Asistencia/usuario/{userId}/rango?fechaInicio=2024-01-01&fechaFin=2024-01-31
```

### Obtener Todas las Asistencias (Solo Admin)
```
GET /api/Asistencia/todas
```

## Validaciones

1. **Entrada Duplicada**: No se permite registrar entrada si ya existe una asistencia activa (sin salida)
2. **Salida sin Entrada**: No se puede registrar salida sin una entrada previa
3. **Autenticación**: Todos los endpoints requieren autenticación JWT
4. **Autorización**: Los endpoints administrativos solo son accesibles por usuarios con rol "Admin"

## Flujo de Uso

1. Usuario inicia sesión
2. Navega a "Configuración" desde el menú principal
3. Al llegar al trabajo, presiona "Registrar Entrada"
   - Se solicitan permisos de ubicación (si es necesario)
   - Se captura la ubicación GPS
   - Se registra en la base de datos
4. Durante el día, puede ver su entrada activa en la pantalla
5. Al finalizar, presiona "Registrar Salida"
   - Se captura la ubicación de salida
   - Se calcula el tiempo trabajado
   - Se completa el registro
6. El historial muestra todas las asistencias previas

## Características de Seguridad

- ✅ Autenticación JWT requerida
- ✅ Validación de permisos de ubicación
- ✅ Validación de datos en backend
- ✅ Registro de ubicación GPS para auditoría
- ✅ Prevención de registros duplicados
- ✅ Logs de todas las acciones

## Mejoras Futuras Sugeridas

1. Exportación de reportes de asistencia a PDF/Excel
2. Notificaciones push para recordar registro de entrada/salida
3. Geofencing para validar que el usuario esté en la ubicación correcta
4. Dashboard para administradores con estadísticas
5. Reportes de horas trabajadas por período
6. Integración con sistema de nómina
7. Fotografía al momento del registro
8. Detección de anomalías (horarios inusuales, ubicaciones inesperadas)

## Notas Importantes

- Los registros son inmutables (no se pueden editar después de crearse)
- La ubicación es opcional pero altamente recomendada para auditoría
- Si falla la obtención de ubicación, el registro se hace de todas formas con ubicación nula
- El cálculo de horas trabajadas se hace automáticamente en el backend
- Los administradores pueden ver todas las asistencias de todos los usuarios

