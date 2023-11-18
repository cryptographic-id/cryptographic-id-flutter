import 'package:flutter/material.dart';

MaterialColor materialColorFromRGB(int r, int g, int b) {
  Map<int, Color> colorCodes = {
    50: Color.fromRGBO(r, g, b, .1),
  };
  for (int i = 1; i < 10; i++) {
    colorCodes[i * 100] = Color.fromRGBO(r, g, b, (i + 1) / 10);
  }
  var code = 0xFF000000 | r << 16 | g << 8 | b;
  return MaterialColor(code, colorCodes);
}

ThemeData createThemeData(bool dark) {
  final primarySwatch = dark ?
    materialColorFromRGB(255, 255, 255) : materialColorFromRGB(62, 145, 74);
  final dividerColor = dark ? Colors.grey[700]! : Colors.grey[300]!;
  final backgroundColor = dark ?
    materialColorFromRGB(34, 34, 34) : materialColorFromRGB(255, 255, 255);
  final elevatedButtenTheme = dark ? null : ElevatedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: MaterialStatePropertyAll<Color>(
        backgroundColor[900]!
      ),
      backgroundColor: MaterialStatePropertyAll<Color>(
        primarySwatch[900]!
      ),
    ),
  );
  return ThemeData(
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xff424242) : primarySwatch[900]!,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: primarySwatch,
      brightness: dark ? Brightness.dark : Brightness.light,
      backgroundColor: backgroundColor,
      accentColor: dark ?
        materialColorFromRGB(250, 138, 41): materialColorFromRGB(211, 79, 58),
    ),
    dividerTheme: DividerThemeData(
      color: dividerColor,
    ),
    elevatedButtonTheme: elevatedButtenTheme,
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: dividerColor,
        ),
      ),
    ),
  );
}
