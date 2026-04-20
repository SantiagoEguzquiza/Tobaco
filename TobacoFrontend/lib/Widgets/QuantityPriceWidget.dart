import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tobaco/Models/ProductQuantityPrice.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';

enum _PackPriceMode { percent, total }

class QuantityPriceWidget extends StatefulWidget {
  final List<ProductQuantityPrice> quantityPrices;
  final Function(List<ProductQuantityPrice>) onChanged;
  final double basePrice;

  const QuantityPriceWidget({
    super.key,
    required this.quantityPrices,
    required this.onChanged,
    required this.basePrice,
  });

  @override
  State<QuantityPriceWidget> createState() => _QuantityPriceWidgetState();
}

class _QuantityPriceWidgetState extends State<QuantityPriceWidget> {
  late List<ProductQuantityPrice> _quantityPrices;
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, TextEditingController> _percentControllers = {};
  final Map<int, TextEditingController> _unitPriceControllers = {};
  final Map<int, bool> _isQuantityEditing = {};
  final Map<int, bool> _isPriceEditing = {};
  final Map<int, bool> _isPercentEditing = {};
  final Map<int, _PackPriceMode> _modes = {};

  @override
  void initState() {
    super.initState();
    _quantityPrices = List.from(widget.quantityPrices);
    for (int i = 0; i < _quantityPrices.length; i++) {
      _ensureRowControllers(i);
    }
  }

  @override
  void didUpdateWidget(covariant QuantityPriceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.basePrice != oldWidget.basePrice) {
      // Recomputar totales de filas en modo porcentaje cuando cambia el precio base.
      for (int i = 0; i < _quantityPrices.length; i++) {
        if (_modes[i] == _PackPriceMode.percent) {
          final percentText = _percentControllers[i]?.text ?? '';
          final percent = double.tryParse(percentText);
          if (percent != null) {
            _applyPercent(i, percent, notifyChanged: false);
          }
        }
      }
      widget.onChanged(_quantityPrices);
    }
  }

  void _ensureRowControllers(int index) {
    final qp = _quantityPrices[index];
    _quantityControllers.putIfAbsent(
      index,
      () => TextEditingController(text: qp.quantity >= 2 ? qp.quantity.toString() : ''),
    );
    _priceControllers.putIfAbsent(
      index,
      () => TextEditingController(text: qp.totalPrice > 0 ? qp.totalPrice.toString() : ''),
    );
    _percentControllers.putIfAbsent(index, () {
      final computed = _computePercent(qp.totalPrice, qp.quantity);
      return TextEditingController(
        text: computed != null ? computed.toStringAsFixed(2) : '',
      );
    });
    _unitPriceControllers.putIfAbsent(
      index,
      () => TextEditingController(text: '\$${qp.unitPrice.toStringAsFixed(2)}'),
    );
    _isQuantityEditing.putIfAbsent(index, () => false);
    _isPriceEditing.putIfAbsent(index, () => false);
    _isPercentEditing.putIfAbsent(index, () => false);
    _modes.putIfAbsent(index, () => _PackPriceMode.total);
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    for (var controller in _percentControllers.values) {
      controller.dispose();
    }
    for (var controller in _unitPriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addQuantityPrice() {
    setState(() {
      final newIndex = _quantityPrices.length;
      _quantityPrices.add(ProductQuantityPrice(
        productId: 0,
        quantity: 2,
        totalPrice: 0.0,
      ));
      _quantityControllers[newIndex] = TextEditingController(text: '');
      _priceControllers[newIndex] = TextEditingController(text: '');
      _percentControllers[newIndex] = TextEditingController(text: '');
      _unitPriceControllers[newIndex] = TextEditingController(
        text: '\$${_quantityPrices[newIndex].unitPrice.toStringAsFixed(2)}',
      );
      _isQuantityEditing[newIndex] = false;
      _isPriceEditing[newIndex] = false;
      _isPercentEditing[newIndex] = false;
      _modes[newIndex] = _PackPriceMode.total;
    });
    widget.onChanged(_quantityPrices);
  }

  Future<void> _removeQuantityPrice(int index) async {
    if (index < 0 || index >= _quantityPrices.length) return;

    final qp = _quantityPrices[index];
    final itemName = qp.quantity >= 2
        ? 'Pack #${index + 1} (${qp.quantity} unidades)'
        : 'Pack #${index + 1}';

    final confirmed = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar pack',
      itemName: itemName,
      confirmText: 'Eliminar',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _quantityPrices.removeAt(index);
      _quantityControllers.remove(index)?.dispose();
      _priceControllers.remove(index)?.dispose();
      _percentControllers.remove(index)?.dispose();
      _unitPriceControllers.remove(index)?.dispose();
      _isQuantityEditing.remove(index);
      _isPriceEditing.remove(index);
      _isPercentEditing.remove(index);
      _modes.remove(index);

      // Reindexar los mapas para que coincidan con los nuevos índices.
      final newQuantity = <int, TextEditingController>{};
      final newPrice = <int, TextEditingController>{};
      final newPercent = <int, TextEditingController>{};
      final newUnit = <int, TextEditingController>{};
      final newIsQty = <int, bool>{};
      final newIsPrice = <int, bool>{};
      final newIsPercent = <int, bool>{};
      final newModes = <int, _PackPriceMode>{};

      final oldKeys = _quantityControllers.keys.toList()..sort();
      int newIdx = 0;
      for (final oldIdx in oldKeys) {
        newQuantity[newIdx] = _quantityControllers[oldIdx]!;
        newPrice[newIdx] = _priceControllers[oldIdx]!;
        newPercent[newIdx] = _percentControllers[oldIdx]!;
        newUnit[newIdx] = _unitPriceControllers[oldIdx]!;
        newIsQty[newIdx] = _isQuantityEditing[oldIdx] ?? false;
        newIsPrice[newIdx] = _isPriceEditing[oldIdx] ?? false;
        newIsPercent[newIdx] = _isPercentEditing[oldIdx] ?? false;
        newModes[newIdx] = _modes[oldIdx] ?? _PackPriceMode.total;
        newIdx++;
      }
      _quantityControllers
        ..clear()
        ..addAll(newQuantity);
      _priceControllers
        ..clear()
        ..addAll(newPrice);
      _percentControllers
        ..clear()
        ..addAll(newPercent);
      _unitPriceControllers
        ..clear()
        ..addAll(newUnit);
      _isQuantityEditing
        ..clear()
        ..addAll(newIsQty);
      _isPriceEditing
        ..clear()
        ..addAll(newIsPrice);
      _isPercentEditing
        ..clear()
        ..addAll(newIsPercent);
      _modes
        ..clear()
        ..addAll(newModes);
    });
    widget.onChanged(_quantityPrices);
  }

  double? _computePercent(double totalPrice, int quantity) {
    final basePrice = widget.basePrice;
    if (basePrice <= 0 || quantity <= 0 || totalPrice <= 0) return null;
    final percent = (1 - totalPrice / (basePrice * quantity)) * 100;
    if (percent <= 0) return null;
    return percent.clamp(0, 100).toDouble();
  }

  void _applyPercent(int index, double percent, {bool notifyChanged = true}) {
    final qp = _quantityPrices[index];
    final basePrice = widget.basePrice;
    if (basePrice <= 0 || qp.quantity <= 0) return;
    final clamped = percent.clamp(0, 100).toDouble();
    final newTotal = basePrice * qp.quantity * (1 - clamped / 100);
    final rounded = double.parse(newTotal.toStringAsFixed(2));
    _quantityPrices[index] = qp.copyWith(totalPrice: rounded);
    if (!(_isPriceEditing[index] ?? false)) {
      _priceControllers[index]?.text = rounded.toString();
    }
    _unitPriceControllers[index]?.text =
        '\$${_quantityPrices[index].unitPrice.toStringAsFixed(2)}';
    if (notifyChanged) widget.onChanged(_quantityPrices);
  }

  void _applyTotalPrice(int index, double total, {bool notifyChanged = true}) {
    final qp = _quantityPrices[index];
    _quantityPrices[index] = qp.copyWith(totalPrice: total);
    _unitPriceControllers[index]?.text =
        '\$${_quantityPrices[index].unitPrice.toStringAsFixed(2)}';
    if (!(_isPercentEditing[index] ?? false)) {
      final percent = _computePercent(total, qp.quantity);
      _percentControllers[index]?.text =
          percent != null ? percent.toStringAsFixed(2) : '';
    }
    if (notifyChanged) widget.onChanged(_quantityPrices);
  }

  void _onQuantityChanged(int index, int newQuantity) {
    setState(() {
      _quantityPrices[index] =
          _quantityPrices[index].copyWith(quantity: newQuantity);
      // Si el modo es porcentaje, recalcular el total con la nueva cantidad.
      if (_modes[index] == _PackPriceMode.percent) {
        final percent = double.tryParse(_percentControllers[index]?.text ?? '');
        if (percent != null) {
          _applyPercent(index, percent, notifyChanged: false);
        }
      } else {
        // En modo total, solo actualizar unitario y el porcentaje derivado.
        _unitPriceControllers[index]?.text =
            '\$${_quantityPrices[index].unitPrice.toStringAsFixed(2)}';
        final percent = _computePercent(
          _quantityPrices[index].totalPrice,
          newQuantity,
        );
        _percentControllers[index]?.text =
            percent != null ? percent.toStringAsFixed(2) : '';
      }
    });
    widget.onChanged(_quantityPrices);
  }

  void _onModeChanged(int index, _PackPriceMode mode) {
    setState(() {
      _modes[index] = mode;
      if (mode == _PackPriceMode.percent) {
        // Precargar porcentaje desde el total actual si se puede.
        final percent = _computePercent(
          _quantityPrices[index].totalPrice,
          _quantityPrices[index].quantity,
        );
        _percentControllers[index]?.text =
            percent != null ? percent.toStringAsFixed(2) : '';
      } else {
        // Asegurar que el input de total refleje el valor actual.
        final total = _quantityPrices[index].totalPrice;
        _priceControllers[index]?.text = total > 0 ? total.toString() : '';
      }
    });
  }

  bool _isValidQuantity(int quantity, int currentIndex) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addQuantityPrice,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Agregar Pack',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_quantityPrices.isNotEmpty) ...[
          const SizedBox(height: 20),
          ...List.generate(_quantityPrices.length, (index) {
            final qp = _quantityPrices[index];
            return _buildQuantityPriceRow(index, qp);
          }),
        ] else ...[
          const SizedBox(height: 16),
          _buildEmptyState(isDark),
        ],
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_offer_outlined,
              size: 28,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin packs configurados',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agregá packs para ofrecer descuentos\npor cantidad.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityPriceRow(int index, ProductQuantityPrice qp) {
    _ensureRowControllers(index);

    final quantityController = _quantityControllers[index]!;
    final priceController = _priceControllers[index]!;
    final percentController = _percentControllers[index]!;
    final mode = _modes[index] ?? _PackPriceMode.total;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final basePriceMissing = widget.basePrice <= 0;
    final savingsPercent =
        _computePercent(qp.totalPrice, qp.quantity); // null si no aplica

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRowHeader(index, isDark),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFieldLabel('Cantidad', isDark),
                const SizedBox(height: 6),
                _buildQuantityInput(index, quantityController),
                const SizedBox(height: 16),
                _buildFieldLabel('Calcular precio por', isDark),
                const SizedBox(height: 6),
                _buildModePicker(index, mode, isDark),
                const SizedBox(height: 16),
                _buildFieldLabel(
                  mode == _PackPriceMode.percent
                      ? 'Porcentaje de descuento'
                      : 'Precio total del pack',
                  isDark,
                ),
                const SizedBox(height: 6),
                if (mode == _PackPriceMode.percent)
                  _buildPercentInput(index, percentController, basePriceMissing)
                else
                  _buildTotalPriceInput(index, priceController),
                const SizedBox(height: 16),
                _buildUnitPriceSummary(qp, savingsPercent, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowHeader(int index, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pack #${index + 1}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _removeQuantityPrice(index),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.shade400,
              size: 22,
            ),
            tooltip: 'Eliminar pack',
            visualDensity: VisualDensity.compact,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text, bool isDark) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required bool isDark,
    String? hintText,
    String? prefixText,
    String? suffixText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      suffixText: suffixText,
      prefixIcon: prefixIcon,
      hintStyle: TextStyle(
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        fontSize: 14,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppTheme.primaryColor,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildQuantityInput(int index, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: _buildInputDecoration(
        isDark: isDark,
        hintText: 'Ej: 6 unidades',
        prefixIcon: Icon(
          Icons.inventory_2_outlined,
          size: 18,
          color: AppTheme.primaryColor,
        ),
      ),
      onTap: () => _isQuantityEditing[index] = true,
      onChanged: (value) {
        _isQuantityEditing[index] = true;
        if (value.isEmpty) return;
        final quantity = int.tryParse(value);
        if (quantity != null &&
            quantity >= 2 &&
            _isValidQuantity(quantity, index)) {
          _isQuantityEditing[index] = false;
          _onQuantityChanged(index, quantity);
          _isQuantityEditing[index] = true;
        }
      },
      onEditingComplete: () {
        _isQuantityEditing[index] = false;
        if (controller.text.isEmpty) {
          FocusScope.of(context).unfocus();
          return;
        }
        final quantity = int.tryParse(controller.text);
        if (quantity == null ||
            quantity < 2 ||
            !_isValidQuantity(quantity, index)) {
          controller.text = '';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La cantidad debe ser >= 2 y única'),
              backgroundColor: Colors.red,
            ),
          );
          FocusScope.of(context).unfocus();
        } else {
          _onQuantityChanged(index, quantity);
          FocusScope.of(context).unfocus();
        }
      },
    );
  }

  Widget _buildModePicker(int index, _PackPriceMode mode, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeOption(
              icon: Icons.percent_rounded,
              label: 'Porcentaje',
              selected: mode == _PackPriceMode.percent,
              isDark: isDark,
              onTap: () => _onModeChanged(index, _PackPriceMode.percent),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeOption(
              icon: Icons.attach_money_rounded,
              label: 'Precio Total',
              selected: mode == _PackPriceMode.total,
              isDark: isDark,
              onTap: () => _onModeChanged(index, _PackPriceMode.total),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : (isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPriceInput(int index, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: _buildInputDecoration(
        isDark: isDark,
        hintText: '0.00',
        prefixText: '\$ ',
        prefixIcon: Icon(
          Icons.attach_money_rounded,
          size: 18,
          color: AppTheme.primaryColor,
        ),
      ),
      onTap: () => _isPriceEditing[index] = true,
      onChanged: (value) {
        _isPriceEditing[index] = true;
        if (value.isEmpty) return;
        final price = double.tryParse(value);
        if (price != null && price > 0) {
          setState(() {
            _applyTotalPrice(index, price);
          });
        }
      },
      onEditingComplete: () {
        _isPriceEditing[index] = false;
        if (controller.text.isEmpty) {
          FocusScope.of(context).unfocus();
          return;
        }
        final price = double.tryParse(controller.text);
        if (price == null || price <= 0) {
          controller.text = '';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El precio debe ser mayor a 0'),
              backgroundColor: Colors.red,
            ),
          );
          FocusScope.of(context).unfocus();
        } else {
          setState(() {
            _applyTotalPrice(index, price);
          });
          FocusScope.of(context).unfocus();
        }
      },
    );
  }

  Widget _buildPercentInput(
    int index,
    TextEditingController controller,
    bool basePriceMissing,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          enabled: !basePriceMissing,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: _buildInputDecoration(
            isDark: isDark,
            hintText: basePriceMissing ? 'Definí el precio base' : '0',
            suffixText: '%',
            prefixIcon: Icon(
              Icons.percent_rounded,
              size: 18,
              color: basePriceMissing
                  ? Colors.grey.shade500
                  : AppTheme.primaryColor,
            ),
          ),
          onTap: () => _isPercentEditing[index] = true,
          onChanged: (value) {
            _isPercentEditing[index] = true;
            if (value.isEmpty) return;
            final percent = double.tryParse(value);
            if (percent != null && percent >= 0 && percent <= 100) {
              setState(() {
                _applyPercent(index, percent);
              });
            }
          },
          onEditingComplete: () {
            _isPercentEditing[index] = false;
            if (controller.text.isEmpty) {
              FocusScope.of(context).unfocus();
              return;
            }
            final percent = double.tryParse(controller.text);
            if (percent == null || percent < 0 || percent > 100) {
              controller.text = '';
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El porcentaje debe estar entre 0 y 100'),
                  backgroundColor: Colors.red,
                ),
              );
              FocusScope.of(context).unfocus();
            } else {
              setState(() {
                _applyPercent(index, percent);
              });
              FocusScope.of(context).unfocus();
            }
          },
        ),
        if (basePriceMissing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Definí primero el precio base del producto',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUnitPriceSummary(
    ProductQuantityPrice qp,
    double? savingsPercent,
    bool isDark,
  ) {
    final hasValue = qp.totalPrice > 0 && qp.quantity > 0;
    final unitPriceText =
        hasValue ? '\$${qp.unitPrice.toStringAsFixed(2)}' : '\$0.00';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(isDark ? 0.22 : 0.12),
            AppTheme.primaryColor.withOpacity(isDark ? 0.10 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(isDark ? 0.35 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(isDark ? 0.35 : 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sell_outlined,
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Precio por unidad',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unitPriceText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (savingsPercent != null && savingsPercent > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_down_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '-${savingsPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
