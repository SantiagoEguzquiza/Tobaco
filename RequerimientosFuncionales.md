# Requerimientos Funcionales – App de Gestión de Ventas Provider

## Convenciones de Prioridad
- **MVP**: imprescindible para la primera versión en producción.  
- **F2**: segunda fase, mejora operativa y control.  
- **F3**: evolución del producto y funcionalidades analíticas o de expansión.  

---

## Descripción General del Sistema
Provider es una plataforma orientada a distribuidoras de mercadería, diseñada para digitalizar y optimizar los procesos comerciales y operativos que ocurren entre el depósito de la empresa y los comercios clientes.  

La aplicación permite registrar ventas, gestionar clientes y productos, controlar inventario y facilitar la distribución de mercadería, utilizando dispositivos móviles para operar directamente en campo.  

El sistema está diseñado para complementar sistemas administrativos o contables existentes, brindando herramientas que optimizan el trabajo operativo de los distintos roles dentro de una distribuidora.  

Provider contempla distintos roles operativos dentro de una empresa distribuidora, permitiendo que cada usuario acceda únicamente a las funcionalidades correspondientes a su puesto de trabajo.  

**Roles contemplados:**
- Administrador   
- Vendedor
- Repartidor  
- Personal de Depósito  

**Arquitectura del sistema:**
- Aplicación móvil desarrollada en Flutter  
- API backend desarrollada en .NET  
- Base de datos centralizada  
- Base de datos local SQLite para operación offline  
- Arquitectura multi-tenant que permite soportar múltiples empresas utilizando la misma infraestructura  

---

## A. Autenticación y Roles
- **RF01 (MVP)** – Inicio de sesión mediante usuario y contraseña contra la API backend.  
- **RF02 (MVP)** – Gestión de usuarios dentro del sistema.  
  - Cada usuario debe estar asociado a uno de los roles operativos.  
- **RF03 (MVP)** – Recuperación de contraseña mediante flujo seguro de validación.  
- **RF04 (MVP)** – Cierre manual de sesión desde la aplicación.  
- **RF05 (F2)** – Cierre automático de sesión por inactividad prolongada.  

---

## B. Clientes
- **RF06 (MVP)** – Gestión completa de clientes (crear, editar, eliminar lógicamente, listar y buscar).  
  - Filtros: nombre, documento, código de cliente, localidad.  
- **RF07 (MVP)** – Visualización del detalle del cliente (datos fiscales, contacto, dirección, geolocalización, condiciones comerciales).  
- **RF08 (MVP)** – Historial comercial del cliente (ventas anteriores, últimos productos comprados, últimos precios aplicados, saldo pendiente).  
- **RF09 (MVP)** – Validaciones automáticas (documento único, campos obligatorios, formatos de datos).  
- **RF10 (F2)** – Importación masiva de clientes mediante CSV/XLSX.  

---

## C. Productos e Inventario
- **RF11 (MVP)** – Gestión de productos (código, nombre, descripción, categoría, precio base, estado).  
- **RF12 (MVP)** – Gestión de stock por depósito o sucursal.  
- **RF13 (MVP)** – Búsqueda y filtrado de productos (texto, categoría, estado).  
- **RF14 (F2)** – Asociación de imágenes a productos.  
- **RF15 (F2)** – Lectura de códigos de barras con cámara.  
- **RF16 (MVP)** – Alertas de stock bajo por producto.  
- **RF17 (F2)** – Ajuste manual de stock con registro de usuario, producto, cantidad y motivo.  

---

## D. Cotizaciones de Monedas
- **RF18 (MVP)** – Consulta automática de cotizaciones (USD/UYU) mediante servicio externo.  
- **RF19 (MVP)** – Almacenamiento local de última cotización válida para operación offline.  
- **RF20 (MVP)** – Actualización manual de cotizaciones.  

---

## E. Ventas / Pedidos
- **RF21 (MVP)** – Flujo de creación de venta/pedido (cliente, resumen, productos, totales).  
- **RF22 (MVP)** – Validaciones automáticas (stock, condiciones comerciales).  
- **RF23 (MVP)** – Guardado en estado borrador.  
- **RF24 (MVP)** – Confirmación de venta con documento backend (numeración independiente por tenant).  
- **RF25 (MVP)** – Comprobantes PDF.  
- **RF26 (MVP)** – Compartir comprobantes por apps externas.  
- **RF27 (MVP)** – Promociones y descuentos.  
- **RF28 (F2)** – Registro de devoluciones/notas de crédito.  
- **RF29 (F2)** – Ventas en múltiples monedas.  

---

## F. Cobranzas
- **RF30 (F2)** – Registro de cobros (efectivo, transferencia, POS).  
- **RF31 (F2)** – Consulta de estado de cuenta.  
- **RF32 (F2)** – Recibos de pago en PDF.  

---

## G. Ruteo, Visitas y Geolocalización
- **RF33 (F2)** – Visualización de clientes en mapa.  
- **RF34 (F2)** – Generación automática de rutas optimizadas.  
- **RF35 (F2)** – Registro manual de visitas.  
- **RF36 (F2)** – Marcado automático de visitas por geolocalización.  
- **RF37 (F3)** – Planificación de recorridos semanales.  

---

## H. Modo Offline y Sincronización
- **RF38 (F2)** – Almacenamiento local de clientes, productos, precios y cotizaciones.  
- **RF39 (F2)** – Cola de operaciones para sincronización automática.  
- **RF40 (F2)** – Resolución básica de conflictos de sincronización.  

---

## I. Notificaciones y Recordatorios
- **RF41 (MVP)** – Notificación automática de stock bajo.  
- **RF42 (F2)** – Notificaciones de deuda vencida y visitas programadas.  
- **RF43 (F3)** – Recordatorios de objetivos comerciales.  

---

## J. Reportes y Analítica
- **RF44 (F2)** – Reportes de ventas por período, cliente, categoría, producto.  
- **RF45 (F2)** – Exportación de reportes en CSV/XLSX.  
- **RF46 (F3)** – Panel de métricas comerciales.  

---

## K. Configuración y Preferencias
- **RF47 (F2)** – Configuración de moneda por defecto.  
- **RF48 (F2)** – Configuración de formato de precios.  
- **RF49 (MVP)** – Selección de tema visual (claro/oscuro).  
- **RF50 (F2)** – Soporte multi-empresa y multi-depósito.  

---

## L. Seguridad y Control de Accesos
- **RF51 (MVP)** – Control de permisos basado en roles.  

---

## M. Integraciones y Backend
- **RF52 (MVP)** – API REST en .NET para autenticación, clientes, productos, ventas, cotizaciones.  
- **RF53 (MVP)** – Base de datos central como fuente de verdad.  
- **RF54 (F2)** – Panel web administrativo.  
- **RF55 (F3)** – Integración con sistemas contables externos.  

---

## N. UX móvil y Performance
- **RF56 (MVP)** – Soporte para listas grandes con virtualización.  
- **RF57 (MVP)** – Pantalla optimizada de Nueva Venta.  
- **RF58 (MVP)** – Ordenamiento claro de listas y rankings.  
- **RF59 (F2)** – Ajustes básicos de accesibilidad.  
- **RF60 (F3)** – Soporte multilenguaje.  

---

## O. Entregas de Mercadería
- **RF61 (F2)** – Visualización de pedidos pendientes.  
- **RF62 (F2)** – Confirmación de entrega por repartidor.  
- **RF63 (F2)** – Registro de fecha y hora de entrega.  
- **RF64 (F2)** – Registro opcional de observaciones.  
- **RF65 (F2)** – Confirmación de entrega mediante firma o validación del cliente.  
