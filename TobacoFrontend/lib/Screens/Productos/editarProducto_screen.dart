import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/ProductQuantityPrice.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
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
  late TextEditingController cantidadController;
  late TextEditingController precioController;
  late TextEditingController halfController;

  Categoria? categoriaSeleccionada;
  List<ProductQuantityPrice> quantityPrices = [];

  // Helper method to safely parse color hex
  Color _parseColor(String colorHex) {
    try {
      if (colorHex.isEmpty || colorHex.length < 7) {
        return const Color(0xFF9E9E9E); // Default gray
      }
      return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF9E9E9E); // Default gray on error
    }
  }

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(text: widget.producto.nombre);
    cantidadController =
        TextEditingController(text: widget.producto.cantidad.toString());
    precioController =
        TextEditingController(text: widget.producto.precio.toString());
    halfController =
        TextEditingController(text: widget.producto.half.toString());

    // Initialize quantity prices
    quantityPrices = List.from(widget.producto.quantityPrices);
    if (quantityPrices.isEmpty) {
      // Add default unit price if none exists
      quantityPrices.add(ProductQuantityPrice(
        productId: widget.producto.id ?? 0,
        quantity: 1,
        totalPrice: widget.producto.precio,
      ));
    }
    
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<CategoriasProvider>(context, listen: false).obtenerCategorias();
    });
  }

  @override
  void dispose() {
    nombreController.dispose();
    cantidadController.dispose();
    precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Categoria> categorias =
        Provider.of<CategoriasProvider>(context).categorias;

    
    if (categoriaSeleccionada == null && categorias.isNotEmpty) {
      categoriaSeleccionada = categorias.firstWhere(
        (cat) => cat.nombre == widget.producto.categoriaNombre,
        orElse: () => categorias.first,
      );
    } else if (categoriaSeleccionada != null && categorias.isNotEmpty) {
      
      final match = categorias.where((cat) => cat.id == categoriaSeleccionada!.id).toList();
      if (match.isNotEmpty) {
        categoriaSeleccionada = match.first;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true, // Ajusta la pantalla al teclado
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nombre:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nombreController,
                    style: AppTheme.inputTextStyle,
                    cursorColor: Colors.black,
                    decoration: AppTheme.inputDecoration,
                    onChanged: (value) {
                      setState(() {
                        widget.producto.nombre = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cantidad:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cantidadController,
                    style: AppTheme.inputTextStyle,
                    cursorColor: Colors.black,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: AppTheme.inputDecoration,
                    onChanged: (value) {
                      setState(() {
                        widget.producto.cantidad =
                            double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Precio:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: precioController,
                    style: AppTheme.inputTextStyle,
                    cursorColor: Colors.black,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: AppTheme.inputDecoration,
                    onChanged: (value) {
                      setState(() {
                        widget.producto.precio = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Categoria:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Categoria>(
                    value: categoriaSeleccionada,
                    isExpanded: true,
                    items: categorias.map((Categoria categoria) {
                      return DropdownMenuItem<Categoria>(
                        value: categoria,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _parseColor(categoria.colorHex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              categoria.nombre,
                              style: AppTheme.inputTextStyle,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Categoria? nuevaCategoria) {
                      if (nuevaCategoria != null) {
                        setState(() {
                          categoriaSeleccionada = nuevaCategoria;
                          widget.producto.categoriaId = nuevaCategoria.id!;
                          widget.producto.categoriaNombre = nuevaCategoria.nombre;
                        });
                      }
                    },
                    decoration: AppTheme.inputDecoration.copyWith(
                      hintText: categoriaSeleccionada?.nombre ??
                          'Selecciona una categoría',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        '¿Se puede vender medio?',
                        style: AppTheme.inputLabelStyle,
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: halfController.text == 'true',
                        onChanged: (bool? value) {
                          setState(() {
                            halfController.text =
                                value == true ? 'true' : 'false';
                            widget.producto.half = value == true;
                          });
                        },
                        shape: AppTheme.checkboxTheme.shape,
                        fillColor: AppTheme.checkboxTheme.fillColor,
                        checkColor:
                            AppTheme.checkboxTheme.checkColor?.resolve({}),
                        side: AppTheme.checkboxTheme.side,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  QuantityPriceWidget(
                    quantityPrices: quantityPrices,
                    onChanged: (prices) {
                      setState(() {
                        quantityPrices = prices;
                        widget.producto.quantityPrices = prices;
                      });
                    },
                  ),
                  const SizedBox(height: 80), // Espacio para los botones
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: AppTheme.outlinedButtonStyle,
                        child: const Text(
                          'Volver',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: AppTheme.elevatedButtonStyle(
                          AppTheme.confirmButtonColor,
                        ),
                        onPressed: () async {
                          // Validar campos requeridos
                          if (nombreController.text.trim().isEmpty) {
                            AppTheme.showSnackBar(
                              context,
                              AppTheme.warningSnackBar('El nombre del producto es requerido'),
                            );
                            return;
                          }

                          // Validar que la cantidad sea un número válido
                          final cantidadValue = double.tryParse(cantidadController.text.trim());
                          if (cantidadValue == null || cantidadValue < 0) {
                            AppTheme.showSnackBar(
                              context,
                              AppTheme.warningSnackBar('La cantidad debe ser un número válido mayor o igual a 0'),
                            );
                            return;
                          }

                          // Validar que el precio sea un número válido
                          final precioValue = double.tryParse(precioController.text.trim());
                          if (precioValue == null || precioValue <= 0) {
                            AppTheme.showSnackBar(
                              context,
                              AppTheme.warningSnackBar('El precio debe ser un número válido mayor a 0'),
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
                                AppTheme.warningSnackBar('Todos los precios deben ser mayores a 0'),
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

                          try {
                            await ProductoProvider()
                                .editarProducto(widget.producto);

                            if (!mounted) return;
                            Navigator.of(context).pop();

                            // Acción para confirmar los cambios
                            if (mounted) {
                              AppTheme.showSnackBar(
                                context,
                                AppTheme.successSnackBar('Cambios confirmados'),
                              );
                            }
                          } catch (e) {
                            // Manejo de errores
                            debugPrint(
                                'Error al editar el producto: $e'); // Registro del error
                            if (mounted) {
                              AppTheme.showSnackBar(
                                context,
                                AppTheme.errorSnackBar('Error: ${e.toString()}'),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Confirmar',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
