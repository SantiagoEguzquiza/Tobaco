// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Screens/Clientes/detalleCliente_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final List<Cliente> clientes = [
    Cliente(
      id: 1,
      nombre: 'Bella Union',
      direccion: 'Calle Principal 123',
      telefono: 123456789,
      deuda: 200,
    ),
    Cliente(
      id: 2,
      nombre: 'Alicia',
      direccion: 'Av. Libertad 456',
      telefono: 987654321,
      deuda: 150,
    ),
    Cliente(
      id: 3,
      nombre: 'Pedro',
      direccion: 'Calle Secundaria 789',
      telefono: 456789123,
      deuda: 300,
    ),
    Cliente(
      id: 4,
      nombre: 'Maria',
      direccion: 'Av. Siempre Viva 101',
      telefono: 321654987,
      deuda: 50,
    ),
    Cliente(
      id: 5,
      nombre: 'Juan',
      direccion: 'Calle Falsa 102',
      telefono: 741852963,
      deuda: 0,
    ),
    Cliente(
      id: 6,
      nombre: 'Carlos',
      direccion: 'Av. Central 103',
      telefono: 963852741,
      deuda: 400,
    ),
    Cliente(
      id: 7,
      nombre: 'Ana',
      direccion: 'La Paz 123',
      telefono: 123456789,
      deuda: 100,
    ),
    Cliente(
      id: 8,
      nombre: 'Luis',
      direccion: 'Calle Norte 104',
      telefono: 852741963,
      deuda: 250,
    ),
    Cliente(
      id: 9,
      nombre: 'Sofia',
      direccion: 'Av. Sur 105',
      telefono: 159753486,
      deuda: 75,
    ),
    Cliente(
      id: 10,
      nombre: 'Miguel',
      direccion: 'Calle Este 106',
      telefono: 357951486,
      deuda: 500,
    ),
  ];

  String searchQuery = '';

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
              width: double.infinity, // Botón ocupa todo el ancho
              child: ElevatedButton(
                onPressed: () {
                  // Acción para crear nuevo cliente
                  print('Crear nuevo cliente');
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
                    margin:
                        const EdgeInsets.symmetric(vertical: 6),
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
                            const Icon(
                              Icons.person, // Icono de cliente
                              size: 30,
                              color: Colors.blue,
                            ),
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
                            // Botón para editar cliente
                            IconButton(
                              icon: const Icon(
                                Icons.edit, // Icono de editar
                                color: Colors.green,
                              ),
                              onPressed: () {
                                // Acción para editar cliente
                                print('Editar cliente: ${cliente.nombre}');
                              },
                            ),
                            // Botón para eliminar cliente
                            IconButton(
                              icon: const Icon(
                                Icons.delete, // Icono de eliminar
                                color: Colors.red,
                              ),
                              onPressed: () {
                                // Acción para eliminar cliente
                                print('Eliminar cliente: ${cliente.nombre}');
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
