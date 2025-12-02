import 'package:flutter/material.dart';

/// Widget que muestra un indicador cuando la app está usando datos en caché (offline)
class CacheIndicator extends StatelessWidget {
  final bool isUsingCache;
  final bool compact;

  const CacheIndicator({
    super.key,
    required this.isUsingCache,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isUsingCache) return const SizedBox.shrink();

    if (compact) {
      // Versión compacta para AppBar
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cloud_off, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Caché',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Versión completa para contenido
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Datos en caché (offline). Los cambios se sincronizarán con conexión.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

