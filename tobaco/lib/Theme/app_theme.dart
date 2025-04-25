import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color confirmButtonColor = Colors.green;
  static const Color cancelButtonColor = Colors.white;
  static const Color secondaryColor = Color(0xFFE9F3EF); // Verde para impares
  static const Color greyColor = Color(0xFFDBDBDB); // Gris claro para pares
  static const Color textColor = Colors.black;
  static const Color textGreyColor = Colors.grey;
  static const Color addGreenColor = Colors.green;

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

  static AlertDialog alertDialogStyle({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          color: textColor,
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
      borderRadius: BorderRadius.all(Radius.circular(30)),
    ),
    prefixIcon: Icon(
      Icons.search,
      color: Colors.grey,
      size: 15,
    ),
    filled: true,
    fillColor: Color.fromRGBO(255, 255, 255, 1),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
      borderSide: BorderSide(
        color: Color.fromRGBO(200, 200, 200, 1),
        width: 1.0,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
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

  static ButtonStyle elevatedButtonStyle(Color backgroundColor) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: backgroundColor,
    );
  }

  static ButtonStyle outlinedButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    side: const BorderSide(color: Colors.grey),
    backgroundColor: Colors.white,
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
    fontSize: 35,
    color: textColor,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 16,
    color: textColor,
  );

  static const TextStyle sectionContentStyle = TextStyle(
    fontSize: 16,
    color: textColor,
  );

  static const TextStyle itemListaNegrita = TextStyle(
    color: textColor,
    fontSize: 16,
    fontWeight: FontWeight.bold
  );

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
      primarySwatch: Colors.blue,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemStatusBarContrastEnforced: false,
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Shippori',
          fontSize: 30,
          color: Colors.black,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        prefixIconColor: Colors.grey,
        filled: true,
        fillColor: Color.fromRGBO(255, 255, 255, 1),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          borderSide: BorderSide(
            color: Color.fromRGBO(200, 200, 200, 1),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
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
}
