import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../Models/Ventas.dart';
import '../../Models/VentasProductos.dart';
import '../../Models/Cliente.dart';
import '../../Models/metodoPago.dart';
import '../../Models/EstadoEntrega.dart';
import '../../Models/User.dart';

/// Servicio SIMPLE de caché de ventas para mostrar offline
/// Solo guarda ventas del servidor para verlas cuando no hay conexión
class VentasCacheService {
  static final VentasCacheService _instance = VentasCacheService._internal();
  factory VentasCacheService() => _instance;
  VentasCacheService._internal();

  static Database? _database;
  static const String _databaseName = 'ventas_simple_cache.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('💾 VentasCacheService: Inicializando base de datos...');
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('💾 VentasCacheService: Creando tabla de ventas...');

    // Tabla simple: guarda las ventas como JSON
    await db.execute('''
      CREATE TABLE ventas_cache (
        id INTEGER PRIMARY KEY,
        venta_json TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    print('✅ VentasCacheService: Tabla creada correctamente');
  }

  /// Guarda las ventas del servidor en caché
  Future<void> guardarVentasEnCache(List<Ventas> ventas) async {
    if (ventas.isEmpty) {
      print('💾 VentasCacheService: No hay ventas para guardar');
      return;
    }

    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        // Limpiar caché anterior
        await txn.delete('ventas_cache');

        // Guardar cada venta como JSON
        for (var venta in ventas) {
          await txn.insert('ventas_cache', {
            'id': venta.id,
            'venta_json': jsonEncode(venta.toJson()),
            'cached_at': now,
          });
        }
      });

      print('✅ VentasCacheService: ${ventas.length} ventas guardadas en caché');
    } catch (e) {
      print('❌ VentasCacheService: Error guardando ventas: $e');
    }
  }

  /// Obtiene las ventas del caché
  Future<List<Ventas>> obtenerVentasDelCache() async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'ventas_cache',
        orderBy: 'id DESC',
      );

      if (maps.isEmpty) {
        print('📦 VentasCacheService: No hay ventas en caché');
        return [];
      }

      List<Ventas> ventas = [];
      for (var map in maps) {
        try {
          final ventaJson = jsonDecode(map['venta_json'] as String);
          ventas.add(Ventas.fromJson(ventaJson));
        } catch (e) {
          print('⚠️ VentasCacheService: Error parseando venta ${map['id']}: $e');
        }
      }

      print('✅ VentasCacheService: ${ventas.length} ventas obtenidas del caché');
      return ventas;
    } catch (e) {
      print('❌ VentasCacheService: Error obteniendo ventas del caché: $e');
      return [];
    }
  }

  /// Verifica cuántas ventas hay en caché
  Future<int> contarVentasEnCache() async {
    try {
      final db = await database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ventas_cache')
      );
      return count ?? 0;
    } catch (e) {
      print('❌ VentasCacheService: Error contando ventas: $e');
      return 0;
    }
  }

  /// Limpia todo el caché
  Future<void> limpiarCache() async {
    try {
      final db = await database;
      await db.delete('ventas_cache');
      print('🧹 VentasCacheService: Caché limpiado');
    } catch (e) {
      print('❌ VentasCacheService: Error limpiando caché: $e');
    }
  }

  /// Resetea completamente la base de datos
  Future<void> resetearBaseDeDatos() async {
    print('🔄 VentasCacheService: Reseteando base de datos...');
    
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      await deleteDatabase(path);
      
      _database = await _initDatabase();
      
      print('✅ VentasCacheService: Base de datos reseteada');
    } catch (e) {
      print('❌ VentasCacheService: Error reseteando BD: $e');
    }
  }
}

