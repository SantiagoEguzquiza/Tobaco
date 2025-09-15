import 'package:flutter/material.dart';
import 'package:tobaco/Screens/menu_screen.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_provider.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_repo.dart';

import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';




void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => CategoriasProvider()),
        ChangeNotifierProvider(create: (_) => VentasProvider()),
        // 1) Repo primero
        Provider(create: (_) => BcuRepository()),
        // 2) Provider que depende del repo
        ChangeNotifierProvider(
          create: (ctx) => BcuProvider(ctx.read<BcuRepository>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}


 