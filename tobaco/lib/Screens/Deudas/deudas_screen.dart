import 'package:flutter/material.dart';
import 'package:tobaco/Theme/app_theme.dart';

class DeudasScreen extends StatefulWidget {
  @override
  _DeudasScreenState createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _clientes = [
    {'nombre': 'Juan Pérez', 'deuda': 1200.0},
    {'nombre': 'Ana Gómez', 'deuda': 800.0},
    {'nombre': 'Carlos Ruiz', 'deuda': 500.0},
    {'nombre': 'Lucía Fernández', 'deuda': 1500.0},
  ];

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final filteredClientes = _clientes.where((cliente) {
      return cliente['nombre']
          .toLowerCase()
          .contains(_searchText.toLowerCase());
    }).toList();

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
              itemCount: filteredClientes.length,
              itemBuilder: (context, index) {
                final cliente = filteredClientes[index];
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
                                  cliente['nombre'],
                                  style: AppTheme.cardTitleStyle,
                                ),
                                Text(
                                  'Deuda: \$${cliente['deuda']}',
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
