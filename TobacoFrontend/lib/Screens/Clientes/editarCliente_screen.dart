import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../Models/Cliente.dart';
import '../../Services/Clientes_Service/clientes_provider.dart';
import '../../Theme/app_theme.dart';
import '../../Helpers/api_handler.dart';
import 'editarPreciosEspeciales_screen.dart';
import 'map_picker_screen.dart';

class EditarClienteScreen extends StatefulWidget {
  final Cliente cliente;

  const EditarClienteScreen({
    super.key,
    required this.cliente,
  });

  @override
  State<EditarClienteScreen> createState() => _EditarClienteScreenState();
}

class _EditarClienteScreenState extends State<EditarClienteScreen> {
  // Datos del cliente
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _descuentoGlobalController = TextEditingController();
  double? _latitud;
  double? _longitud;
  bool _hasCCTE = false;
  
  bool _isLoading = false;
  
  final ClienteProvider _clienteProvider = ClienteProvider();

  @override
  void initState() {
    super.initState();
    _cargarDatosCliente();
  }

  void _cargarDatosCliente() {
    _nombreController.text = widget.cliente.nombre;
    _telefonoController.text = widget.cliente.telefono?.toString() ?? '';
    _direccionController.text = widget.cliente.direccion ?? '';
    _descuentoGlobalController.text = widget.cliente.descuentoGlobal == 0.0 
        ? '' 
        : widget.cliente.descuentoGlobal.toString();
    _latitud = widget.cliente.latitud;
    _longitud = widget.cliente.longitud;
    _hasCCTE = widget.cliente.hasCCTE;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _descuentoGlobalController.dispose();
    super.dispose();
  }

  Future<void> _actualizarCliente() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Por favor, completa todos los campos obligatorios marcados con *'),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final clienteActualizado = Cliente(
        id: widget.cliente.id,
        nombre: _nombreController.text.trim(),
        telefono: int.tryParse(_telefonoController.text.trim()),
        direccion: _direccionController.text.trim(),
        deuda: widget.cliente.deuda ?? '0',
        descuentoGlobal: _descuentoGlobalController.text.trim().isEmpty 
            ? 0.0 
            : double.tryParse(_descuentoGlobalController.text.trim()) ?? 0.0,
        preciosEspeciales: widget.cliente.preciosEspeciales,
        latitud: _latitud,
        longitud: _longitud,
        visible: widget.cliente.visible,
        hasCCTE: _hasCCTE,
      );

      await _clienteProvider.editarCliente(clienteActualizado);
      
      setState(() {
        _isLoading = false;
      });
      
      // Retornar con el cliente actualizado
      // El snackbar se mostrará en la pantalla de clientes después de cerrar
      if (mounted) {
        Navigator.pop(context, clienteActualizado);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted && Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else if (mounted) {
        // Extraer el mensaje de error del backend si está disponible
        String errorMessage = 'Error al actualizar el cliente';
        final errorString = e.toString();
        
        // Intentar extraer el mensaje del backend
        if (errorString.contains('Exception: ')) {
          final parts = errorString.split('Exception: ');
          if (parts.length > 1) {
            errorMessage = parts[1].trim();
          }
        } else if (errorString.contains('404')) {
          errorMessage = 'Cliente no encontrado. Por favor, recarga la lista de clientes.';
        } else {
          errorMessage = errorString.replaceAll('Exception: ', '');
        }
        
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar(errorMessage),
        );
      }
    }
  }

  Future<void> _editarPreciosEspeciales() async {
    // Primero guardar el cliente si hay cambios sin guardar
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Por favor, completa todos los campos obligatorios antes de editar precios especiales'),
        );
      }
      return;
    }

    // Si hay cambios, guardar primero
    if (_hayCambiosSinGuardar()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final clienteActualizado = Cliente(
          id: widget.cliente.id,
          nombre: _nombreController.text.trim(),
          telefono: int.tryParse(_telefonoController.text.trim()),
          direccion: _direccionController.text.trim(),
          deuda: widget.cliente.deuda ?? '0',
          descuentoGlobal: _descuentoGlobalController.text.trim().isEmpty 
              ? 0.0 
              : double.tryParse(_descuentoGlobalController.text.trim()) ?? 0.0,
          preciosEspeciales: widget.cliente.preciosEspeciales,
          latitud: _latitud,
          longitud: _longitud,
          visible: widget.cliente.visible,
          hasCCTE: _hasCCTE,
        );

        await _clienteProvider.editarCliente(clienteActualizado);
        
        // Actualizar el cliente del widget con los cambios
        widget.cliente.nombre = clienteActualizado.nombre;
        widget.cliente.telefono = clienteActualizado.telefono;
        widget.cliente.direccion = clienteActualizado.direccion;
        widget.cliente.deuda = clienteActualizado.deuda;
        widget.cliente.descuentoGlobal = clienteActualizado.descuentoGlobal;
        widget.cliente.latitud = clienteActualizado.latitud;
        widget.cliente.longitud = clienteActualizado.longitud;
        widget.cliente.hasCCTE = clienteActualizado.hasCCTE;
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted && Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
        } else if (mounted) {
          // Extraer el mensaje de error del backend si está disponible
          String errorMessage = 'Error al guardar cambios';
          final errorString = e.toString();
          
          // Intentar extraer el mensaje del backend
          if (errorString.contains('Exception: ')) {
            final parts = errorString.split('Exception: ');
            if (parts.length > 1) {
              errorMessage = parts[1].trim();
            }
          } else if (errorString.contains('404')) {
            errorMessage = 'Cliente no encontrado. Por favor, recarga la lista de clientes.';
          } else {
            errorMessage = errorString.replaceAll('Exception: ', '');
          }
          
          AppTheme.showSnackBar(
            context,
            AppTheme.errorSnackBar(errorMessage),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = false;
    });

    // Navegar a la pantalla de precios especiales
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditarPreciosEspecialesScreen(
            cliente: widget.cliente,
            isWizardMode: false, // No es modo wizard, es una pantalla independiente
          ),
        ),
      );

      // Si se guardaron cambios en precios especiales, actualizar el cliente
      if (result is Cliente && mounted) {
        widget.cliente.preciosEspeciales = result.preciosEspeciales;
      }
    }
  }

  bool _hayCambiosSinGuardar() {
    return _nombreController.text.trim() != widget.cliente.nombre ||
        _telefonoController.text.trim() != (widget.cliente.telefono?.toString() ?? '') ||
        _direccionController.text.trim() != (widget.cliente.direccion ?? '') ||
        (_descuentoGlobalController.text.trim().isEmpty ? 0.0 : double.tryParse(_descuentoGlobalController.text.trim()) ?? 0.0) != widget.cliente.descuentoGlobal ||
        _latitud != widget.cliente.latitud ||
        _longitud != widget.cliente.longitud ||
        _hasCCTE != widget.cliente.hasCCTE;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppTheme.primaryColor,
          selectionColor: AppTheme.primaryColor.withOpacity(0.3),
          selectionHandleColor: AppTheme.primaryColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Editar Cliente', style: AppTheme.appBarTitleStyle),
          backgroundColor: null,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      isDark: isDark,
                      title: 'Información Básica',
                      icon: Icons.person_outline,
                      children: [
                        _buildTextFormField(
                          controller: _nombreController,
                          label: 'Nombre *',
                          hint: 'Ingresa el nombre del cliente',
                          icon: Icons.person_outlined,
                          isDark: isDark,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _telefonoController,
                          label: 'Teléfono *',
                          hint: 'Ingresa el teléfono',
                          icon: Icons.phone_outlined,
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'El teléfono es obligatorio';
                            if (int.tryParse(v.trim()) == null) return 'Ingresa un teléfono válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _direccionController,
                          label: 'Dirección *',
                          hint: 'Ingresa la dirección',
                          icon: Icons.location_on_outlined,
                          isDark: isDark,
                          maxLines: 2,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'La dirección es obligatoria' : null,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MapPickerScreen(
                                    initial: (_latitud != null && _longitud != null)
                                        ? LatLng(_latitud!, _longitud!)
                                        : null,
                                  ),
                                ),
                              );
                              if (result is List && result.length == 2 && mounted) {
                                setState(() {
                                  _latitud = result[0] as double;
                                  _longitud = result[1] as double;
                                });
                              }
                            },
                            icon: const Icon(Icons.place, size: 20, color: AppTheme.primaryColor),
                            label: const Text('Editar ubicación en mapa'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : Colors.black87,
                              side: BorderSide(color: isDark ? const Color(0xFF404040) : Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      isDark: isDark,
                      title: 'Finanzas',
                      icon: Icons.account_balance_wallet_outlined,
                      children: [
                        _buildTextFormField(
                          controller: _descuentoGlobalController,
                          label: 'Descuento global (%)',
                          hint: '0',
                          icon: Icons.percent,
                          isDark: isDark,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final d = double.tryParse(v.trim());
                              if (d == null) return 'Ingresa un porcentaje válido';
                              if (d < 0 || d > 100) return 'Entre 0 y 100';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                            ),
                          ),
                          child: SwitchListTile.adaptive(
                            value: _hasCCTE,
                            onChanged: (value) => setState(() => _hasCCTE = value),
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Habilitar Cuenta Corriente',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            activeColor: AppTheme.primaryColor,
                            secondary: Icon(Icons.account_balance_wallet_rounded, size: 20, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      isDark: isDark,
                      title: 'Precios Especiales',
                      icon: Icons.local_offer_outlined,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _editarPreciosEspeciales,
                            icon: const Icon(Icons.local_offer, size: 20, color: AppTheme.primaryColor),
                            label: const Text('Configurar precios especiales'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : Colors.black87,
                              side: BorderSide(color: isDark ? const Color(0xFF404040) : Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 220),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _actualizarCliente,
                            icon: const Icon(Icons.save_outlined, size: 24),
                            label: const Text('Guardar Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF404040) : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF404040) : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
