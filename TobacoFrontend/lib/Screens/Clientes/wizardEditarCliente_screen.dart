import 'package:flutter/material.dart';
import '../../Models/Cliente.dart';
import '../../Services/Clientes_Service/clientes_provider.dart';
import '../../Theme/app_theme.dart';
import '../../Helpers/api_handler.dart';
import 'editarPreciosEspeciales_screen.dart';

class WizardEditarClienteScreen extends StatefulWidget {
  final Cliente cliente;

  const WizardEditarClienteScreen({
    super.key,
    required this.cliente,
  });

  @override
  State<WizardEditarClienteScreen> createState() => _WizardEditarClienteScreenState();
}

class _WizardEditarClienteScreenState extends State<WizardEditarClienteScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Datos del cliente
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _deudaController = TextEditingController();
  final _descuentoGlobalController = TextEditingController();
  
  Cliente? _clienteActualizado;
  bool _isLoading = false;
  String? _errorMessage;
  
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
    _deudaController.text = (widget.cliente.deuda == null || widget.cliente.deuda == '0') 
        ? '' 
        : widget.cliente.deuda!;
    _descuentoGlobalController.text = widget.cliente.descuentoGlobal == 0.0 
        ? '' 
        : widget.cliente.descuentoGlobal.toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _deudaController.dispose();
    _descuentoGlobalController.dispose();
    super.dispose();
  }

  Future<void> _actualizarCliente() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Por favor, completa todos los campos obligatorios marcados con *';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clienteActualizado = Cliente(
        id: widget.cliente.id,
        nombre: _nombreController.text.trim(),
        telefono: int.tryParse(_telefonoController.text.trim()),
        direccion: _direccionController.text.trim(),
        deuda: _deudaController.text.trim().isNotEmpty ? _deudaController.text.trim() : "0",
        descuentoGlobal: _descuentoGlobalController.text.trim().isEmpty 
            ? 0.0 
            : double.tryParse(_descuentoGlobalController.text.trim()) ?? 0.0,
        preciosEspeciales: widget.cliente.preciosEspeciales,
      );

      await _clienteProvider.editarCliente(clienteActualizado);
      
      setState(() {
        _clienteActualizado = clienteActualizado;
        _isLoading = false;
      });
      
      // Avanzar al siguiente paso
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted && Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
        setState(() {
          _errorMessage = 'Error de conexión al servidor';
        });
      } else {
        setState(() {
          _errorMessage = 'Error al actualizar el cliente: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  void _finalizarWizard() {
    Navigator.pop(context, true);
  }

  void _anteriorPaso() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStep == 0 ? 'Editar Cliente' : 'Precios Especiales',
          style: AppTheme.appBarTitleStyle,
        ),
        backgroundColor: null, // Usar el tema
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: _currentStep == 0 
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _anteriorPaso,
              ),
        actions: _currentStep == 1 
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: TextButton(
                    onPressed: _finalizarWizard,
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).cardTheme.color?.withOpacity(0.2) ?? Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Finalizar',
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ]
            : [
                // Espacio vacío para balancear cuando no hay botón Finalizar
                const SizedBox(width: 48),
              ],
      ),
      body: Column(
        children: [
          // Indicador de progreso
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Datos Básicos', _currentStep >= 0),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep > 0 ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                ),
                _buildStepIndicator(1, 'Precios Especiales', _currentStep >= 1),
              ],
            ),
          ),
          
          // Contenido de los pasos
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Deshabilitar deslizamiento
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildPasoDatosBasicos(),
                _buildPasoPreciosEspeciales(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPasoDatosBasicos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: AppTheme.primaryColor.withOpacity(0.3),
            selectionHandleColor: AppTheme.primaryColor,
            cursorColor: AppTheme.primaryColor,
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Editar Información del Cliente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Modifica los datos del cliente ${widget.cliente.nombre}',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            
            // Campo Nombre
            TextFormField(
              controller: _nombreController,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ingresa el nombre del cliente',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Campo Teléfono
            TextFormField(
              controller: _telefonoController,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: const InputDecoration(
                labelText: 'Teléfono *',
                hintText: 'Ingresa el teléfono del cliente',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El teléfono es obligatorio';
                }
                if (int.tryParse(value.trim()) == null) {
                  return 'Ingresa un teléfono válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Campo Dirección
            TextFormField(
              controller: _direccionController,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: const InputDecoration(
                labelText: 'Dirección *',
                hintText: 'Ingresa la dirección del cliente',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La dirección es obligatoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Campo Deuda
            TextFormField(
              controller: _deudaController,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: const InputDecoration(
                labelText: 'Deuda',
                hintText: 'Ingresa el monto de la deuda (opcional)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un monto válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Campo Descuento Global
            TextFormField(
              controller: _descuentoGlobalController,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: const InputDecoration(
                labelText: 'Descuento Global (%)',
                hintText: 'Ingresa el porcentaje de descuento global',
                prefixIcon: Icon(Icons.percent),
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final descuento = double.tryParse(value.trim());
                  if (descuento == null) {
                    return 'Ingresa un porcentaje válido';
                  }
                  if (descuento < 0 || descuento > 100) {
                    return 'El descuento debe estar entre 0 y 100';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            
            // Mensaje de error
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            const SizedBox(height: 30),
            
            // Botón Siguiente
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _actualizarCliente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Siguiente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildPasoPreciosEspeciales() {
    if (_clienteActualizado == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return EditarPreciosEspecialesScreen(
      cliente: _clienteActualizado!,
      isWizardMode: true,
    );
  }
}
