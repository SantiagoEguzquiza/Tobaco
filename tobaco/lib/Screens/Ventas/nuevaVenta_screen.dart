import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Screens/Ventas/seleccionarProducto_screen.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Theme/confirmAnimation.dart';

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  Cliente? clienteSeleccionado;
  final TextEditingController _searchController = TextEditingController();
  List<Cliente> clientesFiltrados = [];
  bool isSearching = true;
  List<ProductoSeleccionado> productosSeleccionados = [];

  void buscarClientes(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      setState(() {
        clientesFiltrados =
            []; // o poné clientes completos si querés sugerencias por defecto
      });
      return;
    }

    try {
      final clientes = await ClienteProvider().buscarClientes(trimmedQuery);
      setState(() {
        clientesFiltrados = clientes;
      });
    } catch (e) {
      debugPrint('Error al buscar clientes: $e');
      setState(() {
        clientesFiltrados = [];
      });
    }
  }

  void seleccionarCliente(Cliente cliente) {
    setState(() {
      clienteSeleccionado = cliente;
      isSearching = false;
    });
  }

  void cambiarCliente() {
    setState(() {
      clientesFiltrados = []; // Limpiar la lista de clientes filtrados
      clienteSeleccionado = null;
      isSearching = true;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Nueva Venta', style: AppTheme.appBarTitleStyle),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. Sección de selección de cliente
              if (isSearching) ...[
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar cliente',
                    prefixIcon: Icon(Icons.search),
                  ),
                  cursorColor: Colors.black,
                  onChanged: buscarClientes,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    itemCount: clientesFiltrados.length.clamp(0, 3),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final cliente = clientesFiltrados[index];
                      return Container(
                        color: index % 2 == 0
                            ? AppTheme.secondaryColor
                            : AppTheme.greyColor,
                        child: ListTile(
                          title: Text(cliente.nombre),
                          onTap: () => seleccionarCliente(cliente),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Card(
                  margin: EdgeInsets.symmetric(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(15),
                        child: Row(
                          children: [
                            Image.asset('Assets/images/tienda.png', height: 24),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                clienteSeleccionado!.nombre,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Image.asset(
                                'Assets/images/editar.png',
                                height: 24,
                              ),
                              onPressed: () {
                                cambiarCliente();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeleccionarProductosScreen(
                            productosYaSeleccionados: productosSeleccionados,
                          ),
                        ),
                      );

                      if (resultado != null &&
                          resultado is List<ProductoSeleccionado>) {
                        setState(() {
                          productosSeleccionados = resultado;
                        });
                      }
                    },
                    style: AppTheme.elevatedButtonStyle(
                        AppTheme.addGreenColor), // Usa el estilo del tema
                    child: const Text(
                      'Agregar productos',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                if (productosSeleccionados.isNotEmpty)
                  const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: productosSeleccionados.length,
                    itemBuilder: (context, index) {
                      final ps = productosSeleccionados[index];

                      return Slidable(
                        key: ValueKey(ps.producto.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            if (ps.producto.half)
                              SlidableAction(
                                autoClose: false,
                                onPressed: (_) {
                                  setState(() {
                                    ps.cantidad = (ps.cantidad % 1 == 0
                                            ? ps.cantidad + 0.5
                                            : ps.cantidad - 0.5)
                                        .clamp(0.5, double.infinity);
                                  });
                                },
                                icon: Icons.contrast,
                                backgroundColor: Colors.blueGrey,
                                label: '½',
                              ),
                            SlidableAction(
                              autoClose: false,
                              onPressed: (_) {
                                setState(() {
                                  ps.cantidad = (ps.cantidad - 1)
                                      .clamp(0.5, double.infinity);
                                });
                              },
                              backgroundColor: Colors.red,
                              icon: Icons.remove_circle,
                              label: '-',
                            ),
                            SlidableAction(
                              autoClose: false,
                              onPressed: (_) {
                                setState(() {
                                  ps.cantidad += 1;
                                });
                              },
                              backgroundColor: Colors.green,
                              icon: Icons.add_circle,
                              label: '+',
                            ),
                          ],
                        ),
                        child: Container(
                          color: index % 2 == 0
                              ? AppTheme.secondaryColor
                              : const Color.fromARGB(255, 255, 255, 255),
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Text(
                                  ps.producto.nombre,
                                  style: AppTheme.itemListaNegrita,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${ps.cantidad % 1 == 0 ? ps.cantidad.toInt() : ps.cantidad}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '\$ ${(ps.producto.precio * ps.cantidad).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}',
                                  style: AppTheme.itemListaPrecio,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: productosSeleccionados.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, bottom: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total: \$ ${productosSeleccionados.fold(0.0, (sum, ps) => sum + (ps.producto.precio * ps.cantidad)).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AppTheme.confirmDialogStyle(
                                  title: 'Confirmar Venta',
                                  content:
                                      '¿Está seguro de que desea finalizar la venta?',
                                  onConfirm: () =>
                                      Navigator.of(context).pop(true),
                                  onCancel: () =>
                                      Navigator.of(context).pop(false),
                                );
                              },
                            );

                            if (confirmar != true) return;

                            final productos = productosSeleccionados
                                .map((ps) => VentasProductos(
                                      productoId: ps.producto.id!,
                                      producto: ps.producto,
                                      cantidad: ps.cantidad,
                                    ))
                                .toList();

                            final venta = Ventas(
                              clienteId: clienteSeleccionado!.id!,
                              cliente: clienteSeleccionado!,
                              ventasProductos: productos,
                              total: productosSeleccionados.fold(
                                  0.0,
                                  (sum, ps) =>
                                      sum + (ps.producto.precio * ps.cantidad)),
                              fecha: DateTime.now(),
                            );

                            try {
                              await VentasProvider().crearVenta(venta);

                              // ✅ Mostrar animación y luego redirigir
                              // showGeneralDialog(
                              //   context: context,
                              //   barrierDismissible: false,
                              //   barrierColor: Colors.transparent,
                              //   transitionDuration:
                              //       const Duration(milliseconds: 0),
                              //   pageBuilder:
                              //       (context, animation, secondaryAnimation) {
                              //     return AnnotatedRegion<SystemUiOverlayStyle>(
                              //       value: SystemUiOverlayStyle.light.copyWith(
                              //         statusBarColor: Colors.green,
                              //         systemNavigationBarColor: Colors.green,
                              //       ),
                              //       child: Scaffold(
                              //         backgroundColor: Colors.transparent,
                              //         body: VentaConfirmadaAnimacion(
                              //           onFinish: () {
                              //             Navigator.of(context)
                              //                 .pop(); // cerrar animación
                              //             Navigator.of(context)
                              //                 .pop(); // volver atrás
                              //           },
                              //         ),
                              //       ),
                              //     );
                              //   },
                              // );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          style: AppTheme.elevatedButtonStyle(
                              AppTheme.addGreenColor),
                          child: const Text(
                            'Confirmar',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null);
  }
}
