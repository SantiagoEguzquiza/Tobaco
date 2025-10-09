import 'package:flutter/material.dart';
import '../Widgets/custom_loading_widget.dart';
import '../Screens/Loading/loading_screen.dart';

class LoadingUtils {
  // Mostrar diálogo de carga
  static void showLoadingDialog(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => DialogLoadingWidget(
        message: message ?? 'Cargando...',
      ),
    );
  }

  // Ocultar diálogo de carga
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // Mostrar pantalla de carga completa
  // static void showFullScreenLoading(
  //   BuildContext context, {
  //   String? message,
  //   Color? backgroundColor,
  //   bool showLogo = true,
  // }) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) => LoadingScreen(
  //         message: message,
  //         backgroundColor: backgroundColor,
  //         showLogo: showLogo,
  //       ),
  //       fullscreenDialog: true,
  //     ),
  //   );
  // }

  // Mostrar pantalla de carga para datos
  static void showDataLoading(
    BuildContext context, {
    String? message,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DataLoadingScreen(
          message: message,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // Mostrar pantalla de carga para operaciones
  static void showOperationLoading(
    BuildContext context, {
    String? message,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OperationLoadingScreen(
          message: message,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // Ejecutar operación con pantalla de carga
  static Future<T?> executeWithLoading<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? loadingMessage,
    bool showDialog = true,
  }) async {
    if (showDialog) {
      showLoadingDialog(context, message: loadingMessage);
    }

    try {
      final result = await operation();
      if (showDialog) {
        hideLoadingDialog(context);
      }
      return result;
    } catch (e) {
      if (showDialog) {
        hideLoadingDialog(context);
      }
      rethrow;
    }
  }

  // Ejecutar operación con pantalla de carga completa
  // static Future<T?> executeWithFullScreenLoading<T>(
  //   BuildContext context,
  //   Future<T> Function() operation, {
  //   String? loadingMessage,
  //   Color? backgroundColor,
  //   bool showLogo = true,
  // }) async {
  //   showFullScreenLoading(
  //     context,
  //     message: loadingMessage,
  //     backgroundColor: backgroundColor,
  //     showLogo: showLogo,
  //   );

  //   try {
  //     final result = await operation();
  //     Navigator.of(context).pop(); // Cerrar pantalla de carga
  //     return result;
  //   } catch (e) {
  //     Navigator.of(context).pop(); // Cerrar pantalla de carga
  //     rethrow;
  //   }
  // }
}
