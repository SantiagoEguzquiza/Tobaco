import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/ProductQuantityPrice.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Widgets/QuantityPriceWidget.dart';

class NuevoProductoScreen extends StatefulWidget {
  const NuevoProductoScreen({super.key});

  @override
  State<NuevoProductoScreen> createState() => _NuevoProductoScreenState();
}

class _NuevoProductoScreenState extends State<NuevoProductoScreen> {
  final nombreController = TextEditingController();
  final cantidadController = TextEditingController();
  final precioController = TextEditingController();
  final categoriaController = TextEditingController();
  final halfController = TextEditingController();
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
    // Cargar categorías al iniciar
    Future.microtask(() =>
        Provider.of<CategoriasProvider>(context, listen: false)
            .obtenerCategorias());
  }

  @override
  Widget build(BuildContext context) {
    final List<Categoria> categorias =
        Provider.of<CategoriasProvider>(context).categorias;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF66BB6A),
          surface: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          background: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0F0F0F)
              : const Color(0xFFF8F9FA),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF4CAF50),
          selectionColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : const Color(0xFF4CAF50).withOpacity(0.2),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF4CAF50),
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade600
                  : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade600
                  : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFF4CAF50),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F0F0F)
            : const Color(0xFFF8F9FA),
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Nuevo Producto',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.white,
            ),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : const Color(0xFF4CAF50),
          iconTheme: IconThemeData(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.white,
          ),
        ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Scroll con campos
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 140), // espacio para botones
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nombre:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: nombreController,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          decoration: AppTheme.inputDecoration.copyWith(
                            hintText: 'Ingrese el nombre...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cantidad:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: cantidadController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          decoration: AppTheme.inputDecoration.copyWith(
                            hintText: 'Ingrese la cantidad...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Precio:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: precioController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          decoration: AppTheme.inputDecoration.copyWith(
                            hintText: 'Ingrese el precio...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Categoría:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Categoria>(
                          value:
                              categorias.isNotEmpty ? categorias.first : null,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          items: categorias.map((categoria) {
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
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            categoriaController.text =
                                value != null ? value.nombre : '';
                          },
                          decoration: AppTheme.inputDecoration.copyWith(
                            hintText: 'Seleccione una categoría...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        StatefulBuilder(
                          builder: (context, setState) {
                            return Row(
                              children: [
                                Text(
                                  '¿Se puede vender medio?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Checkbox(
                                  value: halfController.text == 'true',
                                  onChanged: (bool? value) {
                                    setState(() {
                                      halfController.text =
                                          value == true ? 'true' : 'false';
                                    });
                                  },
                                  shape: AppTheme.checkboxTheme.shape,
                                  fillColor: AppTheme.checkboxTheme.fillColor,
                                  checkColor: AppTheme.checkboxTheme.checkColor
                                      ?.resolve({}),
                                  side: AppTheme.checkboxTheme.side,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        QuantityPriceWidget(
                          quantityPrices: quantityPrices,
                          onChanged: (prices) {
                            setState(() {
                              quantityPrices = prices;
                            });
                          },
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),

              // Botones de acción
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child:                   Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0F0F0F)
                        : Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade600
                                    : Colors.grey,
                              ),
                            ),
                            child: Text(
                              'Volver',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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

                              if (cantidadController.text.trim().isEmpty) {
                                AppTheme.showSnackBar(
                                  context,
                                  AppTheme.warningSnackBar('La cantidad es requerida'),
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

                              if (precioController.text.trim().isEmpty) {
                                AppTheme.showSnackBar(
                                  context,
                                  AppTheme.warningSnackBar('El precio es requerido'),
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

                              final selectedCategoria = categorias.firstWhere(
                                (c) => c.nombre == categoriaController.text,
                                orElse: () => categorias.first,
                              );
                              
                              final producto = Producto(
                                id: null,
                                nombre: nombreController.text.trim(),
                                cantidad: double.tryParse(cantidadController.text) ?? 0.0,
                                precio: double.tryParse(precioController.text) ?? 0.0,
                                categoriaId: selectedCategoria.id ?? 0,
                                half: halfController.text == 'true',
                                quantityPrices: quantityPrices,
                              );

                              // Debug: verificar qué se está enviando
                              debugPrint('=== NUEVO PRODUCTO ===');
                              debugPrint('Nombre: ${producto.nombre}');
                              debugPrint('Cantidad packs: ${quantityPrices.length}');
                              debugPrint('Packs: ${quantityPrices.map((qp) => 'Cant: ${qp.quantity}, Precio: ${qp.totalPrice}').toList()}');

                              try {
                                // Mostrar loading básico
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                    ),
                                  ),
                                );
                                
                                await Provider.of<ProductoProvider>(context,
                                        listen: false)
                                    .crearProducto(producto);
                                
                                if (!context.mounted) return;
                                
                                // Cerrar loading
                                Navigator.pop(context);
                                
                                AppTheme.showSnackBar(
                                  context,
                                  AppTheme.successSnackBar('Producto guardado con éxito'),
                                );
                                Navigator.pop(context, true); // Devolver true para indicar éxito
                              } catch (e) {
                                if (!context.mounted) return;
                                
                                // Cerrar loading
                                Navigator.pop(context);
                                
                                if (Apihandler.isConnectionError(e)) {
                                  await Apihandler.handleConnectionError(context, e);
                                } else {
                                  await AppDialogs.showErrorDialog(
                                    context: context,
                                    message: 'Error al crear producto: ${e.toString().replaceFirst('Exception: ', '')}',
                                  );
                                }
                              }
                            },
                            child: const Text('Guardar',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
