# Configuración del Keystore para Firma de Android

## 📍 Ubicación del archivo .jks

El archivo `.jks` (Java KeyStore) debe estar en:
```
android/app/upload-keystore.jks
```

**⚠️ IMPORTANTE:** Este archivo NO está en el repositorio Git (está en `.gitignore` por seguridad). Debes crearlo localmente o tenerlo guardado en un lugar seguro.

## 🔑 Crear el Keystore

### Opción 1: Usar el script (Recomendado)

**Windows:**
```bash
cd android
create_keystore.bat
```

**Linux/Mac:**
```bash
cd android
chmod +x create_keystore.sh
./create_keystore.sh
```

### Opción 2: Comando manual

```bash
cd android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Durante la creación, se te pedirá:
- **Contraseña del keystore** (storePassword)
- **Contraseña de la clave** (keyPassword) - puede ser la misma
- **Nombre y apellidos**
- **Unidad organizativa**
- **Organización**
- **Ciudad**
- **Estado/Provincia**
- **Código de país** (ej: AR, MX, US)

## ⚙️ Configurar key.properties

1. Copia el archivo de ejemplo:
   ```bash
   cd android
   copy key.properties.example key.properties
   ```
   (En Linux/Mac: `cp key.properties.example key.properties`)

2. Edita `key.properties` y completa con tus contraseñas:
   ```properties
   storePassword=TU_STORE_PASSWORD_AQUI
   keyPassword=TU_KEY_PASSWORD_AQUI
   keyAlias=upload
   storeFile=app/upload-keystore.jks
   ```

3. **⚠️ IMPORTANTE:** El archivo `key.properties` también está en `.gitignore` - NO lo subas al repositorio.

## 🔒 Seguridad

- **NUNCA** subas el archivo `.jks` al repositorio
- **NUNCA** subas el archivo `key.properties` al repositorio
- Guarda una copia de seguridad del `.jks` en un lugar seguro
- Guarda las contraseñas en un gestor de contraseñas seguro
- Si pierdes el keystore, NO podrás actualizar tu app en Google Play Store

## 📦 Construir APK/AAB firmado

Una vez configurado, puedes construir la app firmada:

```bash
# APK firmado
flutter build apk --release

# AAB firmado (para Google Play Store)
flutter build appbundle --release
```

## ❓ ¿Ya tienes un keystore?

Si ya tienes un archivo `.jks` de otro proyecto o ubicación:

1. Copia el archivo a `android/app/upload-keystore.jks`
2. Crea el archivo `key.properties` con las credenciales correctas
3. Asegúrate de que el `keyAlias` coincida con el alias usado al crear el keystore

## 🔍 Verificar información del keystore

Para ver la información de un keystore existente:

```bash
keytool -list -v -keystore android/app/upload-keystore.jks
```
