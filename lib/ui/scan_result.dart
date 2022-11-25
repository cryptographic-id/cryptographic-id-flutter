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
const textColor = Colors.black;

Text darkText(String text) {
  return Text(text, style: const TextStyle(color: textColor));
}

Widget showValidationError(String title, String error) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
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
    debugPrint(trace.toString());
    Isolate.exit(p, Tuple(item1: false, item2: e));
  }
}

String formatTimestamp(int ts) {
  var date = DateTime.fromMicrosecondsSinceEpoch(ts * 1000000);
  return date.toString();
}

Map<CryptographicId_PersonalInformationType, ValueAddUpdate> idToPersonalInfoMap(
    CryptographicId id) {
  return {
    for (final e in id.personalInformation)
      e.type: ValueAddUpdate(
        property: e.type,
        value: e.content,
        timestamp: e.timestamp.toInt(),
        signature: Uint8List.fromList(e.signature))
  };
}

List<ValueAddUpdate> createAddUpdateList(CryptographicId id, DBKeyInfo? dbKey) {
  var curr = idToPersonalInfoMap(id);
  if (dbKey != null) {
    for (final i in dbKey.personalInformation.entries) {
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
  bool isRecent = false;
  String? error;
  DBKeyInfo? dbKeyInfo;
  CryptographicId id = CryptographicId();
  List<ValueAddUpdate> values = [];

  void _evaluateScan() async {
    try {
      final localization = AppLocalizations.of(context)!;
      final tmpID = CryptographicId.fromBuffer(widget.idBytes);
      final p = ReceivePort();
      await Isolate.spawn(_backgroundVerify, Tuple(item1: p.sendPort,
                                                   item2: tmpID));
      final storage = await getStorage();
      final pubKey = Uint8List.fromList(tmpID.publicKey);
      final keyFromDB = await storage.fetchKeyInfoFromKey(pubKey);
      final result = await p.first;
      var errMsg = null;
      if (result.item1) {
        if (widget.check != null) {
          final toCheck = widget.check!;
          if (!listEquals(toCheck.publicKey, tmpID.publicKey)) {
            errMsg = localization.differentSignature(toCheck.name);
          } else {
            if (keyFromDB != null) {
              if (keyFromDB.name != toCheck.name) {
                errMsg = localization.databaseNameDiffers(
                  keyFromDB.name, toCheck.name);
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
        valuesToAdd = createAddUpdateList(tmpID, keyFromDB);
      }
      // caluclate recent here, otherwise navigator.pop will
      // change the screen
      final tmpIsRecent = crypto.isSignatureRecent(tmpID);

      setState(() {
        loaded = true;
        id = tmpID;
        dbKeyInfo = keyFromDB;
        error = errMsg;
        isRecent = tmpIsRecent;
        values = valuesToAdd;
      });
    } catch (e, trace) {
      debugPrint(trace.toString());
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
    bool showAddUpdate = (dbKeyInfo == null) || (values.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        // no darkText, since title background is not changed
        title: Text(localization.validResult),
      ),
      backgroundColor: background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localization.signatureCorrect,
              style: const TextStyle(fontWeight: FontWeight.w900, color: textColor)),
            showName,
            showIsRecent,
            darkText(localization.signedDate(formatTimestamp(id.timestamp.toInt()))),
            darkText(""),
            if (showAddUpdate) ElevatedButton(
              onPressed: () async {
                final res = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (c) => AddOrUpdate(
                      dbKeyInfo: dbKeyInfo,
                      id: id,
                      values: values),
                  ),
                );
                if (res != null && mounted) {
                  Navigator.of(context).pop(res);
                }
              },
              child: Text(
                dbKeyInfo == null ? localization.addButton : localization.updateButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
