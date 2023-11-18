import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import './theme.dart';
import './ui/overview.dart';

void main() {
  runApp(const CryptographicID());
}

class CryptographicID extends StatelessWidget {
  const CryptographicID({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const title = 'Cryptographic ID';
    return MaterialApp(
      title: title,
      darkTheme: createThemeData(true),
      theme: createThemeData(false),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ContactOverview(title: title),
    );
  }
}
