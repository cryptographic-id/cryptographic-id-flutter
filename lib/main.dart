import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import './qr_scan.dart';
import './storage.dart';
import './ui/loading_screen.dart';
import './ui/scan_result.dart';
import './ui/error_screen.dart';


void main() {
  runApp(const CryptographicID());
}

class CryptographicID extends StatelessWidget {
  const CryptographicID({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cryptograhpic ID',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
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

class ContactOverview extends StatefulWidget {
  const ContactOverview({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<ContactOverview> createState() => _ContactOverviewState();
}

class _ContactOverviewState extends State<ContactOverview> {
  bool loaded = false;
  String? error;
  List<DBKeyInfo> keys = [];

  Future<void> scan(DBKeyInfo? compare) async {
    String title = AppLocalizations.of(context)!.scanContact;
    if (compare != null) {
      title = AppLocalizations.of(context)!.scanContactName(compare.name);
    }
    final qr = await scanQRCodeAsync(title, context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => ScanResult(idBytes: qr, check: compare),
      ),
    ).then((flag) => _loadData());
  }

  void _loadData() async {
    try {
      final storage = await getStorage();
      final dBkeys = await storage.fetchKeyInfos();
      setState(() {
        loaded = true;
        keys = dBkeys;
        error = null;
      });
    } catch (e) {
      setState(() {
        loaded = true;
        keys = [];
        error = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    if (!loaded) {
      return loadingScreen(localization.appInit);
    }
    if (error != null) {
      return showError(localization.appInitFailed, error!);
    }
    final children = ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final pos = i;
        return new TextButton(
          onPressed: () async {
            await scan(keys[pos]);
          },
          child: Text(localization.showName(keys[pos].name)),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: children,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await scan(null);
        },
        tooltip: localization.qrScanTooltip,
        child: const Icon(Icons.qr_code_scanner_outlined),
      ),
    );
  }
}
