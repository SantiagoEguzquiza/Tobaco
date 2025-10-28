import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../Models/Ventas.dart';

/// Servicio para guardar ventas creadas offline (pendientes de sincronización)
class VentasOfflineCacheService {
  static final VentasOfflineCacheService _instance = VentasOfflineCacheService._internal();
  factory VentasOfflineCacheService() => _instance;
  VentasOfflineCacheService._internal();

  static Database? _database;
  static const String _databaseName = 'ventas_offline.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('💾 VentasOfflineCacheService: Inicializando base de datos...');
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('💾 VentasOfflineCacheService: Creando tabla...');

    // Tabla simple: guarda ventas offline como JSON
    await db.execute('''
      CREATE TABLE ventas_offline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    print('✅ VentasOfflineCacheService: Tabla creada correctamente');
  }

  /// Guarda una venta offline (para sincronizar después)
  Future<int> guardarVentaOffline(Ventas venta) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final id = await db.insert('ventas_offline', {
        'venta_json': jsonEncode(venta.toJson()),
        'created_at': now,
        'synced': 0,
      });

      print('✅ VentasOfflineCacheService: Venta guardada offline (ID: $id)');
      return id;
    } catch (e) {
      print('❌ VentasOfflineCacheService: Error guardando venta: $e');
      rethrow;
    }
  }

  /// Obtiene ventas offline pendientes de sincronización
  Future<List<Map<String, dynamic>>> obtenerVentasPendientes() async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'ventas_offline',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );

      print('📦 VentasOfflineCacheService: ${maps.length} ventas pendientes de sincronización');
      return maps;
    } catch (e) {
      print('❌ VentasOfflineCacheService: Error obteniendo ventas pendientes: $e');
      return [];
    }
  }

  /// Marca una venta como sincronizada
  Future<void> marcarComoSincronizada(int id) async {
    try {
      final db = await database;
      
      await db.update(
        'ventas_offline',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );

      print('✅ VentasOfflineCacheService: Venta $id marcada como sincronizada');
    } catch (e) {
      print('❌ VentasOfflineCacheService: Error marcando venta como sincronizada: $e');
    }
  }

  /// Elimina ventas sincronizadas antiguas
  Future<void> limpiarVentasSincronizadas() async {
    try {
      final db = await database;
      
      await db.delete(
        'ventas_offline',
        where: 'synced = ?',
        whereArgs: [1],
      );

      print('🧹 VentasOfflineCacheService: Ventas sincronizadas limpiadas');
    } catch (e) {
      print('❌ VentasOfflineCacheService: Error limpiando ventas: $e');
    }
  }

  /// Cuenta ventas pendientes
  Future<int> contarPendientes() async {
    try {
      final db = await database;
      
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ventas_offline WHERE synced = 0')
      );
      
      return count ?? 0;
    } catch (e) {
      print('❌ VentasOfflineCacheService: Error contando pendientes: $e');
      return 0;
    }
  }
}

