import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'dart:developer';

class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key});

  @override
  _DeudasScreenState createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  bool isLoading = true;
  String searchQuery = '';
  String? errorMessage;
  List<Cliente> clientes = [];
  final TextEditingController _searchController = TextEditingController();

   @override
  void initState() {
    super.initState();
    _loadClientes();
  }



  Future<void> _loadClientes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final clienteProvider = ClienteProvider();
      final List<Cliente> fetchedClientes =
          await clienteProvider.obtenerClientesConDeuda();

      setState(() {
        clientes = fetchedClientes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar los clientes: $e';
      });
      log('Error al cargar los clientes: $e', level: 1000);
    }
  }

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    
    //falta que funcione la barra de busqueda y que se ordenen los clientes por orden alfabetico

    return Scaffold(
      appBar: AppBar(
        title: Text('Clientes con Deuda'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar cliente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  color: index % 2 == 0
                      ? AppTheme.secondaryColor
                      : AppTheme.greyColor,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'Assets/images/tienda.png',
                            height: 30,
                          ),
                          const SizedBox(width: 25),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cliente.nombre,
                                  style: AppTheme.cardTitleStyle,
                                ),
                                Text(
                                  'Deuda: \$${cliente.deuda}',
                                  style: AppTheme.cardSubtitleStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
