import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:tobaco/Utils/thermal/ticket_builder.dart';
import 'package:tobaco/Models/Ventas.dart';

export 'package:blue_thermal_printer/blue_thermal_printer.dart'
    show BluetoothDevice;

class BluetoothPrinterService {
  static BluetoothPrinterService? _instance;
  static BluetoothPrinterService get instance =>
      _instance ??= BluetoothPrinterService._();

  BluetoothPrinterService._();

  final BlueThermalPrinter _bt = BlueThermalPrinter.instance;
  BluetoothDevice? _connectedDevice;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<bool> get isBluetoothOn async => (await _bt.isOn) ?? false;

  Future<bool> get isConnected async => (await _bt.isConnected) ?? false;

  /// Returns bonded (paired) Bluetooth devices.
  /// The printer must be paired from Android Bluetooth Settings first.
  Future<List<BluetoothDevice>> getBondedDevices() async {
    final on = await _bt.isOn;
    if (on != true) {
      throw Exception(
        'Bluetooth está desactivado. Por favor, activalo desde Ajustes.',
      );
    }

    try {
      return await _bt.getBondedDevices();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('permission') || msg.contains('security')) {
        throw Exception(
          'Permiso de Bluetooth denegado. '
          'Andá a Ajustes > Apps > Tobaco > Permisos y habilitá Bluetooth.',
        );
      }
      throw Exception('Error al obtener dispositivos emparejados: $e');
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_connectedDevice != null) {
      await disconnect();
    }

    try {
      await _bt.connect(device);
      _connectedDevice = device;
    } catch (e) {
      _connectedDevice = null;
      final msg = e.toString().toLowerCase();
      if (msg.contains('permission') || msg.contains('security')) {
        throw Exception(
          'Permiso de Bluetooth denegado. '
          'Andá a Ajustes > Apps > Tobaco > Permisos y habilitá Bluetooth.',
        );
      }
      throw Exception('Error al conectar con la impresora: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await _bt.disconnect();
    } catch (_) {}
    _connectedDevice = null;
  }

  Future<void> printTicket(Ventas venta) async {
    final connected = await isConnected;
    if (!connected) {
      _connectedDevice = null;
      throw Exception(
        'Impresora desconectada. Verificá que esté encendida y volvé a conectar.',
      );
    }

    try {
      final ticketData = TicketBuilder.buildTicket(venta);
      await _bt.writeBytes(ticketData);

      // Feed + partial cut (GS V A 0x00)
      await _bt.writeBytes(
        Uint8List.fromList([0x0A, 0x0A, 0x0A, 0x1D, 0x56, 0x41, 0x00]),
      );
    } catch (e) {
      throw Exception('Error al imprimir ticket: $e');
    }
  }
}
