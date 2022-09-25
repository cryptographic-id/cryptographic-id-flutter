import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../crypto.dart' as crypto;
import '../protocol/cryptograhic_id.pb.dart';
import '../storage.dart';
import '../tuple.dart';
import './loading_screen.dart';


Widget scanErrorMsg(String error) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Scan failed"),
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

class ScanResult extends StatefulWidget {
  const ScanResult({Key? key, required this.idBytes, required this.check}) : super(key: key);
  final Uint8List idBytes;
  final PublicKey? check;

  @override
  State<ScanResult> createState() => _ScanResultState();
}

Future<void> _backgroundVerify(Tuple<SendPort, CryptographicId> params) async {
  final p = params.item1;
  final result = await crypto.verifyCryptographicId(params.item2);
  Isolate.exit(p, result);
}

class _ScanResultState extends State<ScanResult> {
  bool loaded = false;
  String? error = "";
  CryptographicId id = CryptographicId();

  void _evaluateScan() async {
    try {
      final tmp_id = CryptographicId.fromBuffer(widget.idBytes);
      final p = ReceivePort();
      await Isolate.spawn(_backgroundVerify, Tuple(item1: p.sendPort,
                                                   item2: tmp_id));
      final result = await p.first;
      var verified = null;
      var errMsg = null;
      if (result) {
        if (widget.check != null) {
          if (widget.check!.publicKey != tmp_id.publicKey) {
            errMsg = "Signature does not belong to user " + widget.check!.name!;
          }
        }
      } else {
        errMsg = "Signature is not correct";
      }

      setState(() {
        loaded = true;
        id = tmp_id;
        error = errMsg;
      });
    } catch (e, trace) {
      setState(() {
        loaded = true;
        error = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _evaluateScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return loadingScreen("Verifying");
    }
    if (error != null) {
      return scanErrorMsg(error!);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Result: valid"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Scanned:',
            ),
            Text("Length: " + widget.idBytes.length.toString()),
          ],
        ),
      ),
    );
  }
}
