import 'package:tobaco/Models/metodoPago.dart';

class VentaPago {
  int id;
  int pedidoId;
  MetodoPago metodo;
  double monto;

  VentaPago({
    required this.id,
    required this.pedidoId,
    required this.metodo,
    required this.monto,
  });

  factory VentaPago.fromJson(Map<String, dynamic> j) => VentaPago(
        id: j['id'] as int,
        pedidoId: j['pedidoId'] as int,
        metodo: MetodoPago.values[j['metodo'] as int],
        monto: (j['monto'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pedidoId': pedidoId,
        'metodo': metodo.index,
        'monto': monto,
      };
}
