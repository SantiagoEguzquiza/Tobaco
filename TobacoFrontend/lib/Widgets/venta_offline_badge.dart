import 'package:flutter/material.dart';

/// Badge para indicar que una venta está pendiente de sincronización
class VentaOfflineBadge extends StatelessWidget {
  final bool isPending;
  final bool isFailed;
  final bool compact;

  const VentaOfflineBadge({
    super.key,
    this.isPending = true,
    this.isFailed = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPending && !isFailed) return const SizedBox.shrink();

    if (compact) {
      // Versión compacta (solo icono)
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isFailed ? Colors.red.shade100 : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isFailed ? Icons.error_outline : Icons.cloud_upload,
          size: 16,
          color: isFailed ? Colors.red.shade700 : Colors.orange.shade700,
        ),
      );
    }

    // Versión completa (con texto)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFailed ? Colors.red.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: isFailed ? Colors.red.shade200 : Colors.orange.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFailed ? Icons.error_outline : Icons.cloud_upload,
            size: 14,
            color: isFailed ? Colors.red.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            isFailed ? 'Error' : 'Pendiente',
            style: TextStyle(
              color: isFailed ? Colors.red.shade900 : Colors.orange.shade900,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension para identificar si una venta es offline
extension VentaOfflineExtension on dynamic {
  /// Verifica si una venta tiene ID null (significa que es offline)
  bool get isOffline {
    try {
      // Si la venta tiene id null, es offline
      return this.id == null;
    } catch (e) {
      return false;
    }
  }
}

