// ignore_for_file: file_names

class Cliente {
  int id;
  String nombre;
  String? direccion;
  int? telefono;
  String? whatsapp;

  Cliente(
      {required this.id,
      required this.nombre,
      required this.direccion,
      this.telefono,
      this.whatsapp});
}
