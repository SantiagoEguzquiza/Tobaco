import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/ProductQuantityPrice.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Widgets/QuantityPriceWidget.dart';
import 'package:intl/intl.dart';

class EditarProductoScreen extends StatefulWidget {
  final Producto producto;
  const EditarProductoScreen({super.key, required this.producto});

  @override
  EditarProductoScreenState createState() => EditarProductoScreenState();
}

class EditarProductoScreenState extends State<EditarProductoScreen> {
  late TextEditingController nombreController;
  late TextEditingController marcaController;
  late TextEditingController stockController;
  late TextEditingController precioController;
  late TextEditingController halfController;
  late TextEditingController descuentoController;

  int? categoriaSeleccionadaId;
  List<ProductQuantityPrice> quantityPrices = [];
  bool _isLoading = false;
  bool _descuentoIndefinido = false;
  DateTime? _fechaExpiracionDescuento;

  // Helper method to safely parse color hex
  Color _parseColor(String colorHex) {
    try {
      if (colorHex.isEmpty || colorHex.length < 7) {
        return const Color(0xFF9E9E9E);
      }
      return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF9E9E9E);
    }
  }

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(text: widget.producto.nombre);
    marcaController = TextEditingController(text: widget.producto.marca ?? '');
    stockController =
        TextEditingController(text: widget.producto.stock.toString());
    precioController =
        TextEditingController(text: widget.producto.precio.toString());
    halfController =
        TextEditingController(text: widget.producto.half.toString());
    descuentoController = TextEditingController(
        text: widget.producto.descuento.toStringAsFixed(2));

    // Initialize quantity prices
    quantityPrices = List.from(widget.producto.quantityPrices);
    
    // Inicializar con el ID de la categoría del producto
    categoriaSeleccionadaId = widget.producto.categoriaId;
    
    // Inicializar campos de descuento
    _descuentoIndefinido = widget.producto.descuentoIndefinido;
    _fechaExpiracionDescuento = widget.producto.fechaExpiracionDescuento;
    
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<CategoriasProvider>(context, listen: false).obtenerCategorias();
    });
  }

  @override
  void dispose() {
    nombreController.dispose();
    marcaController.dispose();
    stockController.dispose();
    precioController.dispose();
    descuentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Categoria> categorias =
        Provider.of<CategoriasProvider>(context).categorias;

    // Validar que la categoría seleccionada esté en la lista
    if (categoriaSeleccionadaId != null && categorias.isNotEmpty) {
      if (!categorias.any((cat) => cat.id == categoriaSeleccionadaId)) {
        categoriaSeleccionadaId = categorias.first.id;
      }
    }

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
        title: const Text(
          'Editar Producto',
          style: AppTheme.appBarTitleStyle,
        ),
        backgroundColor: null, // Usar el tema
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información básica
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Información Básica',
                  icon: Icons.info_outline,
                  children: [
                    _buildTextField(
                      controller: nombreController,
                      label: 'Nombre del producto',
                      hint: 'Ej: Marlboro Rojo',
                      icon: Icons.inventory_2_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: marcaController,
                      label: 'Marca',
                      hint: 'Ej: Marlboro',
                      icon: Icons.branding_watermark_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: stockController,
                            label: 'Stock disponible',
                            hint: '0',
                            icon: Icons.warehouse_outlined,
                            isDark: isDark,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: precioController,
                            label: 'Precio unitario',
                            hint: '0.00',
                            icon: Icons.attach_money,
                            isDark: isDark,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Categoría
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Categoría',
                  icon: Icons.category_outlined,
                  children: [
                    DropdownButtonFormField<int>(
                      value: categoriaSeleccionadaId,
                      decoration: InputDecoration(
                        hintText: 'Seleccione una categoría',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      items: categorias.map((categoria) {
                        return DropdownMenuItem<int>(
                          value: categoria.id,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _parseColor(categoria.colorHex),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(categoria.nombre),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          categoriaSeleccionadaId = value;
                          widget.producto.categoriaId = value ?? 0;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Descuento
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Descuento',
                  icon: Icons.percent_outlined,
                  children: [
                    _buildTextField(
                      controller: descuentoController,
                      label: 'Porcentaje de descuento (%)',
                      hint: '0',
                      icon: Icons.percent,
                      isDark: isDark,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.schedule_outlined,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Descuento indefinido',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'El descuento no expirará',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _descuentoIndefinido,
                            onChanged: (bool value) {
                              setState(() {
                                _descuentoIndefinido = value;
                                if (value) {
                                  _fechaExpiracionDescuento = null;
                                  widget.producto.fechaExpiracionDescuento = null;
                                }
                                widget.producto.descuentoIndefinido = value;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    if (!_descuentoIndefinido) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _selectFechaExpiracion(context, isDark),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha de expiración',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fechaExpiracionDescuento != null
                                          ? DateFormat('dd/MM/yyyy').format(_fechaExpiracionDescuento!)
                                          : 'Seleccionar fecha',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Opciones
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Opciones',
                  icon: Icons.settings_outlined,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.call_split,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿Se puede vender medio?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Permite vender fracciones del producto',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: halfController.text == 'true',
                            onChanged: (bool value) {
                              setState(() {
                                halfController.text = value ? 'true' : 'false';
                                widget.producto.half = value;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Precios por cantidad (packs)
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Precios por Cantidad (Packs)',
                  icon: Icons.local_offer_outlined,
                  children: [
                    QuantityPriceWidget(
                      quantityPrices: quantityPrices,
                      onChanged: (prices) {
                        setState(() {
                          quantityPrices = prices;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 100), // Espacio para el botón flotante
              ],
            ),
          ),
          
          // Botón flotante para guardar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
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
                          onPressed: _guardarCambios,
                          icon: const Icon(Icons.save_outlined, size: 24),
                          label: const Text(
                            'Guardar Cambios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
            color: isDark 
                ? Colors.black.withOpacity(0.3) 
                : Colors.black.withOpacity(0.05),
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
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          onChanged: (value) {
            setState(() {
              if (controller == nombreController) {
                widget.producto.nombre = value;
              } else if (controller == marcaController) {
                widget.producto.marca = value.isEmpty ? null : value;
              } else if (controller == stockController) {
                widget.producto.stock = double.tryParse(value) ?? 0.0;
              } else if (controller == precioController) {
                widget.producto.precio = double.tryParse(value) ?? 0.0;
              } else if (controller == descuentoController) {
                widget.producto.descuento = double.tryParse(value) ?? 0.0;
              }
            });
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _selectFechaExpiracion(BuildContext context, bool isDark) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        DateTime? selectedDate = _fechaExpiracionDescuento ?? DateTime.now().add(const Duration(days: 30));
        
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark 
              ? ColorScheme.dark(
                  primary: AppTheme.primaryColor,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF1A1A1A),
                  onSurface: Colors.white,
                  surfaceVariant: const Color(0xFF2A2A2A),
                )
              : ColorScheme.light(
                  primary: AppTheme.primaryColor,
                  onPrimary: Colors.white,
                  onSurface: Colors.black87,
                ),
            dialogBackgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                content: SizedBox(
                  width: 300,
                  child: CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    onDateChanged: (date) {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                  ),
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                actions: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            minimumSize: const Size(120, 44),
                            fixedSize: const Size(120, 44),
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(selectedDate),
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            minimumSize: const Size(120, 44),
                            fixedSize: const Size(120, 44),
                          ),
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    if (picked != null && picked != _fechaExpiracionDescuento) {
      setState(() {
        _fechaExpiracionDescuento = picked;
        widget.producto.fechaExpiracionDescuento = picked;
      });
    }
  }

  Future<void> _guardarCambios() async {
    // Validaciones
    if (nombreController.text.trim().isEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('El nombre del producto es requerido'),
      );
      return;
    }

    final stockValue = double.tryParse(stockController.text.trim());
    if (stockValue == null || stockValue < 0) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('El stock debe ser un número válido mayor o igual a 0'),
      );
      return;
    }

    final precioValue = double.tryParse(precioController.text.trim());
    if (precioValue == null || precioValue <= 0) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('El precio debe ser un número válido mayor a 0'),
      );
      return;
    }

    // Validar descuento
    final descuentoValue = double.tryParse(descuentoController.text.trim()) ?? 0.0;
    if (descuentoValue < 0 || descuentoValue > 100) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('El descuento debe estar entre 0 y 100'),
      );
      return;
    }

    if (!_descuentoIndefinido && descuentoValue > 0 && _fechaExpiracionDescuento == null) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('Debe seleccionar una fecha de expiración si el descuento no es indefinido'),
      );
      return;
    }

    // Validar precios por cantidad
    if (quantityPrices.isNotEmpty) {
      final quantities = quantityPrices.map((qp) => qp.quantity).toList();
      if (quantities.length != quantities.toSet().length) {
        AppTheme.showSnackBar(
          context,
          AppTheme.warningSnackBar('No puede haber cantidades duplicadas'),
        );
        return;
      }

      if (quantityPrices.any((qp) => qp.totalPrice <= 0)) {
        AppTheme.showSnackBar(
          context,
          AppTheme.warningSnackBar('Los precios deben ser mayores a 0'),
        );
        return;
      }

      if (quantityPrices.any((qp) => qp.quantity < 2)) {
        AppTheme.showSnackBar(
          context,
          AppTheme.warningSnackBar('Las cantidades deben ser >= 2 para packs'),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      widget.producto.quantityPrices = quantityPrices;
      widget.producto.descuento = descuentoValue;
      widget.producto.fechaExpiracionDescuento = _descuentoIndefinido ? null : _fechaExpiracionDescuento;
      widget.producto.descuentoIndefinido = _descuentoIndefinido;

      await Provider.of<ProductoProvider>(context, listen: false)
          .editarProducto(widget.producto);

      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Producto actualizado exitosamente'),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _mostrarDialogoEliminar() async {
    final confirmar = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Producto',
      message: '¿Está seguro de que desea eliminar "${widget.producto.nombre}"?\n\nEsta acción no se puede deshacer.',
    );

    if (confirmar == true && mounted) {
      setState(() => _isLoading = true);

      try {
      await Provider.of<ProductoProvider>(context, listen: false)
          .eliminarProducto(widget.producto.id!);

      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Producto eliminado exitosamente'),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar(e.toString()),
        );
      }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
