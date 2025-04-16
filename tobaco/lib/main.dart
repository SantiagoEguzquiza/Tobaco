import 'package:flutter/material.dart';
import 'package:tobaco/Screens/menu_screen.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
//import 'package:tobaco/Services/Productos_Service/producto_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClienteProvider()), // Provider para clientes
        ChangeNotifierProvider(create: (_) => ProductoProvider()), // Provider para productos
      ],
      child: const MyApp(), // TE REDIRIGE A MENU SCREEN
    ),
  );
}

 