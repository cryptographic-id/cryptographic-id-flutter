import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../crypto.dart' as crypto;
import '../protocol/cryptograhic_id.pb.dart';
import '../storage.dart';
import '../tuple.dart';
import './add_or_update.dart';
import './loading_screen.dart';

// black is viewable on green/red/yellow screen in dark and light mode
final textColor = Colors.black;

Text darkText(String text) {
  return new Text(text, style:TextStyle(color: textColor));
}

Widget showValidationError(String title, String error) {
  return Scaffold(
    appBar: AppBar(
      title: new Text(title),
    ),
    backgroundColor: Colors.redAccent.shade400,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          darkText(error),
        ],
      ),
    ),
  );
}

class ScanResult extends StatefulWidget {
  const ScanResult({Key? key, required this.idBytes, required this.check}) : super(key: key);
  final Uint8List idBytes;
  final DBKeyInfo? check;

  @override
  State<ScanResult> createState() => _ScanResultState();
}

Future<void> _backgroundVerify(Tuple<SendPort, CryptographicId> params) async {
  final p = params.item1;
  try {
    final result = await crypto.verifyCryptographicId(params.item2);
    Isolate.exit(p, Tuple(item1: result, item2: null));
  } catch (e, trace) {
    Isolate.exit(p, Tuple(item1: false, item2: e));
  }
}

String formatTimestamp(int ts) {
  var date = new DateTime.fromMicrosecondsSinceEpoch(ts * 1000000);
  return date.toString();
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

List<ValueAddUpdate> createAddUpdateList(CryptographicId id, DBKeyInfo? dbKey) {
  var curr = idToPersonalInfoMap(id);
  if (dbKey != null) {
    for (final i in dbKey!.personalInformation.entries) {
      final e = i.value;
      if (curr.containsKey(e.property)) {
        final elem = curr[e.property]!;
        if (elem.value == e.value) {
          curr.remove(e.property);
        } else {
          elem.oldValue = e.value;
        }
      }
    }
  }
  return curr.entries.map((e) => e.value).toList();
}

class _ScanResultState extends State<ScanResult> {
  bool loaded = false;
  String? error;
  DBKeyInfo? dbKeyInfo;
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
      final keyFromDB = await storage.fetchKeyInfoFromKey(pubKey);
      final result = await p.first;
      var verified = null;
      var errMsg = null;
      final localization = AppLocalizations.of(context)!;
      if (result.item1) {
        if (widget.check != null) {
          if (!listEquals(widget.check!.publicKey, tmp_id.publicKey)) {
            errMsg = localization.differentSignature(widget.check!.name!);
          } else {
            if (keyFromDB != null) {
              if (keyFromDB!.name != widget.check!.name) {
                errMsg = localization.databaseNameDiffers(
                  keyFromDB!.name, widget.check!.name);
              }
            }
          }
        }
      } else {
        if (result.item2 != null) {
          errMsg = result.item2.toString();
        } else {
          errMsg = localization.corruptSignature;
        }
      }
      List<ValueAddUpdate> valuesToAdd = [];
      if (errMsg == null) {
        valuesToAdd = createAddUpdateList(tmp_id, keyFromDB);
      }

      setState(() {
        loaded = true;
        id = tmp_id;
        dbKeyInfo = keyFromDB;
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
    final localization = AppLocalizations.of(context)!;
    if (!loaded) {
      return loadingScreen(localization.waitForVerification);
    }
    if (error != null) {
      return showValidationError(localization.validationFailed, error!);
    }
    final isRecent = crypto.isSignatureRecent(id);
    Color background = Colors.green;
    var showName = darkText(localization.unkownKey);
    var showIsRecent = darkText(localization.recentSignature);
    if (!isRecent) {
      background = Colors.yellow;
      showIsRecent = darkText(localization.oldSignature);
    }
    if (dbKeyInfo == null) {
      background = Colors.orange;
    } else {
      showName = darkText(localization.showName(dbKeyInfo!.name));
    }
    bool showAddUpdate = (dbKeyInfo == null) || (values.length > 0);

    return Scaffold(
      appBar: AppBar(
        // no darkText, since title background is not changed
        title: new Text(localization.validResult),
      ),
      backgroundColor: background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localization.signatureCorrect,
              style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
            showName,
            showIsRecent,
            darkText(localization.signedDate(formatTimestamp(id.timestamp.toInt()))),
            darkText(""),
            if (showAddUpdate) TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.all(15),
                foregroundColor: textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.indigo),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (c) => AddOrUpdate(
                      dbKeyInfo: dbKeyInfo,
                      id: id,
                      values: values),
                  ),
                );
              },
              child: Text(
                dbKeyInfo == null ? localization.addButton : localization.updateButton,
                style: TextStyle(color: Colors.indigo)),
            ),
          ],
        ),
      ),
    );
  }
}
