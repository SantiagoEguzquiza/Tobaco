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
  static const int _databaseVersion = 2; // Incrementado para agregar columna is_syncing

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
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    

    // Tabla simple: guarda ventas offline como JSON
    await db.execute('''
      CREATE TABLE ventas_offline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        is_syncing INTEGER DEFAULT 0
      )
    ''');

    
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar columna is_syncing para evitar duplicados durante sincronización
      await db.execute('''
        ALTER TABLE ventas_offline ADD COLUMN is_syncing INTEGER DEFAULT 0
      ''');
    }
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

      
      return id;
    } catch (e) {
      
      rethrow;
    }
  }

  /// Obtiene ventas offline pendientes de sincronización
  Future<List<Map<String, dynamic>>> obtenerVentasPendientes() async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'ventas_offline',
        where: 'synced = ? AND (is_syncing = ? OR is_syncing IS NULL)',
        whereArgs: [0, 0],
        orderBy: 'created_at DESC',
      );

      
      return maps;
    } catch (e) {
      
      return [];
    }
  }

  /// Marca una venta como sincronizada
  Future<void> marcarComoSincronizada(int id) async {
    try {
      final db = await database;
      
      await db.update(
        'ventas_offline',
        {'synced': 1, 'is_syncing': 0},
        where: 'id = ?',
        whereArgs: [id],
      );

      
    } catch (e) {
      
    }
  }

  /// Marca una venta como en proceso de sincronización (para evitar duplicados)
  Future<bool> marcarComoSyncing(int id) async {
    try {
      final db = await database;
      
      // Solo marcar si no está ya sincronizada o en proceso
      final result = await db.update(
        'ventas_offline',
        {'is_syncing': 1},
        where: 'id = ? AND synced = ? AND is_syncing = ?',
        whereArgs: [id, 0, 0],
      );
      
      // Retornar true si se marcó exitosamente (result > 0)
      return result > 0;
    } catch (e) {
      
      return false;
    }
  }

  /// Revierte el marcado de sincronización (por si falla)
  Future<void> revertirSyncing(int id) async {
    try {
      final db = await database;
      
      await db.update(
        'ventas_offline',
        {'is_syncing': 0},
        where: 'id = ?',
        whereArgs: [id],
      );

      
    } catch (e) {
      
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

      
    } catch (e) {
      
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
      
      return 0;
    }
  }

  /// Limpia ventas que están marcadas como "syncing" pero no deberían estarlo
  /// Esto puede pasar si la app se cierra durante una sincronización
  Future<int> limpiarSyncingAtascadas() async {
    try {
      final db = await database;
      
      // Revertir todas las ventas que están marcadas como syncing pero no han sido sincronizadas
      final result = await db.update(
        'ventas_offline',
        {'is_syncing': 0},
        where: 'is_syncing = ? AND synced = ?',
        whereArgs: [1, 0],
      );
      
      return result;
    } catch (e) {
      return 0;
    }
  }

  /// Obtiene todas las ventas offline (incluyendo las atascadas)
  Future<List<Map<String, dynamic>>> obtenerTodasLasVentasOffline() async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'ventas_offline',
        orderBy: 'created_at DESC',
      );
      
      return maps;
    } catch (e) {
      return [];
    }
  }

  /// Elimina una venta offline específica por ID
  Future<bool> eliminarVentaOffline(int id) async {
    try {
      final db = await database;
      
      final result = await db.delete(
        'ventas_offline',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return result > 0;
    } catch (e) {
      return false;
    }
  }
}

