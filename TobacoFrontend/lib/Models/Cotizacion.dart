class Cotizacion {
  final String? fecha;      // YYYY-MM-DD
  final int? moneda;
  final String? nombre;
  final String? codigoIso;
  final double? tcc;        // compra
  final double? tcv;        // venta

  Cotizacion({this.fecha, this.moneda, this.nombre, this.codigoIso, this.tcc, this.tcv});
}
