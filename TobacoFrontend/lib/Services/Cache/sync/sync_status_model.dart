/// Modelo para el estado de sincronización
class SyncStatusModel {
  final int totalPending;
  final int totalSynced;
  final int totalFailed;
  final bool isSyncing;
  final String? lastSyncError;
  final DateTime? lastSyncTime;

  SyncStatusModel({
    required this.totalPending,
    required this.totalSynced,
    required this.totalFailed,
    this.isSyncing = false,
    this.lastSyncError,
    this.lastSyncTime,
  });

  /// Crea un estado vacío
  factory SyncStatusModel.empty() {
    return SyncStatusModel(
      totalPending: 0,
      totalSynced: 0,
      totalFailed: 0,
      isSyncing: false,
    );
  }

  /// Crea un estado desde un mapa
  factory SyncStatusModel.fromMap(Map<String, dynamic> map) {
    return SyncStatusModel(
      totalPending: map['totalPending'] as int? ?? 0,
      totalSynced: map['totalSynced'] as int? ?? 0,
      totalFailed: map['totalFailed'] as int? ?? 0,
      isSyncing: map['isSyncing'] as bool? ?? false,
      lastSyncError: map['lastSyncError'] as String?,
      lastSyncTime: map['lastSyncTime'] != null
          ? DateTime.parse(map['lastSyncTime'] as String)
          : null,
    );
  }

  /// Convierte el estado a un mapa
  Map<String, dynamic> toMap() {
    return {
      'totalPending': totalPending,
      'totalSynced': totalSynced,
      'totalFailed': totalFailed,
      'isSyncing': isSyncing,
      'lastSyncError': lastSyncError,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
    };
  }

  /// Verifica si hay ventas pendientes
  bool get hasPending => totalPending > 0;

  /// Verifica si hay errores
  bool get hasErrors => totalFailed > 0;

  /// Obtiene el total de ventas
  int get total => totalPending + totalSynced + totalFailed;
}
