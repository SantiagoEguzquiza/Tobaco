import 'package:flutter/material.dart';
import '../../Models/Cliente.dart';
import '../../Models/Producto.dart';
import '../../Models/PrecioEspecial.dart';
import '../../Services/PrecioEspecialService.dart';
import '../../Services/Productos_Service/productos_provider.dart';
import '../../Theme/app_theme.dart';
import '../../Theme/dialogs.dart';
import '../../Helpers/api_handler.dart';
import 'editarPreciosEspeciales_screen.dart';

class PreciosEspecialesScreen extends StatefulWidget {
  final Cliente cliente;

  const PreciosEspecialesScreen({super.key, required this.cliente});

  @override
  State<PreciosEspecialesScreen> createState() => _PreciosEspecialesScreenState();
}

class _PreciosEspecialesScreenState extends State<PreciosEspecialesScreen> {
  List<PrecioEspecial> preciosEspeciales = [];
  List<Producto> productos = [];
  bool isLoading = true;
  String errorMessage = '';
  final ProductoProvider productoProvider = ProductoProvider();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final precios = await PrecioEspecialService.getPreciosEspecialesByCliente(widget.cliente.id!);
      final productosData = await productoProvider.obtenerProductos();
      
      if (!mounted) return;
      
      setState(() {
        preciosEspeciales = precios;
        productos = productosData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isLoading = false;
      });
      
      // Verificar si es un error de conexión con el servidor
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else if (e.toString().contains('401')) {
        // Si es un error 401, el usuario necesita autenticarse
        _showAuthErrorDialog();
      } else {
        // Mostrar otros errores
        await AppDialogs.showErrorDialog(
          context: context,
          message: 'Error al cargar los datos: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  void _showAuthErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sesión Expirada'),
          content: const Text('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver a la pantalla anterior
                // Aquí podrías navegar al login si tienes una ruta configurada
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _agregarPrecioEspecial() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPreciosEspecialesScreen(cliente: widget.cliente),
      ),
    );
    _loadData(); // Recargar datos al volver
  }

  Future<void> _editarPrecioEspecial(PrecioEspecial precioEspecial) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPreciosEspecialesScreen(
          cliente: widget.cliente,
          isIndividualEdit: true,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _eliminarPrecioEspecial(PrecioEspecial precioEspecial) async {
    final confirmed = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Precio Especial',
      message: '¿Estás seguro de que quieres eliminar el precio especial para ${precioEspecial.productoNombre}?',
    );

    if (confirmed == true) {
      try {
        await PrecioEspecialService.deletePrecioEspecial(precioEspecial.id!);
        
        if (mounted) {
          AppTheme.showSnackBar(
            context,
            AppTheme.successSnackBar('Precio especial eliminado exitosamente'),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted && Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
        } else if (mounted) {
          await AppDialogs.showErrorDialog(
            context: context,
            message: 'Error al eliminar el precio especial: ${e.toString().replaceFirst('Exception: ', '')}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null, // Usar el tema
        title: const Text(
          'Precios Especiales',
          style: AppTheme.appBarTitleStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Información del cliente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.cliente.nombre,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : preciosEspeciales.isEmpty
                        ? _buildEmptyState()
                        : _buildPreciosList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade800 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade300 
                    : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.price_change_outlined,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay precios especiales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Este cliente no tiene precios especiales configurados',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Usa el botón de gestión desde el detalle del cliente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreciosList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: preciosEspeciales.length,
      itemBuilder: (context, index) {
        final precioEspecial = preciosEspeciales[index];
        return _buildPrecioCard(precioEspecial, index);
      },
    );
  }

  Widget _buildPrecioCard(PrecioEspecial precioEspecial, int index) {
    final tieneDescuento = precioEspecial.precioEstandar != null && 
                          precioEspecial.precio < precioEspecial.precioEstandar!;
    final porcentajeDescuento = precioEspecial.precioEstandar != null 
        ? ((precioEspecial.precioEstandar! - precioEspecial.precio) / precioEspecial.precioEstandar! * 100)
        : 0.0;
    final indicatorColor = tieneDescuento ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicador lateral
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      precioEspecial.productoNombre ?? 'Producto desconocido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Precio: \$${precioEspecial.precio.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (precioEspecial.precioEstandar != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '\$${precioEspecial.precioEstandar!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (tieneDescuento && precioEspecial.precioEstandar != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              'Descuento: ${porcentajeDescuento.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Botones de acción
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      onPressed: () => _editarPrecioEspecial(precioEspecial),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _eliminarPrecioEspecial(precioEspecial),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}