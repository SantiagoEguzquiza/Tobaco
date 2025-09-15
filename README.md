# Tobaco

App móvil que transforma la gestión de ventas en empresas distribuidoras.
Con un diseño intuitivo, permite controlar inventario, crear facturas digitales al instante, registrar clientes desde el terreno y consultar cotizaciones de monedas en vivo. Todo pensado para que los vendedores trabajen más rápido, con menos errores y con información clave siempre al alcance.

## Tabla de Contenidos

- [Descripción](#descripción)
- [Características](#características)
- [Tecnologías Utilizadas](#tecnologías-utilizadas)
- [Instalación](#instalación)
- [Uso](#uso)
- [Futuras mejoras](#futuras-mejoras)
- [Contribución](#contribución)

---

## Descripción

Aplicación móvil multiplataforma desarrollada en Flutter, orientada a empresas proveedoras y distribuidoras de mercadería.
La app integra en un mismo entorno la gestión de inventario, el registro de clientes, la generación de facturas digitales y la consulta de cotizaciones de monedas extranjeras en tiempo real.
Además, está pensada para optimizar la labor diaria de los vendedores, permitiendo trabajar con o sin conexión a internet, planificar rutas de visitas mediante geolocalización y obtener reportes de ventas para una mejor toma de decisiones.

## Características

- **Gestión de inventario:** Controla el stock de productos disponibles y movimientos de inventario.
- **Facturación digital:** Genera y gestiona facturas electrónicas de manera rápida y sencilla.
- **Cotizaciones de monedas:** Consulta tasas de cambio de diferentes monedas en tiempo real.
- **Registro de clientes:** Almacena y administra datos de clientes fácilmente.
- **Optimización del proceso de ventas:** Acceso inmediato a información relevante para la toma de decisiones.
- **Interfaz intuitiva:** Fácil de usar para vendedores en movimiento.

## Tecnologías Utilizadas

- **Dart / Flutter:** Desarrollo móvil multiplataforma.
- **C++ / C / C#:** Lógica de integración nativa.
- **CMake:** Gestión de la build.
- **Swift:** Integración iOS (mínima).
- **Otros:** Utilidades adicionales.

## Instalación

1. Clona este repositorio:

   ```bash
   git clone https://github.com/SantiagoEguzquiza/Tobaco.git
   ```

2. Instala las dependencias necesarias según la plataforma (verifica que tienes instalado Flutter, CMake y compiladores de C/C++ según corresponda).

3. Configura el entorno para Android/iOS siguiendo la [documentación oficial de Flutter](https://docs.flutter.dev/get-started/install).

4. Compila e inicia la aplicación móvil:

   ```bash
   cd Tobaco
   flutter pub get
   flutter run
   ```

   > **Nota:** Puede requerirse configuración adicional para la compilación de módulos nativos (C/C++/C#).

## Uso

1. Inicia sesión con tus credenciales de vendedor.
2. Accede al panel principal para gestionar inventario, clientes y facturación.
3. Consulta cotizaciones de monedas extranjeras en la sección dedicada.
4. Genera facturas digitales y registra ventas directamente desde la app.

## Futuras mejoras

- **Integración de mapas con rutas de clientes:** Se planea incorporar una funcionalidad que permita visualizar en un mapa la ubicación de los clientes y trazar rutas óptimas para realizar visitas, optimizando así la planificación y el recorrido diario de los vendedores.

## Contribución

Si deseas contribuir a este proyecto, por favor comunícate conmigo antes de realizar cualquier cambio significativo. Estoy disponible para discutir ideas, sugerencias o posibles mejoras para asegurar que el desarrollo siga una dirección coherente.
