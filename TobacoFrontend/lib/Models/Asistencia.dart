class Asistencia {
  final int id;
  final int userId;
  final String? userName;
  final DateTime fechaHoraEntrada;
  final DateTime? fechaHoraSalida;
  final String? ubicacionEntrada;
  final String? ubicacionSalida;
  final String? latitudEntrada;
  final String? longitudEntrada;
  final String? latitudSalida;
  final String? longitudSalida;
  final Duration? horasTrabajadas;

  Asistencia({
    required this.id,
    required this.userId,
    this.userName,
    required this.fechaHoraEntrada,
    this.fechaHoraSalida,
    this.ubicacionEntrada,
    this.ubicacionSalida,
    this.latitudEntrada,
    this.longitudEntrada,
    this.latitudSalida,
    this.longitudSalida,
    this.horasTrabajadas,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    Duration? horasTrabajadas;
    if (json['horasTrabajadas'] != null) {
      final parts = json['horasTrabajadas'].toString().split(':');
      if (parts.length >= 3) {
        horasTrabajadas = Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
          seconds: int.parse(parts[2].split('.')[0]),
        );
      }
    }

    return Asistencia(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      fechaHoraEntrada: DateTime.parse(json['fechaHoraEntrada']),
      fechaHoraSalida: json['fechaHoraSalida'] != null 
          ? DateTime.parse(json['fechaHoraSalida']) 
          : null,
      ubicacionEntrada: json['ubicacionEntrada'],
      ubicacionSalida: json['ubicacionSalida'],
      latitudEntrada: json['latitudEntrada'],
      longitudEntrada: json['longitudEntrada'],
      latitudSalida: json['latitudSalida'],
      longitudSalida: json['longitudSalida'],
      horasTrabajadas: horasTrabajadas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'fechaHoraEntrada': fechaHoraEntrada.toIso8601String(),
      'fechaHoraSalida': fechaHoraSalida?.toIso8601String(),
      'ubicacionEntrada': ubicacionEntrada,
      'ubicacionSalida': ubicacionSalida,
      'latitudEntrada': latitudEntrada,
      'longitudEntrada': longitudEntrada,
      'latitudSalida': latitudSalida,
      'longitudSalida': longitudSalida,
    };
  }

  bool get estaActiva => fechaHoraSalida == null;

  String get horasTrabajadasFormateadas {
    if (horasTrabajadas == null) return 'En progreso';
    final hours = horasTrabajadas!.inHours;
    final minutes = horasTrabajadas!.inMinutes.remainder(60);
    return '$hours h $minutes min';
  }
}

class RegistrarEntradaDTO {
  final int userId;
  final String? ubicacionEntrada;
  final String? latitudEntrada;
  final String? longitudEntrada;

  RegistrarEntradaDTO({
    required this.userId,
    this.ubicacionEntrada,
    this.latitudEntrada,
    this.longitudEntrada,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'ubicacionEntrada': ubicacionEntrada,
      'latitudEntrada': latitudEntrada,
      'longitudEntrada': longitudEntrada,
    };
  }
}

class RegistrarSalidaDTO {
  final int asistenciaId;
  final String? ubicacionSalida;
  final String? latitudSalida;
  final String? longitudSalida;

  RegistrarSalidaDTO({
    required this.asistenciaId,
    this.ubicacionSalida,
    this.latitudSalida,
    this.longitudSalida,
  });

  Map<String, dynamic> toJson() {
    return {
      'asistenciaId': asistenciaId,
      'ubicacionSalida': ubicacionSalida,
      'latitudSalida': latitudSalida,
      'longitudSalida': longitudSalida,
    };
  }
}

