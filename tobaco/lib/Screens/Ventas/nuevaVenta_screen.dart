import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Screens/Ventas/seleccionarProducto_screen.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';

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
      print('Error al buscar clientes: $e');
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
                    return ListTile(
                      title: Text(cliente.nombre),
                      onTap: () => seleccionarCliente(cliente),
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

              if (productosSeleccionados.isNotEmpty) const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: productosSeleccionados.length,
                  itemBuilder: (context, index) {
                    final ps = productosSeleccionados[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      color: index % 2 == 0
                          ? AppTheme.secondaryColor // Verde para impares
                          : AppTheme.greyColor, // Gris claro para pares
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ps.producto.nombre,
                                    style: AppTheme.cardTitleStyle, // Usa el tema
                                  ),
                                  Text(
                                    '\$${(ps.producto.precio * ps.cantidad).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}',
                                    style: AppTheme.cardTitleStyle, // Usa el tema
                                  ),
                                ],
                              ),
                            ),

                            


                            IconButton(
                              icon: Image.asset(
                                'Assets/images/borrar.png',
                                height: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  productosSeleccionados.removeAt(index);
                                });
                              },
                            ),
                            
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 2. Continúa con el formulario de la venta
            ],
          ],
        ),
      ),
    );
  }
}
