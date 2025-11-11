import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:tobaco/Utils/thermal/ticket_builder.dart';
import 'package:tobaco/Models/Ventas.dart';

class BluetoothPrinterService {
  static BluetoothPrinterService? _instance;
  static BluetoothPrinterService get instance =>
      _instance ??= BluetoothPrinterService._();

  BluetoothPrinterService._();

  BluetoothDevice? _connectedDevice;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<List<BluetoothDevice>> scanForPrinters(
      {Duration timeout = const Duration(seconds: 2)}) async {
    try {
      // Verificar que Bluetooth esté habilitado
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth no está soportado en este dispositivo');
      }

      if (await FlutterBluePlus.isOn == false) {
        throw Exception('Bluetooth está desactivado. Por favor, actívalo');
      }

      // Limpiar dispositivos escaneados anteriormente
      await FlutterBluePlus.stopScan();
      await Future.delayed(const Duration(milliseconds: 500));

      // Iniciar escaneo con timeout
      FlutterBluePlus.startScan(timeout: timeout);

      // Recopilar todos los resultados
      List<BluetoothDevice> printers = [];
      Set<String> seenIds = {};
      StreamSubscription? subscription;

      // Suscribirse a los resultados del escaneo
      subscription = FlutterBluePlus.scanResults.listen((scanResults) {
        for (var result in scanResults) {
          final device = result.device;
          final deviceId = device.remoteId.toString();

          // Evitar duplicados
          if (seenIds.contains(deviceId)) {
            continue;
          }
          seenIds.add(deviceId);

          // Debug: mostrar nombres de dispositivos encontrados
          print(
              'Dispositivo Bluetooth encontrado: ${device.name}, ID: $deviceId');

          if (_looksLikePrinter(result)) {
            printers.add(device);
          } else {
            print('Descartado (no parece impresora): ${device.name}');
          }
        }
      });

      // Esperar hasta que el escaneo termine
      await Future.delayed(timeout);

      // Cancelar suscripción
      await subscription.cancel();

      // Detener el escaneo manualmente
      await FlutterBluePlus.stopScan();

      return printers;
    } catch (e) {
      throw Exception('Error al escanear impresoras: $e');
    }
  }

  bool _looksLikePrinter(ScanResult result) {
    final name = result.device.platformName.toLowerCase();
    const printerNameKeywords = [
      'printer',
      'print',
      'pos',
      'thermal',
      'rpp',
      'bt-sp',
      'gprinter',
      'gp',
      'escpos',
      'qs-58',
    ];
    if (printerNameKeywords.any((keyword) => name.contains(keyword))) {
      return true;
    }

    const printerServiceIds = [
      'FFE0',
      'FFE1',
      'FFE5',
      '18F0',
      '1812', // HID over GATT often used by printers
    ];

    final serviceUuids = result.advertisementData.serviceUuids
        .map((uuid) => uuid.toString().toUpperCase())
        .toList();
    if (serviceUuids.any(
        (uuid) => printerServiceIds.any((id) => uuid.contains(id)))) {
      return true;
    }

    final serviceDataKeys = result.advertisementData.serviceData.keys
        .map((uuid) => uuid.toString().toUpperCase())
        .toList();
    if (serviceDataKeys.any(
        (uuid) => printerServiceIds.any((id) => uuid.contains(id)))) {
      return true;
    }

    return false;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Desconectar si hay una conexión previa
      if (_connectedDevice != null && _connectedDevice != device) {
        await disconnect();
      }

      _connectedDevice = device;

      // Conectar al dispositivo (flutter_blue_plus v2 requiere 'license')
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
      );

      // Esperar a que la conexión se establezca completamente
      await Future.delayed(const Duration(milliseconds: 500));

      if (!device.isConnected) {
        throw Exception('No se pudo establecer la conexión con la impresora');
      }
    } catch (e) {
      _connectedDevice = null;
      throw Exception('Error al conectar con la impresora: $e');
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        // Ignorar errores al desconectar
      }
      _connectedDevice = null;
    }
  }

  Future<void> printTicket(Ventas venta) async {
    if (_connectedDevice == null || !_connectedDevice!.isConnected) {
      throw Exception('No hay una impresora conectada');
    }

    try {
      // Buscar el servicio y característica para imprimir
      List<BluetoothService> services =
          await _connectedDevice!.discoverServices();

      BluetoothService? printService;
      BluetoothCharacteristic? printCharacteristic;

      // Buscar el servicio de impresión (SPS)
      for (var service in services) {
        if (service.uuid.toString().toUpperCase().contains('0000FFE0') ||
            service.uuid.toString().toUpperCase().contains('18F0')) {
          printService = service;
          break;
        }
      }

      // Si no encontramos el servicio específico, usar el primer servicio
      if (printService == null && services.isNotEmpty) {
        printService = services.first;
      }

      if (printService == null) {
        throw Exception('No se pudo encontrar el servicio de impresión');
      }

      // Buscar la característica de escritura (WRITE)
      for (var char in printService.characteristics) {
        if (char.properties.write || char.properties.writeWithoutResponse) {
          printCharacteristic = char;
          break;
        }
      }

      if (printCharacteristic == null) {
        throw Exception('No se pudo encontrar la característica de impresión');
      }

      // Generar el ticket
      final ticketData = TicketBuilder.buildTicket(venta);

      // Enviar el ticket en chunks si es muy grande
      const chunkSize = 20;
      for (int i = 0; i < ticketData.length; i += chunkSize) {
        final end = (i + chunkSize < ticketData.length)
            ? i + chunkSize
            : ticketData.length;
        final chunk = Uint8List.fromList(ticketData.sublist(i, end));

        if (printCharacteristic.properties.writeWithoutResponse) {
          await printCharacteristic.write(chunk, withoutResponse: true);
        } else {
          await printCharacteristic.write(chunk, withoutResponse: false);
        }

        // Pequeña pausa para evitar saturar el buffer
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Agregar comandos finales de corte (opcional)
      final finalCommands =
          Uint8List.fromList([0x0A, 0x0A, 0x0A, 0x1D, 0x56, 0x41, 0x00]);
      if (printCharacteristic.properties.writeWithoutResponse) {
        await printCharacteristic.write(finalCommands, withoutResponse: true);
      } else {
        await printCharacteristic.write(finalCommands, withoutResponse: false);
      }
    } catch (e) {
      throw Exception('Error al imprimir ticket: $e');
    }
  }

  bool get isConnected => _connectedDevice?.isConnected ?? false;
}
