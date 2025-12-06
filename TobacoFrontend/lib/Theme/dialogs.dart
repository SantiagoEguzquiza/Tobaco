import 'package:flutter/material.dart';
import 'package:tobaco/Theme/app_theme.dart';

class AppDialogs {
  // Colores para diálogos
  static const Color _destructiveColor = Colors.red;
  static const Color _successColor = Colors.green;
  static const Color _warningColor = Colors.orange;
  
  // Estilos consistentes - ahora son métodos que toman el contexto
  static TextStyle _titleStyle(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).textTheme.titleLarge?.color,
  );
  
  static TextStyle _messageStyle(BuildContext context) => TextStyle(
    fontSize: 16,
    color: Theme.of(context).textTheme.bodyLarge?.color,
    height: 1.4,
  );
  
  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Diálogo de confirmación genérica
  /// 
  /// [context] - Contexto de la aplicación
  /// [title] - Título del diálogo (opcional, por defecto: "Confirmar acción")
  /// [message] - Mensaje del diálogo (opcional, por defecto: "¿Está seguro de continuar?")
  /// [confirmText] - Texto del botón de confirmación (opcional, por defecto: "Confirmar")
  /// [cancelText] - Texto del botón de cancelación (opcional, por defecto: "Cancelar")
  /// [icon] - Ícono del diálogo (opcional, por defecto: Icons.help_outline)
  /// [iconColor] - Color del ícono (opcional, por defecto: Colors.blue)
  /// 
  /// Retorna [true] si el usuario confirma, [false] si cancela
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    String? title,
    String? message,
    String? confirmText,
    String? cancelText,
    IconData? icon,
    Color? iconColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Evita cerrar accidentalmente
      builder: (BuildContext context) {
        return _ConfirmationDialog(
          title: title ?? 'Confirmar acción',
          message: message ?? '¿Está seguro de continuar?',
          confirmText: confirmText ?? 'Confirmar',
          cancelText: cancelText ?? 'Cancelar',
          icon: icon ?? Icons.help_outline,
          iconColor: iconColor ?? Colors.blue,
          isDestructive: false,
        );
      },
    );
    
    return result ?? false;
  }

  /// Diálogo de confirmación de eliminación (destructivo)
  /// 
  /// [context] - Contexto de la aplicación
  /// [title] - Título del diálogo (opcional, por defecto: "Eliminar elemento")
  /// [message] - Mensaje del diálogo (opcional, por defecto: "¿Eliminar este elemento? Esta acción no se puede deshacer.")
  /// [confirmText] - Texto del botón de eliminación (opcional, por defecto: "Eliminar")
  /// [cancelText] - Texto del botón de cancelación (opcional, por defecto: "Cancelar")
  /// [itemName] - Nombre del elemento a eliminar (opcional, para personalizar el mensaje)
  /// 
  /// Retorna [true] si el usuario confirma la eliminación, [false] si cancela
  static Future<bool> showDeleteConfirmationDialog({
    required BuildContext context,
    String? title,
    String? message,
    String? confirmText,
    String? cancelText,
    String? itemName,
  }) async {
    final defaultMessage = itemName != null 
        ? '¿Eliminar "$itemName"? Esta acción no se puede deshacer.'
        : '¿Eliminar este elemento? Esta acción no se puede deshacer.';
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Evita cerrar accidentalmente
      builder: (BuildContext context) {
        return _ConfirmationDialog(
          title: title ?? 'Eliminar elemento',
          message: message ?? defaultMessage,
          confirmText: confirmText ?? 'Eliminar',
          cancelText: cancelText ?? 'Cancelar',
          icon: Icons.warning_rounded,
          iconColor: _destructiveColor,
          isDestructive: true,
        );
      },
    );
    
    return result ?? false;
  }

  /// Diálogo de éxito
  /// 
  /// [context] - Contexto de la aplicación
  /// [title] - Título del diálogo (opcional, por defecto: "Éxito")
  /// [message] - Mensaje del diálogo
  /// [buttonText] - Texto del botón (opcional, por defecto: "Aceptar")
  static Future<void> showSuccessDialog({
    required BuildContext context,
    String? title,
    required String message,
    String? buttonText,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _InfoDialog(
          title: title ?? 'Éxito',
          message: message,
          buttonText: buttonText ?? 'Aceptar',
          icon: Icons.check_circle,
          iconColor: _successColor,
        );
      },
    );
  }

  /// Diálogo de error
  /// 
  /// [context] - Contexto de la aplicación
  /// [title] - Título del diálogo (opcional, por defecto: "Error")
  /// [message] - Mensaje del diálogo
  /// [buttonText] - Texto del botón (opcional, por defecto: "Aceptar")
  static Future<void> showErrorDialog({
    required BuildContext context,
    String? title,
    required String message,
    String? buttonText,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _InfoDialog(
          title: title ?? 'Error',
          message: message,
          buttonText: buttonText ?? 'Aceptar',
          icon: Icons.error,
          iconColor: _destructiveColor,
        );
      },
    );
  }

  /// Diálogo de advertencia
  /// 
  /// [context] - Contexto de la aplicación
  /// [title] - Título del diálogo (opcional, por defecto: "Advertencia")
  /// [message] - Mensaje del diálogo
  /// [buttonText] - Texto del botón (opcional, por defecto: "Entendido")
  static Future<void> showWarningDialog({
    required BuildContext context,
    String? title,
    required String message,
    String? buttonText,
    IconData? icon,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _InfoDialog(
          title: title ?? 'Advertencia',
          message: message,
          buttonText: buttonText ?? 'Entendido',
          icon: icon ?? Icons.warning_rounded,
          iconColor: _warningColor,
        );
      },
    );
  }

  /// Diálogo de confirmación de cerrar sesión
  /// 
  /// [context] - Contexto de la aplicación
  /// [title] - Título del diálogo (opcional, por defecto: "Cerrar Sesión")
  /// [message] - Mensaje del diálogo (opcional, por defecto: "¿Estás seguro de que quieres cerrar sesión?")
  /// [confirmText] - Texto del botón de confirmación (opcional, por defecto: "Cerrar Sesión")
  /// [cancelText] - Texto del botón de cancelación (opcional, por defecto: "Cancelar")
  /// 
  /// Retorna [true] si el usuario confirma cerrar sesión, [false] si cancela
  static Future<bool> showLogoutConfirmationDialog({
    required BuildContext context,
    String? title,
    String? message,
    String? confirmText,
    String? cancelText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Evita cerrar accidentalmente
      builder: (BuildContext context) {
        return _ConfirmationDialog(
          title: title ?? 'Cerrar Sesión',
          message: message ?? '¿Estás seguro de que quieres cerrar sesión?',
          confirmText: confirmText ?? 'Cerrar Sesión',
          cancelText: cancelText ?? 'Cancelar',
          icon: Icons.logout,
          iconColor: _destructiveColor, // Rojo para indicar acción destructiva
          isDestructive: true,
        );
      },
    );
    
    return result ?? false;
  }

  /// Diálogo de desactivación de producto con ventas vinculadas
  /// 
  /// [context] - Contexto de la aplicación
  /// [productName] - Nombre del producto a desactivar
  /// [title] - Título del diálogo (opcional, por defecto: "Producto con Ventas")
  /// [message] - Mensaje del diálogo (opcional)
  /// [confirmText] - Texto del botón de confirmación (opcional, por defecto: "Desactivar")
  /// [cancelText] - Texto del botón de cancelación (opcional, por defecto: "Cancelar")
  /// 
  /// Retorna [true] si el usuario confirma desactivar, [false] si cancela
  static Future<bool> showDeactivateProductDialog({
    required BuildContext context,
    required String productName,
    String? title,
    String? message,
    String? confirmText,
    String? cancelText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Evita cerrar accidentalmente
      builder: (BuildContext context) {
        return _DeactivateProductDialog(
          title: title ?? 'Producto con Ventas',
          productName: productName,
          message: message ?? 'El producto "$productName" no se puede eliminar porque tiene ventas vinculadas.',
          confirmText: confirmText ?? 'Desactivar',
          cancelText: cancelText ?? 'Cancelar',
        );
      },
    );
    
    return result ?? false;
  }

  /// Diálogo de error de conexión con el servidor
  /// 
  /// [context] - Contexto de la aplicación
  /// [title] - Título del diálogo (opcional, por defecto: "Servidor No Disponible")
  /// [message] - Mensaje del diálogo (opcional)
  /// [buttonText] - Texto del botón (opcional, por defecto: "Entendido")
  static Future<void> showServerErrorDialog({
    required BuildContext context,
    String? title,
    String? message,
    String? buttonText,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _InfoDialog(
          title: title ?? 'Servidor No Disponible',
          message: message ?? 'No se pudo conectar con el servidor. Por favor, intente más tarde.',
          buttonText: buttonText ?? 'Entendido',
          icon: Icons.cloud_off_rounded,
          iconColor: _destructiveColor,
        );
      },
    );
  }
}

/// Widget privado para diálogos de confirmación
class _ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final Color iconColor;
  final bool isDestructive;

  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.icon,
    required this.iconColor,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Título
            Text(
              title,
              style: AppDialogs._titleStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Mensaje
            Text(
              message,
              style: AppDialogs._messageStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: AppDialogs._buttonTextStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: isDestructive 
                          ? AppDialogs._destructiveColor 
                          : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      confirmText,
                      style: AppDialogs._buttonTextStyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget privado para diálogos informativos (éxito, error, advertencia)
class _InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData icon;
  final Color iconColor;

  const _InfoDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Título
            Text(
              title,
              style: AppDialogs._titleStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Mensaje
            Text(
              message,
              style: AppDialogs._messageStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Botón
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  buttonText,
                  style: AppDialogs._buttonTextStyle.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget privado para diálogo de desactivación de producto
class _DeactivateProductDialog extends StatelessWidget {
  final String title;
  final String productName;
  final String message;
  final String confirmText;
  final String cancelText;

  const _DeactivateProductDialog({
    required this.title,
    required this.productName,
    required this.message,
    required this.confirmText,
    required this.cancelText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 32,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            
            // Título
            Text(
              title,
              style: AppDialogs._titleStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Mensaje principal
            Text(
              message,
              style: AppDialogs._messageStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Pregunta
            Text(
              '¿Desea desactivarlo en su lugar?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Información adicional
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El producto se ocultará de los catálogos pero se mantendrá en las ventas existentes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: AppDialogs._buttonTextStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      confirmText,
                      style: AppDialogs._buttonTextStyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
