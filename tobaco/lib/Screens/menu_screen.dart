import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Screens/Clientes/clientes_screen.dart';
import 'package:tobaco/Screens/Clientes/detalleCliente_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // Configuración global del tema
        scaffoldBackgroundColor: Colors.white, // Fondo de todas las pantallas
        primarySwatch: Colors.blue, // Color principal de la app.
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // Color del AppBar
          foregroundColor: Colors.black, // Color del texto en el AppBar
          elevation: 0, // Sin sombra en el AppBar
          titleTextStyle: TextStyle(
              fontFamily: 'Shippori', fontSize: 30, color: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Color de fondo de los botones
            foregroundColor: Colors.white, // Color del texto en los botones
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Bordes redondeados
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontFamily: 'LibreFranklin'), // Texto general
          bodyMedium: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontFamily: 'LibreFranklin'), // Texto secundario
        ),
        inputDecorationTheme: const InputDecorationTheme(
          // Configuración global para los TextField
          labelStyle: TextStyle(
            color: Colors.grey,
            fontSize: 15, // Color del label cuando no está enfocado
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.grey, // Color del label cuando está enfocado
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          prefixIconColor: Colors.grey, // Color del ícono
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
              color: Color.fromRGBO(200, 200, 200, 1), // Color del borde normal
              width: 1.0, // Grosor más delgado
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: 10, // Reduce la altura del TextField
            horizontal: 15, // Espaciado horizontal
          ),
        ),
      ),
      home: const MenuScreen(), // Pantalla inicial
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      body: SafeArea(
        child: Center(
          child: Column(
            
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(
                          125, 176, 242, 1), // background color
                      foregroundColor: Colors.black, // text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(150, 150),
                      elevation: 10, // Altura de la sombra
                      shadowColor: Colors.black, // Color de la sombra
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ClientesScreen()),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'Assets/images/clientes_icon.png', // Ruta de la imagen
                          height: 80, // Altura de la imagen
                          width: 80, // Ancho de la imagen
                        ),
                        const SizedBox(), // Espacio entre la imagen y el texto
                        const Text(
                          'Clientes',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(
                          246, 243, 141, 1), // background color
                      foregroundColor: Colors.black, // text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(150, 150),
                      elevation: 10, // Altura de la sombra
                      shadowColor: Colors.black, // Color de la sombra
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ClientesScreen()),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'Assets/images/cigarettes.png', // Ruta de la imagen
                          height: 80, // Altura de la imagen
                          width: 80, // Ancho de la imagen
                        ),
                        const SizedBox(
                          height: 5,
                        ), // Espacio entre la imagen y el texto
                        const Text(
                          'Productos',
                          style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(
                      248, 207, 112, 1), // background color
                  foregroundColor: Colors.black, // text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  fixedSize: const Size(320, 150),
                  elevation: 10, // Altura de la sombra
                  shadowColor: Colors.black, // Color de la sombra
                ),
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'Assets/images/files.png', // Ruta de la imagen
                      height: 80, // Altura de la imagen
                      width: 80, // Ancho de la imagen
                    ),
                    const SizedBox(
                        width: 10), // Espacio entre la imagen y el texto
                    const Text(
                      'Lista de pedidos',
                      style: TextStyle(
                        fontSize: 20,
                        //fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(
                      255, 153, 251, 152), // background color
                  foregroundColor: Colors.black, // text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  fixedSize: const Size(320, 150),
                  elevation: 10, // Altura de la sombra
                  shadowColor: Colors.black, // Color de la sombra
                ),
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'Assets/images/add_file.png', // Ruta de la imagen
                      height: 80, // Altura de la imagen
                      width: 80, // Ancho de la imagen
                    ),
                    const SizedBox(
                        width: 10), // Espacio entre la imagen y el texto
                    const Text(
                      'Crear nuevo pedido',
                      style: TextStyle(
                        fontSize: 20,
                        //fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 3, 117, 39), // background color
                      foregroundColor: const Color.fromARGB(
                          255, 255, 255, 255), // text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      fixedSize: const Size(150, 150),
                      elevation: 10, // Altura de la sombra
                      shadowColor: Colors.black, // Color de la sombra
                    ),
                    onPressed: () {},
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image.asset(
                        //   'Assets/images/clientes_icon.png', // Ruta de la imagen
                        //   height: 80, // Altura de la imagen
                        //   width: 80, // Ancho de la imagen
                        // ),
                        SizedBox(), // Espacio entre la imagen y el texto
                        Text(
                          'DOLAR',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 99, 99, 99), // background color
                      foregroundColor: Colors.white, // text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      fixedSize: const Size(150, 150),
                      elevation: 10, // Altura de la sombra
                      shadowColor: Colors.black, // Color de la sombra
                    ),
                    onPressed: () {},
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image.asset(
                        //   'Assets/images/cigarettes.png', // Ruta de la imagen
                        //   height: 80, // Altura de la imagen
                        //   width: 80, // Ancho de la imagen
                        // ),
                        SizedBox(
                          height: 5,
                        ), // Espacio entre la imagen y el texto
                        Text(
                          'Configuración',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
