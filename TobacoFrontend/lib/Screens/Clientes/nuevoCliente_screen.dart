import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/Cliente.dart';
import '../../Services/Clientes_Service/clientes_provider.dart';
import '../../Theme/app_theme.dart';
import '../../Helpers/api_handler.dart';
import 'editarPreciosEspeciales_screen.dart';
import 'map_picker_screen.dart';

class NuevoClienteScreen extends StatefulWidget {
  const NuevoClienteScreen({super.key});

  @override
  State<NuevoClienteScreen> createState() => _NuevoClienteScreenState();
}

class _NuevoClienteScreenState extends State<NuevoClienteScreen> {
  // Datos del cliente
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  double? _latitud;
  double? _longitud;
  final _deudaController = TextEditingController();
  final _descuentoGlobalController = TextEditingController();
  
  Cliente? _clienteCreado;
  bool _isLoading = false;
  String? _errorMessage;

  /// Normaliza el valor de deuda: convierte comas a puntos y formatea correctamente
  String _normalizarDeuda(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return "0";
    }
    
    // Reemplazar coma por punto y eliminar espacios
    String normalizado = valor.trim().replaceAll(',', '.').replaceAll(' ', '');
    
    // Intentar parsear como double
    final double? numero = double.tryParse(normalizado);
    
    if (numero == null || numero < 0) {
      return "0";
    }
    
    // Si es un número entero, retornarlo sin decimales
    if (numero == numero.truncateToDouble()) {
      return numero.toInt().toString();
    }
    
    // Si tiene decimales, retornarlo con punto como separador
    return numero.toString();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _deudaController.dispose();
    _descuentoGlobalController.dispose();
    super.dispose();
  }

  Future<void> _crearCliente() async {
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
      final cliente = Cliente(
        id: null,
        nombre: _nombreController.text.trim(),
        telefono: int.tryParse(_telefonoController.text.trim()),
        direccion: _direccionController.text.trim(),
        deuda: _normalizarDeuda(_deudaController.text),
        descuentoGlobal: _descuentoGlobalController.text.trim().isEmpty 
            ? 0.0 
            : double.tryParse(_descuentoGlobalController.text.trim()) ?? 0.0,
        preciosEspeciales: [],
        latitud: _latitud,
        longitud: _longitud,
      );

      final clienteProvider = Provider.of<ClienteProvider>(context, listen: false);
      final clienteCreado = await clienteProvider.crearCliente(cliente);
      
      if (!mounted) return;
      
      setState(() {
        _clienteCreado = clienteCreado;
        _isLoading = false;
      });
      
      // Mostrar mensaje de éxito
      AppTheme.showSnackBar(
        context,
        AppTheme.successSnackBar('Cliente creado exitosamente'),
      );
      
      // Retornar con el cliente creado
      Navigator.pop(context, clienteCreado);
    } catch (e) {
      if (!mounted) return;
      
      if (Apihandler.isConnectionError(e)) {
        setState(() {
          _isLoading = false;
        });
        await Apihandler.handleConnectionError(context, e);
      } else {
        setState(() {
          _isLoading = false;
        });
        // Extraer el mensaje de error del backend si está disponible
        String errorMessage = 'Error al crear el cliente';
        final errorString = e.toString();
        if (errorString.contains('Respuesta:')) {
          try {
            final jsonStart = errorString.indexOf('{');
            if (jsonStart != -1) {
              final jsonString = errorString.substring(jsonStart);
              final jsonData = jsonDecode(jsonString);
              if (jsonData is Map && jsonData.containsKey('message')) {
                errorMessage = jsonData['message'].toString();
              } else {
                errorMessage = errorString.replaceAll('Exception: ', '');
              }
            } else {
              errorMessage = errorString.replaceAll('Exception: ', '');
            }
          } catch (_) {
            errorMessage = errorString.replaceAll('Exception: ', '');
          }
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
    // Primero validar el formulario
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Por favor, completa todos los campos obligatorios antes de editar precios especiales';
      });
      return;
    }

    // Si el cliente no ha sido creado aún, crearlo primero
    if (_clienteCreado == null) {
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
          deuda: _normalizarDeuda(_deudaController.text),
          descuentoGlobal: _descuentoGlobalController.text.trim().isEmpty 
              ? 0.0 
              : double.tryParse(_descuentoGlobalController.text.trim()) ?? 0.0,
          preciosEspeciales: [],
          latitud: _latitud,
          longitud: _longitud,
        );

        final clienteProvider = Provider.of<ClienteProvider>(context, listen: false);
        final clienteCreado = await clienteProvider.crearCliente(cliente);
        
        if (!mounted) return;
        
        setState(() {
          _clienteCreado = clienteCreado;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted && Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
        } else if (mounted) {
          // Extraer el mensaje de error del backend si está disponible
          String errorMessage = 'Error al crear el cliente';
          final errorString = e.toString();
          if (errorString.contains('Respuesta:')) {
            try {
              final jsonStart = errorString.indexOf('{');
              if (jsonStart != -1) {
                final jsonString = errorString.substring(jsonStart);
                final jsonData = jsonDecode(jsonString);
                if (jsonData is Map && jsonData.containsKey('message')) {
                  errorMessage = jsonData['message'].toString();
                } else {
                  errorMessage = errorString.replaceAll('Exception: ', '');
                }
              } else {
                errorMessage = errorString.replaceAll('Exception: ', '');
              }
            } catch (_) {
              errorMessage = errorString.replaceAll('Exception: ', '');
            }
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

    // Navegar a la pantalla de precios especiales
    if (mounted && _clienteCreado != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditarPreciosEspecialesScreen(
            cliente: _clienteCreado!,
            isWizardMode: false, // No es modo wizard, es una pantalla independiente
          ),
        ),
      );

      // Si se guardaron cambios en precios especiales, actualizar el cliente
      if (result is Cliente && mounted) {
        setState(() {
          _clienteCreado = result;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nuevo Cliente',
          style: AppTheme.appBarTitleStyle,
        ),
        backgroundColor: null, // Usar el tema
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildPasoDatosBasicos(),
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
              'Información del Cliente',
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
              'Completa los datos básicos del cliente',
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
            // Coordenadas seleccionadas
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Latitud',
                      prefixIcon: Icon(Icons.map),
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: _latitud?.toStringAsFixed(6) ?? ''),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Longitud',
                      prefixIcon: Icon(Icons.map),
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: _longitud?.toStringAsFixed(6) ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapPickerScreen(),
                    ),
                  );
                  if (result is List && result.length == 2) {
                    setState(() {
                      _latitud = result[0] as double;
                      _longitud = result[1] as double;
                    });
                  }
                },
                icon: const Icon(Icons.place),
                label: const Text('Elegir ubicación en mapa'),
              ),
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
                hintText: 'Ingresa el monto de la deuda',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  // Normalizar el valor (reemplazar coma por punto)
                  final normalizado = value.trim().replaceAll(',', '.').replaceAll(' ', '');
                  if (double.tryParse(normalizado) == null) {
                    return 'Ingresa un monto válido';
                  }
                  // Validar que no sea negativo
                  final numero = double.tryParse(normalizado);
                  if (numero != null && numero < 0) {
                    return 'La deuda no puede ser negativa';
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
            
            
            const SizedBox(height: 30),
            
            // Botón Crear Cliente
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
                          Icon(Icons.person_add),
                          SizedBox(width: 8),
                          Text(
                            'Crear Cliente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botón Precios Especiales (opcional)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _editarPreciosEspeciales,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF333333)
                      : Colors.transparent,
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.local_offer, color: Colors.white),
                label: const Text(
                  'Precios Especiales',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        ),
      ),
    );
  }

}
