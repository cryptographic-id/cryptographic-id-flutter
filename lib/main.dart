import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import './ui/overview.dart';


void main() {
  runApp(const CryptographicID());
}

MaterialColor MaterialColorFromRGB(int r, int g, int b) {
  Map<int, Color> colorCodes = {
    50: Color.fromRGBO(r, g, b, .1),
  };
  for (int i = 1; i < 10; i++) {
    colorCodes[i * 100] = Color.fromRGBO(r, g, b, (i + 1) / 10);
  }
  var code = 0xFF000000 | r << 16 | g << 8 | b;
  return MaterialColor(code, colorCodes);
}

class CryptographicID extends StatelessWidget {
  const CryptographicID({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cryptograhpic ID',
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColorFromRGB(218, 218, 218),
          brightness: Brightness.dark,
          backgroundColor: MaterialColorFromRGB(34, 34, 34),
          accentColor: MaterialColorFromRGB(250, 138, 41),
        ),
      ),
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColorFromRGB(37, 125, 49),
          brightness: Brightness.light,
          backgroundColor: MaterialColorFromRGB(231, 231, 231),
          accentColor: MaterialColorFromRGB(211, 79, 58),
        ),
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ContactOverview(title: 'Cryptograhpic ID'),
    );
  }
}
