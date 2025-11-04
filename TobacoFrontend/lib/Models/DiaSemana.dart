enum DiaSemana {
  domingo(0), // El backend tiene Domingo = 0
  lunes(1),
  martes(2),
  miercoles(3),
  jueves(4),
  viernes(5),
  sabado(6);

  final int value;
  const DiaSemana(this.value);

  factory DiaSemana.fromJson(dynamic json) {
    // Handle both int and String values
    int intValue;
    if (json is int) {
      intValue = json;
    } else if (json is String) {
      intValue = int.tryParse(json) ?? 0; // Default to domingo if parsing fails
    } else {
      intValue = 0; // Default to domingo
    }
    return DiaSemana.values.firstWhere(
      (e) => e.value == intValue,
      orElse: () => DiaSemana.domingo, // Default to domingo if not found
    );
  }
  int toJson() => value;

  String get nombre {
    switch (this) {
      case DiaSemana.domingo:
        return 'Domingo';
      case DiaSemana.lunes:
        return 'Lunes';
      case DiaSemana.martes:
        return 'Martes';
      case DiaSemana.miercoles:
        return 'Miércoles';
      case DiaSemana.jueves:
        return 'Jueves';
      case DiaSemana.viernes:
        return 'Viernes';
      case DiaSemana.sabado:
        return 'Sábado';
    }
  }

  String get nombreCorto {
    switch (this) {
      case DiaSemana.domingo:
        return 'Dom';
      case DiaSemana.lunes:
        return 'Lun';
      case DiaSemana.martes:
        return 'Mar';
      case DiaSemana.miercoles:
        return 'Mié';
      case DiaSemana.jueves:
        return 'Jue';
      case DiaSemana.viernes:
        return 'Vie';
      case DiaSemana.sabado:
        return 'Sáb';
    }
  }
}

