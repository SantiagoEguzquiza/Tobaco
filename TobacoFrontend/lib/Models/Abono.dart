class Abono {
  int? id;
  int clienteId;
  String clienteNombre;
  String monto;
  DateTime fecha;
  String nota;

  Abono({
    this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.monto,
    required this.fecha,
    required this.nota,
  });

  factory Abono.fromJson(Map<String, dynamic> json) => Abono(
        id: json['id'],
        clienteId: json['clienteId'] ?? 0,
        clienteNombre: json['clienteNombre'] ?? '',
        monto: json['monto'] ?? '0',
        fecha: DateTime.parse(json['fecha']),
        nota: json['nota'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
        'nota': nota,
      };
}
