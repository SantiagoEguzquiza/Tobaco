import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/ProductQuantityPrice.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Widgets/QuantityPriceWidget.dart';

class NuevoProductoScreen extends StatefulWidget {
  const NuevoProductoScreen({super.key});

  @override
  State<NuevoProductoScreen> createState() => _NuevoProductoScreenState();
}

class _NuevoProductoScreenState extends State<NuevoProductoScreen> {
  final nombreController = TextEditingController();
  final stockController = TextEditingController();
  final precioController = TextEditingController();
  final categoriaController = TextEditingController();
  final halfController = TextEditingController();
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
    Future.microtask(() async {
      await Provider.of<CategoriasProvider>(context, listen: false)
          .obtenerCategorias();
      
      // Seleccionar la primera categoría por defecto
      if (mounted) {
        final categorias = Provider.of<CategoriasProvider>(context, listen: false).categorias;
        if (categorias.isNotEmpty) {
          setState(() {
            categoriaController.text = categorias.first.nombre;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Categoria> categorias =
        Provider.of<CategoriasProvider>(context).categorias;

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
          'Nuevo Producto',
          style: AppTheme.appBarTitleStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
                    DropdownButtonFormField<Categoria>(
                      value: categorias.isNotEmpty ? categorias.first : null,
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
                        return DropdownMenuItem<Categoria>(
                          value: categoria,
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
                        categoriaController.text = value != null ? value.nombre : '';
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
                    _buildQuantityPricesSection(isDark),
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
                      onPressed: _guardarProducto,
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
                          Icon(Icons.check_circle_outline, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Crear Producto',
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

  Future<void> _removeQuantityPrice(int index) async {
    if (index < 0 || index >= quantityPrices.length) return;
    
    final qp = quantityPrices[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Eliminar Pack',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar el pack de ${qp.quantity} unidades?',
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true && mounted) {
      setState(() {
        quantityPrices.removeAt(index);
      });
    }
  }

  Widget _buildQuantityPricesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (quantityPrices.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'No hay packs configurados. El producto se venderá solo por unidad.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Packs configurados:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...quantityPrices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final qp = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${qp.quantity} unidades',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total: \$${qp.totalPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Unitario: \$${qp.unitPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade400,
                            size: 22,
                          ),
                          onPressed: () => _removeQuantityPrice(index),
                          tooltip: 'Eliminar pack',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showQuantityPricesDialog(isDark),
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: Text(
              quantityPrices.isEmpty 
                  ? 'Configurar Precios por Cantidad' 
                  : 'Agregar Precios por Cantidad',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showQuantityPricesDialog(bool isDark) async {
    final List<ProductQuantityPrice> tempPrices = List.from(quantityPrices);
    
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 600),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_offer_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Precios por Cantidad (Packs)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: QuantityPriceWidget(
                          quantityPrices: tempPrices,
                          onChanged: (prices) {
                            setDialogState(() {
                              tempPrices.clear();
                              tempPrices.addAll(prices);
                            });
                          },
                        ),
                      ),
                    ),
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                quantityPrices = List.from(tempPrices);
                              });
                              Navigator.of(dialogContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _guardarProducto() async {
    final categorias = Provider.of<CategoriasProvider>(context, listen: false).categorias;

    // Validaciones
    if (nombreController.text.trim().isEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('El nombre del producto es requerido'),
      );
      return;
    }

    if (stockController.text.trim().isEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('El stock es requerido'),
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

    if (precioController.text.trim().isEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('El precio es requerido'),
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

    if (categoriaController.text.trim().isEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('Debe seleccionar una categoría'),
      );
      return;
    }

    // Validar precios por cantidad (solo packs, cantidad >= 2)
    if (quantityPrices.isNotEmpty) {
      // Verificar que no hay cantidades duplicadas
      final quantities = quantityPrices.map((qp) => qp.quantity).toList();
      if (quantities.length != quantities.toSet().length) {
        AppTheme.showSnackBar(
          context,
          AppTheme.warningSnackBar('No puede haber cantidades duplicadas'),
        );
        return;
      }

      // Verificar que todos los precios son válidos y cantidades >= 2
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
      final selectedCategoria = categorias.firstWhere(
        (c) => c.nombre == categoriaController.text,
        orElse: () => categorias.first,
      );
      
      final producto = Producto(
        id: null,
        nombre: nombreController.text.trim(),
        stock: double.tryParse(stockController.text) ?? 0.0,
        precio: double.tryParse(precioController.text) ?? 0.0,
        categoriaId: selectedCategoria.id ?? 0,
        half: halfController.text == 'true',
        quantityPrices: quantityPrices,
      );

      await Provider.of<ProductoProvider>(context, listen: false)
          .crearProducto(producto);

      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Producto creado exitosamente'),
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
