import 'package:flutter/material.dart';

/// Widget de estado de sincronización - DESACTIVADO en sistema simple
/// El nuevo sistema de caché simple no requiere sincronización
class SyncStatusWidget extends StatelessWidget {
  final bool showDetails;

  const SyncStatusWidget({
    super.key,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sistema simple: sin sincronización, sin widget de estado
    return const SizedBox.shrink();
  }
}

/// Botón de sincronización - DESACTIVADO en sistema simple
class SyncButton extends StatelessWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Sistema simple: sin sincronización manual
    return const SizedBox.shrink();
  }
}
