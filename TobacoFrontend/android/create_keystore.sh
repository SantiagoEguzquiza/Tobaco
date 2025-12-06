#!/bin/bash

echo "========================================"
echo "Creando Keystore para firma de Android"
echo "========================================"
echo ""
echo "Este script creara un archivo upload-keystore.jks en la carpeta android/app"
echo ""
echo "IMPORTANTE: Guarda las contraseñas y el alias en un lugar seguro!"
echo ""

cd "$(dirname "$0")/app"

keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

echo ""
echo "========================================"
echo "Keystore creado exitosamente!"
echo "Ubicacion: android/app/upload-keystore.jks"
echo "========================================"
