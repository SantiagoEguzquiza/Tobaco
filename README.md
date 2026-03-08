# Provider

Provider es una plataforma móvil diseñada para digitalizar la operación de empresas distribuidoras, permitiendo gestionar clientes, productos, ventas y entregas directamente desde el terreno.

La aplicación está pensada para optimizar el trabajo de vendedores, repartidores y personal de depósito, centralizando la información comercial y operativa en un único sistema conectado a un backend seguro.

Provider busca convertirse en una herramienta de campo que complemente sistemas administrativos o contables existentes, enfocándose en la velocidad, confiabilidad y simplicidad necesarias para la operación diaria de distribuidoras.

## Tabla de Contenidos

- [Descripción](#descripción)
- [Arquitectura del Sistema](#arquitectura-del-sistema)
- [Características Principales](#características-principales)
- [Roles Operativos](#roles-operativos)
- [Tecnologías Utilizadas](#tecnologías-utilizadas)
- [Roadmap](#roadmap)
- [Contribución](#contribución)

## Descripción

Provider es una aplicación móvil desarrollada en Flutter orientada a empresas proveedoras y distribuidoras de mercadería.

El sistema permite gestionar la operación comercial y logística desde dispositivos móviles, facilitando tareas como:

- Registro de clientes
- Generación de ventas
- Control de productos
- Consulta de historial comercial
- Generación de comprobantes
- Control básico de inventario

La plataforma está diseñada para funcionar en entornos de conectividad variable, permitiendo continuar operando en campo y sincronizar la información cuando se restablece la conexión.

Provider utiliza una arquitectura multi-tenant, lo que permite que múltiples empresas utilicen la misma infraestructura manteniendo el aislamiento completo de sus datos.

## Arquitectura del Sistema

La plataforma está compuesta por los siguientes componentes principales:

### Aplicación móvil
Aplicación desarrollada en Flutter, utilizada por vendedores, repartidores y otros roles operativos para interactuar con el sistema desde dispositivos móviles.

### API Backend
API REST desarrollada en .NET, encargada de:
- Autenticación
- Gestión de clientes
- Gestión de productos
- Registro de ventas
- Sincronización de datos

### Base de datos central
Base de datos relacional utilizada como fuente de verdad del sistema, almacenando la información de todas las empresas registradas en la plataforma.

### Base de datos local
La aplicación utiliza SQLite en el dispositivo móvil para permitir operación offline y sincronización posterior con el backend.

### Arquitectura Multi-Tenant
Provider implementa un modelo multi-tenant, donde múltiples empresas utilizan la misma infraestructura manteniendo separación lógica de datos mediante identificadores de tenant. Esto permite escalar el sistema sin necesidad de desplegar instancias separadas para cada cliente.

## Características Principales

### Gestión de Clientes
- Registro y edición de clientes
- Consulta de historial comercial
- Información de contacto y dirección
- Búsqueda rápida de clientes

### Gestión de Productos
- Registro de productos
- Consulta de precios
- Control básico de inventario
- Alertas de stock bajo

### Gestión de Ventas
- Creación de ventas desde dispositivos móviles
- Selección rápida de productos
- Cálculo automático de totales
- Registro de ventas en campo

### Comprobantes Digitales
- Generación de comprobantes en PDF
- Compartición mediante aplicaciones externas (WhatsApp, correo electrónico)

### Consulta de Cotizaciones
- Consulta de cotizaciones de monedas
- Almacenamiento local para uso offline

### Operación Offline
La aplicación permite continuar operando incluso cuando no existe conexión a internet. Las operaciones se almacenan localmente y se sincronizan automáticamente con el servidor cuando la conexión vuelve a estar disponible.

## Roles Operativos

Provider está diseñado para contemplar distintos puestos de trabajo dentro de una distribuidora.

| Rol | Descripción de funciones |
| :--- | :--- |
| **Administrador** | Configuración de la empresa, gestión de usuarios, administración de productos y clientes. |
| **Vendedor / Preventista** | Registro de ventas, consulta de historial del cliente, aplicación de promociones y generación de comprobantes. |
| **Repartidor** | Consulta de pedidos pendientes, registro de entregas realizadas y confirmación de recepción. |
| **Personal de Depósito** | Gestión de stock, ajustes de inventario y preparación de pedidos para reparto. |
| **Supervisor** | Supervisión de la operación comercial y revisión de información de ventas. |

## Tecnologías Utilizadas

### Frontend
- Flutter
- Dart

### Backend
- .NET
- ASP.NET Web API

### Base de Datos
- SQL Server / PostgreSQL
- SQLite (modo offline en dispositivo)

### Infraestructura
- Backend desplegado en servicios cloud
- Arquitectura multi-tenant


## Roadmap

El desarrollo de Provider contempla futuras funcionalidades orientadas a mejorar la operación logística de distribuidoras. Entre las mejoras planificadas se encuentran:

- Planificación de rutas de visitas
- Visualización de clientes en mapas
- Optimización automática de recorridos
- Gestión de entregas
- Integración con sistemas contables externos
- Reportes comerciales avanzados
- Panel administrativo web

## Contribución

Este proyecto se encuentra en desarrollo activo.

Si deseas contribuir o discutir ideas relacionadas con el sistema, puedes comunicarte directamente con el autor del proyecto. Las sugerencias y mejoras son bienvenidas, siempre buscando mantener una dirección coherente en la evolución de la plataforma.
