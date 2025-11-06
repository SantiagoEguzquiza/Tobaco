import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tobaco/Models/ProductQuantityPrice.dart';
import 'package:tobaco/Theme/app_theme.dart';

class QuantityPriceWidget extends StatefulWidget {
  final List<ProductQuantityPrice> quantityPrices;
  final Function(List<ProductQuantityPrice>) onChanged;

  const QuantityPriceWidget({
    super.key,
    required this.quantityPrices,
    required this.onChanged,
  });

  @override
  State<QuantityPriceWidget> createState() => _QuantityPriceWidgetState();
}

class _QuantityPriceWidgetState extends State<QuantityPriceWidget> {
  late List<ProductQuantityPrice> _quantityPrices;
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, TextEditingController> _unitPriceControllers = {};
  final Map<int, bool> _isQuantityEditing = {};
  final Map<int, bool> _isPriceEditing = {};

  @override
  void initState() {
    super.initState();
    _quantityPrices = List.from(widget.quantityPrices);
    _ensureUnitPrice();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (int i = 0; i < _quantityPrices.length; i++) {
      _quantityControllers[i] = TextEditingController(text: '');
      _priceControllers[i] = TextEditingController(text: '');
      _unitPriceControllers[i] = TextEditingController(
        text: '\$${_quantityPrices[i].unitPrice.toStringAsFixed(2)}',
      );
      _isQuantityEditing[i] = false;
      _isPriceEditing[i] = false;
    }
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    for (var controller in _unitPriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _ensureUnitPrice() {
    // No need to ensure unit price - it comes from the product's base price
  }

  void _addQuantityPrice() {
    setState(() {
      final newIndex = _quantityPrices.length;
      _quantityPrices.add(ProductQuantityPrice(
        productId: 0,
        quantity: 2, // Start with quantity 2 (first pack)
        totalPrice: 0.0,
      ));
      _quantityControllers[newIndex] = TextEditingController(text: '');
      _priceControllers[newIndex] = TextEditingController(text: '');
      _unitPriceControllers[newIndex] = TextEditingController(
        text: '\$${_quantityPrices[newIndex].unitPrice.toStringAsFixed(2)}',
      );
      _isQuantityEditing[newIndex] = false;
      _isPriceEditing[newIndex] = false;
    });
    widget.onChanged(_quantityPrices);
  }

  void _updateQuantityPrice(int index, ProductQuantityPrice updatedPrice) {
    setState(() {
      _quantityPrices[index] = updatedPrice;
      // Solo actualizar controladores si no se están editando
      if (!(_isQuantityEditing[index] ?? false)) {
        _quantityControllers[index]?.text = updatedPrice.quantity.toString();
      }
      if (!(_isPriceEditing[index] ?? false)) {
        // Si el precio es 0.0, mostrar campo vacío
        _priceControllers[index]?.text = updatedPrice.totalPrice == 0.0 
            ? '' 
            : updatedPrice.totalPrice.toString();
      }
      // Actualizar precio unitario siempre
      _unitPriceControllers[index]?.text = '\$${updatedPrice.unitPrice.toStringAsFixed(2)}';
    });
    widget.onChanged(_quantityPrices);
  }

  bool _isValidQuantity(int quantity, int currentIndex) {
    // Check if quantity is unique (except for current index) and >= 2
    if (quantity < 2) return false;
    
    for (int i = 0; i < _quantityPrices.length; i++) {
      if (i != currentIndex && _quantityPrices[i].quantity == quantity) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Precios por Packs',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addQuantityPrice,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar Pack'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configure los precios para packs (cantidad >= 2). El precio unitario se toma del precio base del producto.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_quantityPrices.length, (index) {
          final qp = _quantityPrices[index];
          return _buildQuantityPriceRow(index, qp);
        }),
        if (_quantityPrices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No hay packs configurados. El producto se venderá solo por unidad.',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityPriceRow(int index, ProductQuantityPrice qp) {
    // Asegurar que los controladores existan
    if (!_quantityControllers.containsKey(index)) {
      _quantityControllers[index] = TextEditingController(text: '');
      _isQuantityEditing[index] = false;
    }
    if (!_priceControllers.containsKey(index)) {
      _priceControllers[index] = TextEditingController(text: '');
      _isPriceEditing[index] = false;
    }
    if (!_unitPriceControllers.containsKey(index)) {
      _unitPriceControllers[index] = TextEditingController(
        text: '\$${qp.unitPrice.toStringAsFixed(2)}',
      );
    }
    
    final quantityController = _quantityControllers[index]!;
    final priceController = _priceControllers[index]!;
    final unitPriceController = _unitPriceControllers[index]!;
    
    // Actualizar precio unitario si cambió
    final currentUnitPriceText = '\$${qp.unitPrice.toStringAsFixed(2)}';
    if (unitPriceController.text != currentUnitPriceText) {
      unitPriceController.text = currentUnitPriceText;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade600
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cantidad',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: 'Cantidad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onTap: () {
                        _isQuantityEditing[index] = true;
                      },
                      onChanged: (value) {
                        _isQuantityEditing[index] = true;
                        if (value.isEmpty) return;
                        
                        final quantity = int.tryParse(value);
                        if (quantity != null && quantity >= 2) {
                          if (_isValidQuantity(quantity, index)) {
                            _isQuantityEditing[index] = false;
                            _updateQuantityPrice(
                              index,
                              qp.copyWith(quantity: quantity),
                            );
                            _isQuantityEditing[index] = true;
                          } else {
                            // Show error for duplicate quantity
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Esta cantidad ya existe o debe ser >= 2'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            // No revertir inmediatamente, permitir que el usuario corrija
                          }
                        } else if (value.isNotEmpty && (quantity == null || quantity < 2)) {
                          // No validar hasta que el usuario termine de escribir
                        }
                      },
                      onEditingComplete: () {
                        _isQuantityEditing[index] = false;
                        final quantity = int.tryParse(quantityController.text);
                        if (quantityController.text.isEmpty) {
                          // Si está vacío, cerrar teclado y dejar vacío
                          FocusScope.of(context).unfocus();
                          return;
                        }
                        if (quantity == null || quantity < 2 || !_isValidQuantity(quantity, index)) {
                          quantityController.text = '';
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('La cantidad debe ser >= 2 y única'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          FocusScope.of(context).unfocus();
                        } else {
                          // Guardar y cerrar teclado
                          _updateQuantityPrice(
                            index,
                            qp.copyWith(quantity: quantity),
                          );
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio Total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Precio total',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onTap: () {
                        _isPriceEditing[index] = true;
                      },
                      onChanged: (value) {
                        _isPriceEditing[index] = true;
                        // Permitir escribir números sin restricciones mientras se escribe
                        if (value.isEmpty) return;
                        
                        final price = double.tryParse(value);
                        if (price != null && price > 0) {
                          // Actualizar sin cambiar el controlador para evitar pérdida de foco
                          final currentQp = _quantityPrices[index];
                          setState(() {
                            _quantityPrices[index] = currentQp.copyWith(totalPrice: price);
                          });
                          widget.onChanged(_quantityPrices);
                        }
                      },
                      onEditingComplete: () {
                        _isPriceEditing[index] = false;
                        if (priceController.text.isEmpty) {
                          // Si está vacío, cerrar teclado y dejar vacío
                          FocusScope.of(context).unfocus();
                          return;
                        }
                        final price = double.tryParse(priceController.text);
                        if (price == null || price <= 0) {
                          priceController.text = '';
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('El precio debe ser mayor a 0'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          FocusScope.of(context).unfocus();
                        } else {
                          // Guardar y cerrar teclado
                          final currentQp = _quantityPrices[index];
                          setState(() {
                            _quantityPrices[index] = currentQp.copyWith(totalPrice: price);
                          });
                          widget.onChanged(_quantityPrices);
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'P. Unitario',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: unitPriceController,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (qp.quantity == 1)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Precio por unidad (obligatorio)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
