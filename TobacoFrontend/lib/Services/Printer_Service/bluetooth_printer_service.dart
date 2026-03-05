import 'dart:async';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:tobaco/Utils/thermal/ticket_builder.dart';
import 'package:tobaco/Models/Ventas.dart';

export 'package:blue_thermal_printer/blue_thermal_printer.dart'
    show BluetoothDevice;

class _PrintJob {
  final int jobId;
  final Ventas venta;
  final Completer<void> completer;
  final DateTime createdAt;

  _PrintJob({
    required this.jobId,
    required this.venta,
    required this.completer,
  }) : createdAt = DateTime.now();
}

class BluetoothPrinterService {
  static BluetoothPrinterService? _instance;
  static BluetoothPrinterService get instance =>
      _instance ??= BluetoothPrinterService._();

  BluetoothPrinterService._();

  final BlueThermalPrinter _bt = BlueThermalPrinter.instance;
  BluetoothDevice? _connectedDevice;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  // --- Print queue state ---
  final List<_PrintJob> _queue = [];
  bool _isProcessing = false;
  int _jobCounter = 0;

  bool get isPrinting => _isProcessing;

  Future<bool> get isBluetoothOn async => (await _bt.isOn) ?? false;

  Future<bool> get isConnected async => (await _bt.isConnected) ?? false;

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
      debugPrint(
        '[BT] Connected to ${device.name} (${device.address})',
      );
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
    _failPendingJobs('Impresora desconectada');
    debugPrint('[BT] Disconnected. Pending jobs cleared.');
  }

  void _failPendingJobs(String reason) {
    for (final job in _queue) {
      if (!job.completer.isCompleted) {
        job.completer.completeError(Exception(reason));
      }
    }
    _queue.clear();
  }

  /// Enqueues a print job. The returned [Future] completes when the ticket
  /// has been fully sent to the printer (or fails with an error).
  /// Only ONE job is processed at a time; concurrent calls are queued.
  Future<void> printTicket(Ventas venta) {
    final jobId = ++_jobCounter;
    final completer = Completer<void>();
    final job = _PrintJob(jobId: jobId, venta: venta, completer: completer);

    _queue.add(job);
    debugPrint(
      '[PrintQueue] Job #$jobId enqueued '
      '(ventaId=${venta.id ?? "local"}, queue=${_queue.length})',
    );

    _processQueue();
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      final sw = Stopwatch()..start();
      debugPrint(
        '[PrintQueue] >>> Start job #${job.jobId} '
        '(ventaId=${job.venta.id ?? "local"})',
      );

      try {
        await _ensureConnection();
        await _executePrint(job.venta);
        sw.stop();
        debugPrint(
          '[PrintQueue] <<< Job #${job.jobId} OK '
          '(${sw.elapsedMilliseconds} ms)',
        );
        job.completer.complete();
      } catch (e) {
        sw.stop();
        debugPrint(
          '[PrintQueue] <<< Job #${job.jobId} FAILED '
          '(${sw.elapsedMilliseconds} ms): $e',
        );
        if (!job.completer.isCompleted) {
          job.completer.completeError(e);
        }
      }
    }

    _isProcessing = false;
  }

  /// Verifies the BT connection is alive. If it dropped but we still know the
  /// device, attempts a transparent reconnect. Throws if unrecoverable.
  Future<void> _ensureConnection() async {
    final connected = await isConnected;
    if (connected) return;

    if (_connectedDevice == null) {
      throw Exception(
        'Impresora desconectada. Verificá que esté encendida y volvé a conectar.',
      );
    }

    debugPrint(
      '[BT] Connection lost. Reconnecting to '
      '${_connectedDevice!.name} (${_connectedDevice!.address})...',
    );

    try {
      await _bt.connect(_connectedDevice!);
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('[BT] Reconnected successfully');
    } catch (e) {
      _connectedDevice = null;
      throw Exception(
        'No se pudo reconectar con la impresora. '
        'Verificá que esté encendida y volvé a conectar.',
      );
    }
  }

  Future<void> _executePrint(Ventas venta) async {
    try {
      // ESC @ — initialize printer (resets any buffered state)
      await _bt.writeBytes(Uint8List.fromList([0x1B, 0x40]));

      final ticketData = TicketBuilder.buildTicket(venta);
      await _bt.writeBytes(ticketData);

      // 5 line feeds + partial cut (GS V A 0x00)
      await _bt.writeBytes(
        Uint8List.fromList([
          0x0A, 0x0A, 0x0A, 0x0A, 0x0A,
          0x1D, 0x56, 0x41, 0x00,
        ]),
      );
    } catch (e) {
      throw Exception('Error al imprimir ticket: $e');
    }
  }
}
