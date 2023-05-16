import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/protobuf/cryptographic_id.pb.dart';

import '../crypto.dart' as crypto;
import '../storage.dart';
import '../tuple.dart';
import './add_or_update.dart';
import './loading_screen.dart';

// black is viewable on green/red/yellow screen in dark and light mode
const textColor = Colors.black;

SelectableText darkText(String text, [FontWeight? weight]) {
  return SelectableText(
    text, style:
    TextStyle(
      color: textColor,
      fontWeight: weight,
    )
  );
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
  const ScanResult({
    Key? key,
    required this.data,
    required this.checkIdentity,
  }) : super(key: key);
  final String data;
  final DBIdentity? checkIdentity;

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

String bytesToString(List<int> msg) {
  return utf8.decode(msg, allowMalformed: true);
}

Map<CryptographicId_PersonalInformationType, ValueAddUpdate> idToPersonalInfoMap(
    CryptographicId id) {
  return {
    for (final e in id.personalInformation)
      e.type: ValueAddUpdate(
        property: e.type,
        value: bytesToString(e.value),
        timestamp: e.timestamp.toInt(),
        signature: Uint8List.fromList(e.signature))
  };
}

List<ValueAddUpdate> createAddUpdateList(CryptographicId id, DBIdentity? dbKey) {
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
  int scannedTime = crypto.now();
  String? error;
  DBIdentity? dbKeyInfo;
  CryptographicId id = CryptographicId();
  List<ValueAddUpdate> values = [];

  void _evaluateScan() async {
    try {
      final localization = AppLocalizations.of(context)!;
      final tmpID = CryptographicId.fromBuffer(base64.decode(widget.data));
      // calculate recent here and asap, otherwise a refresh will
      // change the result
      final tmpIsRecent = crypto.isSignatureRecent(tmpID);
      final p = ReceivePort();
      await Isolate.spawn(_backgroundVerify, Tuple(item1: p.sendPort,
                                                   item2: tmpID));
      final storage = await getStorage();
      final pubKey = Uint8List.fromList(tmpID.publicKey);
      final keyFromDB = await storage.fetchKeyInfoFromKey(pubKey);
      final result = await p.first;
      var errMsg = null;
      if (result.item1) {
        if (widget.checkIdentity != null) {
          final checkIdentity = widget.checkIdentity!;
          if (!listEquals(checkIdentity.publicKey, tmpID.publicKey)) {
            errMsg = localization.differentSignature(checkIdentity.name);
          } else {
            if (keyFromDB != null) {
              if (keyFromDB.name != checkIdentity.name) {
                errMsg = localization.databaseNameDiffers(
                  keyFromDB.name, checkIdentity.name);
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
    var showIsRecent = darkText(localization.recentSignature, FontWeight.w900);
    if (!isRecent) {
      background = Colors.yellow;
      showIsRecent = darkText(localization.oldSignature, FontWeight.w900);
    }
    if (dbKeyInfo == null) {
      background = Colors.orange;
    } else {
      showName = darkText(localization.showName(dbKeyInfo!.name));
    }

    final publicKey = crypto.formatPublicKey(
      Uint8List.fromList(id.publicKey), id.publicKeyType);
    final publicKeyText = darkText(publicKey);
    bool showAddUpdate = (dbKeyInfo == null) || (values.isNotEmpty);
    final int signed = crypto.oldestTimestamp(id);
    final int signatureAge = scannedTime - signed;
    final signatureTimeText = signatureAge >= 0 ?
      localization.signatureAgePast(signatureAge) :
      localization.signatureAgeFuture(- signatureAge);

    return Scaffold(
      appBar: AppBar(
        // no darkText, since title background is not changed
        title: Text(localization.validResult),
      ),
      backgroundColor: background,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              darkText(localization.signatureCorrect, FontWeight.w900),
              showName,
              const SizedBox(height: 15),
              darkText(localization.publicKeyType(
                id.publicKeyType.toString()), FontWeight.w900),
              publicKeyText,
              const SizedBox(height: 15),
              showIsRecent,
              darkText(localization.signedDate(formatTimestamp(signed))),
              darkText(signatureTimeText),
              darkText(""),
              darkText(localization.showMessage, FontWeight.w900),
              darkText(bytesToString(id.msg)),
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
          )
        ),
      ),
    );
  }
}
