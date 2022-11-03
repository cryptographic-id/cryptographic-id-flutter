import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import './qr_scan.dart';
import './storage.dart';
import './ui/loading_screen.dart';
import './ui/scan_result.dart';


void main() {
  runApp(const MyApp());
}

Widget showError(String error) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Failed to initialize"),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(error),
        ],
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cryptograhpic ID',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const MyHomePage(title: 'Cryptograhpic ID'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loaded = false;
  String? error;
  List<DBKeyInfo> keys = [];

  Future<void> scan(DBKeyInfo? compare) async {
    String text = "";
    if (compare != null) {
      text = " (" + compare.name + ")";
    }
    final qr = await scanQRCodeAsync(text, context);
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
    if (!loaded) {
      return loadingScreen("Starting");
    }
    if (error != null) {
      return showError(error!);
    }
    final children = ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final pos = i;
        return new TextButton(
          onPressed: () async {
            await scan(keys[pos]);
          },
          child: Text("Name: " + keys[pos].name));
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
        tooltip: 'Add new id',
        child: const Icon(Icons.qr_code_scanner_outlined),
      ),
    );
  }
}
