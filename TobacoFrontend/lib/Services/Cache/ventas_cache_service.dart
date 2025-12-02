import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../Models/Ventas.dart';

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
    
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    

    // Tabla simple: guarda las ventas como JSON
    await db.execute('''
      CREATE TABLE ventas_cache (
        id INTEGER PRIMARY KEY,
        venta_json TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    
  }

  /// Guarda las ventas del servidor en caché
  Future<void> guardarVentasEnCache(List<Ventas> ventas) async {
    try {
      final db = await database;
      
      // SIEMPRE limpiar el caché anterior, incluso si la lista está vacía
      await db.delete('ventas_cache');
      
      // Si hay ventas, guardarlas
      if (ventas.isNotEmpty) {
        final now = DateTime.now().toIso8601String();
        
        for (var venta in ventas) {
          await db.insert('ventas_cache', {
            'id': venta.id,
            'venta_json': jsonEncode(venta.toJson()),
            'cached_at': now,
          });
        }
      }
      
    } catch (e) {
      
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
        
        return [];
      }

      List<Ventas> ventas = [];
      for (var map in maps) {
        try {
          final ventaJson = jsonDecode(map['venta_json'] as String);
          ventas.add(Ventas.fromJson(ventaJson));
        } catch (e) {
          
        }
      }

      
      return ventas;
    } catch (e) {
      
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
      
      return 0;
    }
  }

  /// Limpia todo el caché
  Future<void> limpiarCache() async {
    try {
      final db = await database;
      await db.delete('ventas_cache');
      
    } catch (e) {
      
    }
  }

  /// Resetea completamente la base de datos
  Future<void> resetearBaseDeDatos() async {
    
    
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      await deleteDatabase(path);
      
      _database = await _initDatabase();
      
      
    } catch (e) {
      
    }
  }
}

