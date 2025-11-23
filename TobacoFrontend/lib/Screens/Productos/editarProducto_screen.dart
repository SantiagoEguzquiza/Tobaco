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

  int? categoriaSeleccionadaId;
  List<ProductQuantityPrice> quantityPrices = [];
  bool _isLoading = false;

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

    // Initialize quantity prices
    quantityPrices = List.from(widget.producto.quantityPrices);
    
    // Inicializar con el ID de la categoría del producto
    categoriaSeleccionadaId = widget.producto.categoriaId;
    
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
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Editar Producto',
          style: AppTheme.appBarTitleStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _mostrarDialogoEliminar,
            tooltip: 'Eliminar producto',
          ),
        ],
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
            left: 20,
            right: 20,
            bottom: 20,
            child: SafeArea(
              child: _isLoading
                  ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
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
                  : ElevatedButton(
                      onPressed: _guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Guardar Cambios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
