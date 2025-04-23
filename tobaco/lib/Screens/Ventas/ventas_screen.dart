// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
   
   _PedidosScreenState createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  @override
  Widget build(BuildContext context) {
    final List<String> pedidos = [
      'Pedido 1',
      'Pedido 2',
      'Pedido 3',
      'Pedido 4',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Pedidos'),
      ),
      body: ListView.builder(
        itemCount: pedidos.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(pedidos[index]),
              leading: Icon(Icons.shopping_cart),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
               
              },
            ),
          );
        },
      ),
    );
  }
}