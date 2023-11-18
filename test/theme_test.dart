import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cryptographic_id/theme.dart' as theme;

void main() {
  test('materialColorFromRGB', () async {
    expect(
      theme.materialColorFromRGB(15, 27, 39),
      const MaterialColor(
        0xff0f1b27,
        {
          50: Color(0x190f1b27),
          100: Color(0x330f1b27),
          200: Color(0x4c0f1b27),
          300: Color(0x660f1b27),
          400: Color(0x7f0f1b27),
          500: Color(0x990f1b27),
          600: Color(0xb20f1b27),
          700: Color(0xcc0f1b27),
          800: Color(0xe50f1b27),
          900: Color(0xff0f1b27),
        }
      ),
    );
  });

  test('createThemeData', () async {
    expect(
      theme.createThemeData(true),
      ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff424242),
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: theme.materialColorFromRGB(255, 255, 255),
          brightness: Brightness.dark,
          backgroundColor: theme.materialColorFromRGB(34, 34, 34),
          accentColor: theme.materialColorFromRGB(250, 138, 41),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey[700],
        ),
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey[700]!,
            ),
          ),
        ),
      )
    );
    final primarySwatchLight = theme.materialColorFromRGB(62, 145, 74);
    final backgroundLight = theme.materialColorFromRGB(255, 255, 255);
    final lightTheme = theme.createThemeData(false);
    // Cannot compare MaterialStateProperty directly
    final buttonStyle = lightTheme.elevatedButtonTheme.style;
    expect(
      lightTheme.elevatedButtonTheme.style,
      ButtonStyle(
        foregroundColor: buttonStyle?.foregroundColor!,
        backgroundColor: buttonStyle?.backgroundColor!,
      )
    );
    expect(
      buttonStyle!.foregroundColor!.resolve(
        <MaterialState>{MaterialState.error}),
      backgroundLight[900]!);
    expect(
      buttonStyle.backgroundColor!.resolve(
        <MaterialState>{MaterialState.error}),
      primarySwatchLight[900]!);
    expect(
      lightTheme,
      ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: primarySwatchLight[900]!,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: primarySwatchLight,
          brightness: Brightness.light,
          backgroundColor: backgroundLight,
          accentColor: theme.materialColorFromRGB(211, 79, 58),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey[300],
        ),
        elevatedButtonTheme: lightTheme.elevatedButtonTheme,
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey[300]!,
            ),
          ),
        ),
      )
    );
  });
}
