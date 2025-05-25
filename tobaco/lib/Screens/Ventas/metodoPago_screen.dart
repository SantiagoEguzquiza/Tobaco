import 'package:flutter/material.dart';

class FormaPagoScreen extends StatefulWidget {
  final double total;

  const FormaPagoScreen({super.key, required this.total});

  @override
  State<FormaPagoScreen> createState() => _FormaPagoScreenState();
}

class _FormaPagoScreenState extends State<FormaPagoScreen> {
  String? metodoSeleccionado;

  final List<_MetodoPago> metodos = [
    _MetodoPago('Efectivo', Icons.payments),
    _MetodoPago('Transferencia', Icons.swap_horiz),
    _MetodoPago('Tarjeta', Icons.credit_card),
    _MetodoPago('Cuenta corriente', Icons.receipt_long),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forma de pago'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...metodos.map((metodo) => _buildMetodoPagoTile(metodo)).toList(),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${widget.total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: metodoSeleccionado != null
                      ? () {
                          // Podés devolver el método seleccionado o ir a pantalla resumen
                          Navigator.pop(context, metodoSeleccionado);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetodoPagoTile(_MetodoPago metodo) {
    return GestureDetector(
      onTap: () {
        setState(() {
          metodoSeleccionado = metodo.nombre;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
              color: metodoSeleccionado == metodo.nombre
                  ? Colors.green
                  : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(metodo.icono, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                metodo.nombre,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (metodoSeleccionado == metodo.nombre)
              const Icon(Icons.check_circle, color: Colors.green)
          ],
        ),
      ),
    );
  }
}

class _MetodoPago {
  final String nombre;
  final IconData icono;

  _MetodoPago(this.nombre, this.icono);
}
