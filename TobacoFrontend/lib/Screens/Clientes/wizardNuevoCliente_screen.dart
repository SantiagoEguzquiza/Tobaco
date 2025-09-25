import 'package:flutter/material.dart';
import '../../Models/Cliente.dart';
import '../../Services/Clientes_Service/clientes_provider.dart';
import '../../Theme/app_theme.dart';
import 'editarPreciosEspeciales_screen.dart';

class WizardNuevoClienteScreen extends StatefulWidget {
  const WizardNuevoClienteScreen({super.key});

  @override
  State<WizardNuevoClienteScreen> createState() => _WizardNuevoClienteScreenState();
}

class _WizardNuevoClienteScreenState extends State<WizardNuevoClienteScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Datos del cliente
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _deudaController = TextEditingController();
  
  Cliente? _clienteCreado;
  bool _isLoading = false;
  String? _errorMessage;
  
  final ClienteProvider _clienteProvider = ClienteProvider();

  @override
  void dispose() {
    _pageController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _deudaController.dispose();
    super.dispose();
  }

  Future<void> _crearCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cliente = Cliente(
        id: null,
        nombre: _nombreController.text.trim(),
        telefono: int.tryParse(_telefonoController.text.trim()),
        direccion: _direccionController.text.trim(),
        deuda: _deudaController.text.trim().isNotEmpty ? _deudaController.text.trim() : null,
        preciosEspeciales: [],
      );

      final clienteCreado = await _clienteProvider.crearCliente(cliente);
      
      if (clienteCreado != null) {
        setState(() {
          _clienteCreado = clienteCreado;
          _isLoading = false;
        });
        
        // Avanzar al siguiente paso
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        setState(() {
          _errorMessage = 'Error al crear el cliente';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _finalizarWizard() {
    Navigator.pop(context, _clienteCreado);
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
        title: Text(_currentStep == 0 ? 'Nuevo Cliente' : 'Precios Especiales'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: _currentStep == 0 
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _anteriorPaso,
              ),
        actions: _currentStep == 1 
            ? [
                TextButton(
                  onPressed: _finalizarWizard,
                  child: const Text(
                    'Finalizar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ]
            : null,
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Cliente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa los datos básicos del cliente',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            
            // Campo Nombre
            TextFormField(
              controller: _nombreController,
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
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                hintText: 'Ingresa el teléfono del cliente',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (int.tryParse(value) == null) {
                    return 'Ingresa un teléfono válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Campo Dirección
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                hintText: 'Ingresa la dirección del cliente',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            
            // Campo Deuda
            TextFormField(
              controller: _deudaController,
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
            
            const Spacer(),
            
            // Botón Siguiente
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _crearCliente,
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
    );
  }

  Widget _buildPasoPreciosEspeciales() {
    if (_clienteCreado == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return EditarPreciosEspecialesScreen(
      cliente: _clienteCreado!,
      isWizardMode: true,
    );
  }
}
