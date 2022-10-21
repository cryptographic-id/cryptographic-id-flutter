import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../crypto.dart' as crypto;
import '../protocol/cryptograhic_id.pb.dart';
import '../storage.dart';
import '../tuple.dart';
import './loading_screen.dart';


Widget showScanError(String error) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Scan failed"),
    ),
    backgroundColor: Colors.redAccent.shade400,
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

String formatTimestamp(int ts) {
  var date = new DateTime.fromMicrosecondsSinceEpoch(ts * 1000000);
  return date.toString();
}

class ValueAddUpdate {
  bool checked = false;
  final String property;
  final String value;
  String? oldValue;
  int timestamp;
  Uint8List signature;

  ValueAddUpdate({
    required this.property,
    required this.value,
    this.oldValue,
    required this.timestamp,
    required this.signature,
  });
}

Map<String, ValueAddUpdate> idToPersonalInfoMap(CryptographicId id) {
  return Map.fromIterable(
    id.personalInformation,
    key: (e) => e.type.toString(),
    value: (e) => new ValueAddUpdate(
      property: e.type.toString(),
      value: e.content,
      timestamp: e.timestamp.toInt(),
      signature: e.signature));
}

List<ValueAddUpdate> createAddUpdateList(CryptographicId id, PublicKey? dbKey) {
  var curr = idToPersonalInfoMap(id);
  if (dbKey != null) {
    for (final i in dbKey!.personalInformation.entries) {
      final e = i.value;
      if (curr.containsKey(e.property)) {
        final elem = curr[e.property]!;
        final val = elem.value;
        if (val == e.value) {
          curr.remove(e.property);
        } else {
          elem.oldValue = elem.value;
        }
      }
    }
  }
  return curr.entries.map((e) => e.value).toList();
}

class _ScanResultState extends State<ScanResult> {
  bool loaded = false;
  String? error;
  PublicKey? dbID;
  CryptographicId id = CryptographicId();
  List<ValueAddUpdate> values = [];

  void _evaluateScan() async {
    try {
      final tmp_id = CryptographicId.fromBuffer(widget.idBytes);
      final p = ReceivePort();
      await Isolate.spawn(_backgroundVerify, Tuple(item1: p.sendPort,
                                                   item2: tmp_id));
      final storage = await getStorage();
      final pubKey = Uint8List.fromList(tmp_id.publicKey);
      final keyFromDB = await storage.fetchPublicKeyFromKey(pubKey);
      final result = await p.first;
      var verified = null;
      var errMsg = null;
      if (result) {
        if (widget.check != null) {
          if (widget.check!.publicKey != tmp_id.publicKey) {
            errMsg = "Signature does not belong to user " + widget.check!.name!;
          } else {
            if (keyFromDB != null) {
              if (keyFromDB!.name != widget.check!.name) {
                errMsg = "Wierd! Signature matches, but database name differs";
              }
            }
          }
        }
      } else {
        errMsg = "Signature is not correct";
      }
      List<ValueAddUpdate> valuesToAdd = [];
      if (errMsg == null) {
        valuesToAdd = createAddUpdateList(tmp_id, keyFromDB);
      }

      setState(() {
        loaded = true;
        id = tmp_id;
        dbID = keyFromDB;
        error = errMsg;
        values = valuesToAdd;
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
      return showScanError(error!);
    }
    final isRecent = crypto.isSignatureRecent(id);
    final missingDetails = values.map((ValueAddUpdate val) {
      return new CheckboxListTile(
        title: new Text(val.property + ": " + val.value),
        // oldValue
        value: val.checked,
        onChanged: (bool? value) {
          if (value == null) {
            return;
          }
          setState(() {
            val.checked = value!;
          });
        },
      );
    }).toList();
    Color background = Colors.green;
    String status = "Sigatues correct";
    if (dbID == null) {
      background = Colors.orange;
      // Text: not known
    }
    if (!isRecent) {
      background = Colors.yellow;
      // Text: not recent
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Result: valid"),
      ),
      backgroundColor: background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Signatures correct",
              style: TextStyle(fontWeight: FontWeight.w900)),
            new Text("Signed on " + formatTimestamp(id.timestamp.toInt())),
            const Text(""),
            new Text(
              "Add or update values",
              style: TextStyle(fontWeight: FontWeight.w900)),
            ...missingDetails],
          // dynamic Button to update / add
        ),
      ),
    );
  }
}
