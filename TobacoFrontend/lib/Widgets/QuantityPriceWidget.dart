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
          children: [
            Expanded(
              child: Text(
                'Precios por Packs',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _addQuantityPrice,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar Pack'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
        if (_quantityPrices.isEmpty) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Text(
                'No hay packs configurados. El producto se venderá solo por unidad.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 380;
    final labelStyle = TextStyle(
      fontSize: isNarrow ? 11 : 12,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade400
          : Colors.grey,
    );

    Widget cantidadField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Cantidad', style: labelStyle),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(1)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 10 : 12,
              vertical: isNarrow ? 6 : 8,
            ),
            isDense: true,
          ),
          onTap: () => _isQuantityEditing[index] = true,
          onChanged: (value) {
            _isQuantityEditing[index] = true;
            if (value.isEmpty) return;
            final quantity = int.tryParse(value);
            if (quantity != null && quantity >= 2 && _isValidQuantity(quantity, index)) {
              _isQuantityEditing[index] = false;
              _updateQuantityPrice(index, qp.copyWith(quantity: quantity));
              _isQuantityEditing[index] = true;
            } else if (value.isNotEmpty && quantity != null && quantity >= 2 && !_isValidQuantity(quantity, index)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Esta cantidad ya existe o debe ser >= 2'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          onEditingComplete: () {
            _isQuantityEditing[index] = false;
            if (quantityController.text.isEmpty) {
              FocusScope.of(context).unfocus();
              return;
            }
            final quantity = int.tryParse(quantityController.text);
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
              _updateQuantityPrice(index, qp.copyWith(quantity: quantity));
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );

    Widget precioTotalField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(isNarrow ? 'P. Total' : 'Precio Total', style: labelStyle),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(1)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 10 : 12,
              vertical: isNarrow ? 6 : 8,
            ),
            isDense: true,
          ),
          onTap: () => _isPriceEditing[index] = true,
          onChanged: (value) {
            _isPriceEditing[index] = true;
            if (value.isEmpty) return;
            final price = double.tryParse(value);
            if (price != null && price > 0) {
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
    );

    Widget unitarioField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('P. Unitario', style: labelStyle),
        const SizedBox(height: 4),
        TextField(
          controller: unitPriceController,
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(isNarrow ? 6 : 10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(isNarrow ? 6 : 10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(isNarrow ? 6 : 10)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 10 : 12,
              vertical: isNarrow ? 6 : 8,
            ),
            isDense: true,
          ),
        ),
      ],
    );

    return Container(
      margin: EdgeInsets.only(bottom: isNarrow ? 10 : 12),
      padding: EdgeInsets.all(isNarrow ? 10 : 12),
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
          if (isNarrow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cantidadField,
                const SizedBox(height: 10),
                precioTotalField,
                const SizedBox(height: 10),
                unitarioField,
              ],
            )
          else
            Row(
              children: [
                Expanded(flex: 2, child: cantidadField),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: precioTotalField),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: unitarioField),
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
