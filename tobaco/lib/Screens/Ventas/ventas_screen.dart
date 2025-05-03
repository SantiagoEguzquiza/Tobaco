// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Screens/Ventas/nuevaVenta_screen.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  _VentasScreenState createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  bool isLoading = true;
  String searchQuery = '';
  String? errorMessage;
  List<Ventas> ventas = [];
  late ScaffoldMessengerState scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void initState() {
    super.initState();
    _loadVentas();
  }

  Future<void> _loadVentas() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final ventasProvider = VentasProvider();
      final List<Ventas> fetchedVentas = await ventasProvider.obtenerVentas();
      if (!mounted) return;
      setState(() {
        ventas = fetchedVentas;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar los pedidos: $e';
      });
      debugPrint('Error al cargar los pedidos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Ventas', style: AppTheme.appBarTitleStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NuevaVentaScreen(),
                    ),
                  );
                  _loadVentas();
                },
                style: AppTheme.elevatedButtonStyle(AppTheme.addGreenColor),
                child: const Text(
                  'Nueva venta',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              cursorColor: Colors.black,
              style: const TextStyle(fontSize: 15),
              decoration: AppTheme.searchInputDecoration,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: ventas.where((venta) {
                  final clienteNombre = venta.cliente.nombre.toLowerCase();
                  final fecha = '${venta.fecha.day}/${venta.fecha.month}';
                  final total = venta.total.toString();
                  return clienteNombre.contains(searchQuery) ||
                      fecha.contains(searchQuery) ||
                      total.contains(searchQuery);
                }).length,
                itemBuilder: (context, index) {
                  final filteredVentas = ventas.where((venta) {
                    final clienteNombre = venta.cliente.nombre.toLowerCase();
                    final fecha = '${venta.fecha.day}/${venta.fecha.month}';
                    final total = venta.total.toString();
                    return clienteNombre.contains(searchQuery) ||
                        fecha.contains(searchQuery) ||
                        total.contains(searchQuery);
                  }).toList();
                  final venta = filteredVentas[index];

                  return Slidable(
                    key: Key(venta.id.toString()),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirmar eliminación'),
                                  content: const Text(
                                      '¿Estás seguro de que deseas eliminar esta venta?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              try {
                                final ventasProvider = VentasProvider();
                                await ventasProvider
                                    .eliminarVenta(venta.id ?? 0);

                                if (!mounted) return;

                                setState(() {
                                  ventas.remove(venta);
                                });

                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Venta eliminada'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;

                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Error al eliminar venta: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Eliminar',
                        ),
                      ],
                    ),
                    child: Container(
                      color: index % 2 == 0
                          ? AppTheme.secondaryColor
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${venta.fecha.day}/${venta.fecha.month}',
                              style: AppTheme.cardTitleStyle,
                            ),
                            
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              venta.cliente.nombre,
                              style: AppTheme.cardTitleStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '\$ ${venta.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}',
                              style: AppTheme.cardTitleStyle,
                              textAlign: TextAlign.end,
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
        ),
      ),
    );
  }
}
