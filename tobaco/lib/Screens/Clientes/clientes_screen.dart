// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final List<String> clientes = [
    'Bella Union',
    'Alicia',
    'Pedro',
    'Maria',
    'Juan',
    'Carlos',
    'Ana',
    'Luis',
    'Sofia',
    'Miguel',
  ];
  String searchQuery = ''; 

  @override
  Widget build(BuildContext context) {
    final filteredClientes = clientes
        .where((cliente) =>
            cliente.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Clientes',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromRGBO(168, 245, 172, 1), // background color
                foregroundColor: Colors.black, // text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fixedSize: const Size(376, 75),
                elevation: 10, // Altura de la sombra
                shadowColor: Colors.black, // Color de la sombra
              ),
              onPressed:
                  () {}, // Agregar la ruta de la pantalla de agregar cliente
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Agregar nuevo cliente',
                    style: TextStyle(
                      fontSize: 20,
                      
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            TextField(
              cursorColor: Colors.black, // Cambia el color del cursor a negro
              decoration: const InputDecoration(
              labelText: 'Buscar cliente...',
              labelStyle: TextStyle(
                color: Colors.grey, // Color del label cuando no está enfocado
              ),
              floatingLabelStyle: TextStyle(
                color: Colors.grey, // Color del label cuando está enfocado
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              prefixIcon:
                Icon(Icons.search, color: Colors.grey), // Color del ícono
              filled: true, // Habilitar fondo
              fillColor: Color.fromRGBO(255, 255, 255, 1), // Fondo gris claro
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide(
                color: Color.fromRGBO(
                  200, 200, 200, 1), // Color del borde al enfocar
                width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide(
                color: Color.fromRGBO(
                  200, 200, 200, 1), // Color del borde normal
                width: 1.5,
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
            const SizedBox(height: 35),
            Expanded(
              child: ListView.builder(
                itemCount: filteredClientes.length,
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    color: index % 2 == 0
                        ? const Color.fromARGB(
                            255, 255, 255, 255) // Gris claro para impares
                        : const Color.fromARGB(
                            255, 240, 240, 240), // Verde claro para pares                   
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Icono del cliente
                          const Icon(
                            Icons.person, // Icono de cliente
                            size: 30,
                            color: Colors.blue,
                          ),
                            // Nombre del cliente
                            const SizedBox(width: 25), // Espaciado adicional
                            Expanded(
                            child: Text(
                              filteredClientes[index],
                              style: const TextStyle(
                              fontSize: 18,
                              ),
                              textAlign: TextAlign.left,
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
                              print(
                                  'Editar cliente: ${filteredClientes[index]}');
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
                              print(
                                  'Eliminar cliente: ${filteredClientes[index]}');
                            },
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
