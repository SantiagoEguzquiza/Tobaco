import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color primaryColor = Colors.green;
  static const Color confirmButtonColor = Colors.green;
  static const Color cancelButtonColor = Colors.white;
  static const Color secondaryColor = Color(0xFFE9F3EF); // Verde para impares
  static const Color greyColor = Color(0xFFDBDBDB); // Gris claro para pares
  static const Color textColor = Colors.black;
  static const Color textGreyColor = Colors.grey;
  static const Color addGreenColor = Colors.green;
  static const double borderRadiusMainButtons = 8;
  static const double borderRadiusCards = 8;

  static const TextStyle inputLabelStyle = TextStyle(
    fontSize: 16,
    color: Colors.black,
  );

  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.black,
  );

  static const InputDecoration inputDecoration = InputDecoration(
    border: OutlineInputBorder(),
  );

  static const BoxDecoration showMenuBoxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  static const TextStyle showMenuItemTextStyle = TextStyle(
    color: textColor,
    fontSize: 16,
  );

  static const TextStyle showMenuSelectedItemTextStyle = TextStyle(
    color: primaryColor,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const ShapeBorder showMenuShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  static CheckboxThemeData checkboxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5),
    ),
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return primaryColor;
      }
      return greyColor;
    }),
    checkColor: WidgetStateProperty.all(Colors.white),
    side: const BorderSide(
      color: greyColor,
      width: 2,
    ),
  );

  static AlertDialog alertDialogStyle({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    return AlertDialog(
      backgroundColor: null, // Usar el tema del contexto
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: null, // Usar el color del tema
        ),
      ),
      content: Text(
        content,
        style: TextStyle(
          fontSize: 16,
          color: null, // Usar el color del tema
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text(
            'Eliminar',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  static AlertDialog confirmDialogStyle({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    return AlertDialog(
      backgroundColor: null, // Usar el tema del contexto
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: null, // Usar el color del tema
        ),
      ),
      content: Text(
        content,
        style: TextStyle(
          fontSize: 16,
          color: null, // Usar el color del tema
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text(
            'Confirmar',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }

  static const InputDecoration searchInputDecoration = InputDecoration(
    labelText: 'Buscar...',
    labelStyle: TextStyle(
      color: Colors.grey,
      fontSize: 15,
    ),
    floatingLabelStyle: TextStyle(
      color: Colors.grey,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    prefixIcon: Icon(
      Icons.search,
      color: Colors.grey,
      size: 15,
    ),
    filled: true,
    fillColor: Color.fromRGBO(255, 255, 255, 1),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(
        color: Color.fromRGBO(200, 200, 200, 1),
        width: 1.0,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(
        color: Color.fromRGBO(200, 200, 200, 1),
        width: 1.0,
      ),
    ),
    contentPadding: EdgeInsets.symmetric(
      vertical: 10,
      horizontal: 15,
    ),
  );

  static ButtonStyle elevatedButtonStyle(
    Color backgroundColor, {
    Color foregroundColor = Colors.white,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      minimumSize: const Size.fromHeight(56),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMainButtons),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ButtonStyle outlinedButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    side: const BorderSide(color: Colors.grey),
    backgroundColor: Colors.white, // This will be overridden by theme
  );

  static const TextStyle cardTitleStyle = TextStyle(
    color: textColor,
    fontSize: 18,
  );

  static const TextStyle cardSubtitleStyle = TextStyle(
    fontSize: 12,
    color: textGreyColor,
  );

  static const TextStyle appBarTitleStyle = TextStyle(
    fontSize: 20,
    color: Color(0xFFFFFFFF), // Blanco puro para títulos
    fontWeight: FontWeight.w600,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 16,
    color: textColor,
  );

  static const TextStyle sectionContentStyle = TextStyle(
    fontSize: 16,
    color: textColor,
  );

  static const TextStyle itemListaNegrita =
      TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold);

  static const TextStyle itemListaPrecio =
      TextStyle(color: Colors.blueGrey, fontSize: 14);

  static BoxDecoration sectionBoxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30),
    border: Border.all(
      color: const Color.fromRGBO(200, 200, 200, 1),
      width: 1.0,
    ),
  );

  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: Colors.white,
      primarySwatch: Colors.green,
      primaryColor: primaryColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemStatusBarContrastEnforced: false,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Shippori',
          fontSize: 30,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withOpacity(0.25),
        selectionHandleColor: primaryColor,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontSize: 18,
          color: Colors.black,
          fontFamily: 'LibreFranklin',
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Colors.black54,
          fontFamily: 'LibreFranklin',
        ),
      ),
      
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(
          color: Colors.grey,
          fontSize: 15,
        ),
        floatingLabelStyle: TextStyle(
          color: Colors.grey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        prefixIconColor: Colors.grey,
        filled: true,
        fillColor: Color.fromRGBO(255, 255, 255, 1),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(
            color: Color.fromRGBO(200, 200, 200, 1),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(
            color: Color.fromRGBO(200, 200, 200, 1),
            width: 1.0,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 15,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      primaryColor: const Color(0xFF4CAF50), // Verde más vibrante para modo oscuro
      colorScheme: const ColorScheme.dark().copyWith(
        primary: const Color(0xFF4CAF50),
        secondary: const Color(0xFF66BB6A),
        surface: const Color(0xFF1A1A1A),
        onSurface: const Color(0xFFE0E0E0),
        onPrimary: Colors.white,
        error: const Color(0xFFCF6679),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000), // Negro para modo oscuro
        foregroundColor: Color(0xFFFFFFFF), // Blanco para modo oscuro
        elevation: 1,
        shadowColor: Colors.black26,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF0F0F0F),
          systemStatusBarContrastEnforced: false,
          statusBarColor: Color(0xFF000000),
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Shippori',
          fontSize: 30,
          color: Color(0xFFFFFFFF),
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A2A),
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF4CAF50),
        selectionColor: Color(0xFF4CAF50),
        selectionHandleColor: Color(0xFF4CAF50),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontSize: 18,
          color: Color(0xFFE0E0E0),
          fontFamily: 'LibreFranklin',
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Color(0xFFB0B0B0),
          fontFamily: 'LibreFranklin',
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          color: Color(0xFF808080),
          fontFamily: 'LibreFranklin',
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          color: Color(0xFFE0E0E0),
          fontFamily: 'LibreFranklin',
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          color: Color(0xFFE0E0E0),
          fontFamily: 'LibreFranklin',
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(
          color: Color(0xFF808080),
          fontSize: 15,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF4CAF50),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF606060),
          fontSize: 15,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFFCF6679)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFFCF6679), width: 2.0),
        ),
        prefixIconColor: const Color(0xFF808080),
        suffixIconColor: const Color(0xFF808080),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 15,
        ),
      ),
      cardTheme: const CardTheme(
        color: Color(0xFF1A1A1A),
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dialogTheme: const DialogTheme(
        backgroundColor: Color(0xFF1A1A1A),
        titleTextStyle: TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF404040),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF4CAF50);
          }
          return const Color(0xFF808080);
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF4CAF50).withOpacity(0.3);
          }
          return const Color(0xFF404040);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF4CAF50);
          }
          return const Color(0xFF404040);
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: Color(0xFF808080)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF4CAF50);
          }
          return const Color(0xFF808080);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF4CAF50),
        linearTrackColor: Color(0xFF404040),
        circularTrackColor: Color(0xFF404040),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1A1A1A),
        contentTextStyle: TextStyle(color: Color(0xFFE0E0E0)),
        actionTextColor: Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A1A),
        selectedItemColor: Color(0xFF4CAF50),
        unselectedItemColor: Color(0xFF808080),
        type: BottomNavigationBarType.fixed,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFE0E0E0),
        iconColor: Color(0xFF808080),
        tileColor: Color(0xFF1A1A1A),
        selectedTileColor: Color(0xFF2A2A2A),
      ),
    );
  }

  static Widget customAlertDialog({
    required String title,
    required Widget content,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Agregar',
    String cancelText = 'Cancelar',
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final mq = MediaQuery.of(context);
        // Redondear el inset del teclado para evitar que la altura cambie en cada frame
        // y se produzca el efecto de teclado subiendo/bajando rápido
        final keyboardInset = (mq.viewInsets.bottom / 60).round() * 60.0;
        final maxDialogHeight = (mq.size.height - keyboardInset - 32)
            .clamp(280.0, 560.0);
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxDialogHeight),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Header con título (tamaño fijo)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF2A2A2A).withOpacity(0.5) 
                          : Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark 
                              ? Colors.grey.shade800 
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  
                  // Contenido (altura limitada y scroll si no cabe)
                  // Sin Key en viewInsets para evitar que el teclado suba/baje rápido (rebuilds por frame)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: maxDialogHeight - 220,
                      ),
                      child: SingleChildScrollView(
                        child: content,
                      ),
                    ),
                  ),
                  
                  // Botones
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: isDark 
                                  ? const Color(0xFF2A2A2A) 
                                  : Colors.transparent,
                              side: BorderSide(
                                color: isDark 
                                    ? Colors.grey.shade700 
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              cancelText,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                            child: Text(
                              confirmText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static AlertDialog minimalAlertDialog({
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: null, // Usar el tema del contexto
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: null, // Usar el color del tema
        ),
      ),
      content: content,
      actions: actions,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
    );
  }

  // SnackBar styling methods
  static SnackBar successSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF4CAF50), // Green
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      elevation: 4,
    );
  }

  static SnackBar errorSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE53E3E), // Red
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
      elevation: 4,
    );
  }

  static SnackBar warningSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.warning,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF6AD55), // Orange
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
      elevation: 4,
    );
  }

  static SnackBar infoSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.info,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF3182CE), // Blue
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      elevation: 4,
    );
  }

  // Helper method to show SnackBar with consistent styling
  static void showSnackBar(BuildContext context, SnackBar snackBar) {
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
