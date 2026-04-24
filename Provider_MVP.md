# Documento – Producto Mínimo Viable (MVP) Plataforma Provider

## 1. Introducción

El presente documento describe el Producto Mínimo Viable (MVP) de la plataforma Provider, un sistema diseñado para digitalizar y optimizar las operaciones comerciales de empresas distribuidoras de mercadería.

El objetivo principal del MVP es validar el funcionamiento del sistema en un entorno real de operación, permitiendo que empresas distribuidoras puedan gestionar sus procesos básicos de ventas e inventario mediante una aplicación móvil.

Provider busca ofrecer una solución que permita:
- Registrar ventas desde el terreno.
- Consultar información comercial en tiempo real.
- Mantener actualizado el inventario de productos.
- Reducir errores operativos.
- Facilitar la comunicación entre vendedores y administración.

## 2. Objetivos del MVP

El desarrollo del MVP tiene como propósito validar el producto en un entorno de operación real y obtener retroalimentación directa de las empresas.

- **Digitalizar la operación de ventas en campo:** Permitir el registro directo desde dispositivos móviles para evitar registros manuales.
- **Centralizar la información comercial:** Proveer una base de datos unificada para clientes, productos y ventas.
- **Mantener el inventario actualizado:** Reflejar automáticamente el impacto de compras y ventas en el stock disponible.
- **Mejorar la eficiencia operativa:** Reducir tiempos de registro y facilitar el acceso a información clave.
- **Validar el producto en el mercado:** Evaluar la utilidad del sistema en distribuidoras reales para definir la evolución del producto.

## 3. Alcance del MVP

El MVP contempla únicamente las funcionalidades necesarias para cubrir el flujo operativo básico:
- Gestión de usuarios del sistema.
- Gestión de clientes y productos.
- Registro de compras de mercadería.
- Registro de ventas e inventario.

Se prioriza la estabilidad operativa y la simplicidad, dejando fuera funcionalidades avanzadas como reportes analíticos complejos o integraciones contables externas.

## 4. Flujo operativo del sistema

El flujo operativo se basa en un modelo lineal que garantiza la integridad del inventario:

**Proveedor → Compra → Inventario → Venta → Cliente**

El sistema registra las compras que incrementan el stock y, posteriormente, las ventas registradas por los vendedores reducen automáticamente dicha disponibilidad.

## 5. Roles incluidos en el MVP

### Administrador
Responsable de la configuración y mantenimiento:
- Gestión de usuarios, productos y clientes.
- Registro de compras de mercadería.
- Supervisión del inventario.

### Vendedor
Principal usuario operativo de la aplicación móvil:
- Consulta de información de clientes y catálogo de productos.
- Registro de ventas y generación de comprobantes.
- Compartición de comprobantes con los clientes.

## 6. Gestión de Clientes

Funcionalidades incluidas:
- Registro y modificación de clientes.
- Consulta de historial comercial y búsqueda rápida.
- Almacenamiento de datos de contacto, dirección y nombre del comercio.

## 7. Gestión de Productos

Cada producto en el sistema incluye:
- Nombre y descripción.
- Precio de venta.
- Stock disponible actualizado en tiempo real.

## 8. Gestión de Compras

Fundamental para el reabastecimiento del inventario. El registro incluye:
- Selección de productos y cantidades adquiridas.
- Registro del precio de compra.
- Cálculo automático del total y actualización inmediata del stock.

## 9. Gestión de Ventas

El núcleo funcional del sistema sigue estos pasos:
1. Selección del cliente.
2. Selección de productos y cantidades.
3. Cálculo automático del total.
4. Validación de stock disponible.
5. Confirmación y reducción automática de inventario.

## 10. Comprobantes de venta

Generación de comprobantes digitales en formato **PDF** que incluyen detalles del cliente, productos, cantidades, precios y total. Pueden compartirse mediante aplicaciones externas como WhatsApp o correo electrónico.

## 11. Cotizaciones de moneda

Consulta de cotizaciones de monedas extranjeras mediante un servicio externo. El sistema almacena localmente la última cotización consultada para asegurar su disponibilidad en situaciones de baja conectividad.

## 12. Arquitectura Multi-tenant

Provider utiliza un modelo multi-tenant para permitir que múltiples empresas compartan la infraestructura manteniendo el aislamiento total de sus datos mediante un **TenantId**. Esto asegura escalabilidad y optimización de costos.

## 13. Arquitectura tecnológica

- **Aplicación móvil:** Desarrollada en Flutter para interacción en terreno.
- **Backend:** API REST desarrollada en .NET para lógica de negocio.
- **Base de datos central:** Motor relacional como fuente de verdad.
- **Base de datos local:** SQLite para soporte de operación offline.

## 14. Exclusiones del MVP

Las siguientes funcionalidades no forman parte de esta etapa inicial:
- Registro de cobranzas.
- Reportes analíticos avanzados.
- Planificación y optimización de rutas de visitas.
- Gestión logística de entregas.
- Panel administrativo web.
- Integración con sistemas contables externos.

## 15. Criterios de éxito del MVP

El éxito de esta fase se determinará si:
- El sistema es operativo en una distribuidora real.
- Las compras y ventas se registran sin errores de integridad.
- El inventario se mantiene sincronizado correctamente.
- Se evidencia una mejora en la velocidad de toma de pedidos y reducción de errores manuales.
