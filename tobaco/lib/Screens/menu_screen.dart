import 'package:flutter/material.dart';
import 'package:tobaco/Screens/Clientes/clientes_screen.dart';
import 'package:tobaco/Screens/Clientes/detalleCliente_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(    
      ),
      body: Center(
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
                      MaterialPageRoute(builder: (context) => const ClientesScreen()),
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
                  onPressed: () {Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>  DetalleClienteScreen.empty()),
                    );},
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
                backgroundColor:
                    const Color.fromRGBO(248, 207, 112, 1), // background color
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
                    backgroundColor: const Color.fromARGB(255, 3, 117, 39), // background color
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255), // text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    fixedSize: const Size(150, 150),
                    elevation: 10, // Altura de la sombra
                    shadowColor: Colors.black, // Color de la sombra
                  ),
                  onPressed: () {
                    
                  },
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
                    backgroundColor: const Color.fromARGB(255, 99, 99, 99), // background color
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
    );
  }
}
