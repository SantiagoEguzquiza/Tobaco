// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Screens/Clientes/detalleCliente_screen.dart';
import 'package:tobaco/Screens/Clientes/editarCliente_Screen.dart';
import 'package:tobaco/Screens/Clientes/nuevoCliente_screen.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_service.dart';
import 'dart:developer';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  bool isLoading = true;
  String searchQuery = '';
  String? errorMessage;
  List<Cliente> clientes = [];

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
      final List<Cliente> fetchedClientes =
          await ClienteService().obtenerClientes();

      setState(() {
        clientes = fetchedClientes; // Actualiza la lista de clientes
        isLoading = false; // Finaliza la carga
      });
      log('Clientes cargados exitosamente');
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar los clientes: $e';
      });
      log('Error al cargar los clientes: $e', level: 1000);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClientes = clientes
        .where((cliente) =>
            cliente.nombre.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList()
      ..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Clientes',
          style: TextStyle(fontSize: 32),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity, // Ancho completo
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NuevoClienteScreen(),
                  ),
                  );
                  _loadClientes(); 
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  backgroundColor: const Color(0xFFAAEDAA), // Color de fondo
                  elevation: 5, // Altura de la sombra
                  shadowColor: Colors.black, // Color de la sombra
                ),
                child: const Text(
                  'Crear nuevo cliente',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              cursorColor: Colors.black, // Cambia el color del cursor a negro
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                labelText: 'Buscar cliente...',
                labelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 15 // Color del label cuando no está enfocado
                    ),
                floatingLabelStyle: TextStyle(
                  color: Colors.grey, // Color del label cuando está enfocado
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 15, // Tamaño del ícono
                ),
                filled: true, // Habilitar fondo
                fillColor: Color.fromRGBO(255, 255, 255, 1), // Fondo gris claro
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  borderSide: BorderSide(
                    color: Color.fromRGBO(
                        200, 200, 200, 1), // Color del borde al enfocar
                    width: 1.0, // Grosor más delgado
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  borderSide: BorderSide(
                    color: Color.fromRGBO(
                        200, 200, 200, 1), // Color del borde normal
                    width: 1.0, // Grosor más delgado
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10, // Reduce la altura del TextField
                  horizontal: 15, // Espaciado horizontal
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: filteredClientes.length,
                itemBuilder: (context, index) {
                  final cliente = filteredClientes[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    color: index % 2 == 0
                        ? const Color(0xFFE9F3EF) // verde para impares
                        : const Color(0xFFDBDBDB), // Gris claro para pares
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetalleClienteScreen(cliente: cliente),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Icono del cliente
                            Image.asset('Assets/images/tienda.png',
                            height: 30, // Altura del icono
                            ), // Ruta del icono en assets
                            const SizedBox(width: 25), // Espaciado adicional
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cliente.nombre,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Deuda: \$${cliente.deuda}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Botón para eliminar cliente
                             IconButton(
                              icon:  Image.asset(
                              'Assets/images/borrar.png', // Ruta del icono en assets
                              height: 24, // Altura del icono
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar cliente'),
                                    content: const Text(
                                        '¿Estás seguro de que deseas eliminar este cliente?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await ClienteProvider()
                                              .eliminarCliente(cliente.id!);
                                          _loadClientes(); // Recargar clientes
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Botón para editar cliente
                            IconButton(
                              icon: Image.asset(
                              'Assets/images/editar.png', // Ruta del icono en assets
                              height: 24, // Altura del icono
                              ),
                              onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                builder: (context) => EditarClienteScreen(
                                  cliente: cliente,
                                ),
                                ),
                              );
                              _loadClientes(); // Recargar clientes al volver
                              },
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
      ),
    );
  }
}
