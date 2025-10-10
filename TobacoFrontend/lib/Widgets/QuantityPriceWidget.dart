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

  @override
  void initState() {
    super.initState();
    _quantityPrices = List.from(widget.quantityPrices);
    _ensureUnitPrice();
  }

  void _ensureUnitPrice() {
    // No need to ensure unit price - it comes from the product's base price
  }

  void _addQuantityPrice() {
    setState(() {
      _quantityPrices.add(ProductQuantityPrice(
        productId: 0,
        quantity: 2, // Start with quantity 2 (first pack)
        totalPrice: 0.0,
      ));
    });
    widget.onChanged(_quantityPrices);
  }

  void _removeQuantityPrice(int index) {
    if (_quantityPrices.isEmpty) return; // Don't remove if empty

    setState(() {
      _quantityPrices.removeAt(index);
    });
    widget.onChanged(_quantityPrices);
  }

  void _updateQuantityPrice(int index, ProductQuantityPrice updatedPrice) {
    setState(() {
      _quantityPrices[index] = updatedPrice;
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
            TextButton.icon(
              onPressed: _addQuantityPrice,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar Pack'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
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
    final quantityController = TextEditingController(text: qp.quantity.toString());
    final priceController = TextEditingController(text: qp.totalPrice.toString());

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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: 'Cantidad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final quantity = int.tryParse(value);
                        if (quantity != null && quantity >= 2) {
                          if (_isValidQuantity(quantity, index)) {
                            _updateQuantityPrice(
                              index,
                              qp.copyWith(quantity: quantity),
                            );
                          } else {
                            // Show error for duplicate quantity
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Esta cantidad ya existe o debe ser >= 2'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            quantityController.text = qp.quantity.toString();
                          }
                        } else if (quantity != null && quantity < 2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('La cantidad debe ser >= 2 para packs'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          quantityController.text = qp.quantity.toString();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Precio total',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final price = double.tryParse(value);
                        if (price != null && price > 0) {
                          _updateQuantityPrice(
                            index,
                            qp.copyWith(totalPrice: price),
                          );
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
                    const Text(
                      'Precio Unitario',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: Text(
                        '\$${qp.unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (qp.quantity != 1)
                IconButton(
                  onPressed: () => _removeQuantityPrice(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Eliminar',
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
