import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../crypto.dart' as crypto;
import '../protocol/cryptograhic_id.pb.dart';
import '../qr_show.dart';
import './loading_screen.dart';


class ScanResult extends StatefulWidget {
  const ScanResult({Key? key, required this.idBytes}) : super(key: key);
  final Uint8List idBytes;

  @override
  State<ScanResult> createState() => _ScanResultState();
}

class _ScanResultState extends State<ScanResult> {
  bool loaded = false;
  bool verified = false;
  CryptographicId id = CryptographicId();

  void evaluateScan() async {
    final tmp_id = CryptographicId.fromBuffer(widget.idBytes);
    final result = await crypto.verifyCryptographicId(tmp_id);

    setState(() {
      verified = result;
      id = tmp_id;
      loaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        evaluateScan();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return loadingScreen("Verifying");
    }
    final title = verified ? "valid" : "invalid";
    return Scaffold(
      appBar: AppBar(
        title: Text("Result: " + title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Scanned:',
            ),
            Text("Length: " + widget.idBytes.length.toString()),
            showQRCode(widget.idBytes),
          ],
        ),
      ),
    );
  }
}
