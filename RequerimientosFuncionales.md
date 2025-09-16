# Requerimientos Funcionales – App de Gestión de Ventas

## Convenciones de Prioridad
- **MVP**: imprescindible para la primera versión en producción.  
- **F2**: segunda fase, mejora operativa y control.  
- **F3**: evolución/escala y analítica avanzada.  

---

## A. Autenticación y Roles
- **RF01 (MVP)** – Inicio de sesión con usuario/contraseña contra la API .NET; mantener sesión con token seguro y expiración.  
- **RF02 (MVP)** – Gestión de roles: *Administrador*, *Vendedor/Preventista*, *Supervisor*.  
- **RF03 (F2)** – Recuperación de contraseña (enlace/código) y cambio de contraseña autenticado.  
- **RF04 (F2)** – Cierre de sesión manual y cierre automático por inactividad.  

## B. Clientes
- **RF05 (MVP)** – ABM de clientes: crear, editar, eliminar (lógico), listar y buscar por nombre, documento, código y localidad.  
- **RF06 (MVP)** – Detalle de cliente: datos fiscales, contacto, dirección, geolocalización, condiciones comerciales.  
- **RF07 (MVP)** – Historial comercial del cliente: compras, saldos, últimos precios y productos frecuentes.  
- **RF08 (F2)** – Validaciones: documentos únicos, campos obligatorios, formato de email/teléfono.  
- **RF09 (F2)** – Importación masiva de clientes desde planilla (CSV/XLSX).  

## C. Productos e Inventario
- **RF10 (MVP)** – ABM de productos con códigos, nombre, descripción, categoría, precio base, impuestos, estado.  
- **RF11 (MVP)** – Stock por depósito/sucursal y reserva al confirmar venta.  
- **RF12 (MVP)** – Búsqueda y filtros por texto, categoría y estado; orden por precio/rotación.  
- **RF13 (F2)** – Imágenes de producto y código de barras (escaneo cámara).  
- **RF14 (F2)** – Listas de precios por cliente/segmento; reglas de redondeo.  
- **RF15 (F3)** – Alertas de stock bajo configurables por producto.  

## D. Cotizaciones de Monedas (BROU)
- **RF16 (MVP)** – Consulta de cotizaciones USD/UYU vía servicio BROU.  
- **RF17 (MVP)** – Cacheo local (SQLite) y uso offline de la última cotización válida con fecha/hora.  
- **RF18 (F2)** – Forzar actualización manual y política de expiración configurable.  

## E. Ventas / Pedidos / Facturación
- **RF19 (MVP)** – Flujo “Nueva Venta/Pedido”: seleccionar cliente, ver resumen, agregar ítems, totales e impuestos.  
- **RF20 (MVP)** – Validaciones: stock, tope de crédito, lista de precios.  
- **RF21 (MVP)** – Guardado borrador y edición antes de confirmar.  
- **RF22 (MVP)** – Confirmación de venta: genera documento con numeración del backend.  
- **RF23 (MVP)** – PDF del comprobante y compartir por WhatsApp/Email.  
- **RF24 (F2)** – Devoluciones/Notas de crédito con impacto en stock y saldos.  
- **RF25 (F2)** – Promociones: 2x1, descuentos por volumen, reglas por cliente.  
- **RF26 (F3)** – Ventas en múltiples monedas con cálculo automático.  

## F. Cobranzas
- **RF27 (F2)** – Registro de cobros: efectivo, transferencia, POS.  
- **RF28 (F2)** – Estado de cuenta por cliente: saldos, vencidos, próximos a vencer.  
- **RF29 (F3)** – Recibos en PDF y envío por WhatsApp/Email.  

## G. Ruteo, Visitas y Geolocalización
- **RF30 (F2)** – Mapa con clientes geolocalizados y plan de visita.  
- **RF31 (F2)** – Generar ruta óptima por cercanía.  
- **RF32 (F2)** – Marcar cliente como “visitado” manualmente.  
- **RF33 (F2)** – Auto-marcado por geofence (radio configurable).  
- **RF34 (F2)** – Reordenamiento dinámico de la ruta según visitas completadas.  
- **RF35 (F3)** – Planificación semanal de visitas con metas de cobertura.  

## H. Modo Offline y Sincronización
- **RF36 (MVP)** – Caché local (SQLite) de clientes, productos, precios y cotización.  
- **RF37 (MVP)** – Cola de operaciones para sincronizar al recuperar conexión.  
- **RF38 (MVP)** – Resolución básica de conflictos (“última edición del servidor gana”).  
- **RF39 (F2)** – Sincronización selectiva por zona/segmento.  
- **RF40 (F3)** – Merge asistido de conflictos en panel admin.  

## I. Notificaciones y Recordatorios
- **RF41 (F2)** – Notificaciones: stock bajo, deuda vencida, visita programada.  
- **RF42 (F3)** – Recordatorios por objetivos: ventas diarias, clientes inactivos.  

## J. Reportes y Analítica
- **RF43 (F2)** – Reportes: ventas por período, cliente, categoría, top productos.  
- **RF44 (F2)** – Exportación CSV/XLSX desde el backend.  
- **RF45 (F3)** – Panel de métricas: ticket promedio, margen estimado.  

## K. Configuración y Preferencias
- **RF46 (MVP)** – Preferencias: moneda por defecto, formato de precios, tema.  
- **RF47 (F2)** – Parámetros comerciales: impuestos, radios de geofence.  
- **RF48 (F2)** – Multi-empresa / Multi-depósito.  

## L. Seguridad y Auditoría
- **RF49 (MVP)** – Autorizaciones por rol para acciones sensibles.  
- **RF50 (F2)** – Auditoría de acciones clave.  
- **RF51 (F2)** – Bloqueo de edición de documentos confirmados y circuito de aprobaciones.  

## M. Integraciones y Backend
- **RF52 (MVP)** – API REST .NET con endpoints para auth, clientes, productos, ventas, cotizaciones y sincronización.  
- **RF53 (MVP)** – SQL Server como fuente de verdad y SQLite en dispositivo.  
- **RF54 (F2)** – Web Admin para ABM masivo, reportes y configuración avanzada.  
- **RF55 (F3)** – Integración contable con sistemas externos.  

## N. UX móvil y Performance
- **RF56 (MVP)** – Listas grandes virtualizadas y búsqueda incremental.  
- **RF57 (MVP)** – Pantalla “Nueva Venta”: buscador de cliente, resumen, botón “Agregar producto”, lista editable y botón Confirmar.  
- **RF58 (MVP)** – Orden en rankings/listados y posiciones claras.  
- **RF59 (F2)** – Accesibilidad básica: tamaños de fuente, contraste.  
- **RF60 (F3)** – Soporte multilenguaje (es/en).  
