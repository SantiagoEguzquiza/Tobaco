import 'package:tobaco/Models/metodoPago.dart';

class VentaPago {
  int id;
  int ventaId;
  MetodoPago metodo;
  double monto;

  VentaPago({
    required this.id,
    required this.ventaId,
    required this.metodo,
    required this.monto,
  });

  factory VentaPago.fromJson(Map<String, dynamic> j) => VentaPago(
        id: j['id'] as int,
        ventaId: j['ventaId'] as int,
        metodo: MetodoPago.values[j['metodo'] as int],
        monto: (j['monto'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ventaId': ventaId,
        'metodo': metodo.index,
        'monto': monto,
      };
}
