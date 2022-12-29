import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter_gen/protobuf/cryptographic_id.pb.dart';

import '../crypto.dart' as crypto;
import '../personal_information.dart';
import '../qr_show.dart';
import '../storage.dart';
import './loading_screen.dart';

DBKeyInfo filterIDFromSet(DBKeyInfo id, Set<CryptographicId_PersonalInformationType> use) {
  final Map<CryptographicId_PersonalInformationType,
            PersonalInformation> info = Map.from(id.personalInformation);
  info.removeWhere((k, v) => !use.contains(k));
  return DBKeyInfo(
    name: id.name,
    publicKey: id.publicKey,
    date: id.date,
    signature: id.signature,
    personalInformation: info,
  );
}

CryptographicId cryptographicIdFromDB(DBKeyInfo id) {
  final now = fixnum.Int64(crypto.now());
  CryptographicId result = CryptographicId();
  result.timestamp = now;
  result.publicKey = id.publicKey;
  for (final e in id.personalInformation.values) {
    result.personalInformation.add(
      CryptographicId_PersonalInformation(
        type: e.property,
        value: e.value,
        timestamp: now,
      )
    );
  }
  return result;
}

class ShareOwnID extends StatefulWidget {
  const ShareOwnID({
    Key? key,
    required this.id,
  }) : super(key: key);
  final DBKeyInfo id;

  @override
  State<ShareOwnID> createState() => _ShareOwnIDState();
}

class _ShareOwnIDState extends State<ShareOwnID> {
  final _toShare = <CryptographicId_PersonalInformationType>{};
  final TextEditingController _msgController = TextEditingController();
  bool _signing = false;

  void showQR() async {
    setState(() {
      _signing = true;
    });
    final useID = filterIDFromSet(widget.id, _toShare);
    final cryptoID = cryptographicIdFromDB(useID);
    cryptoID.msg = _msgController.text.codeUnits;
    final storage = await getStorage();
    final privateKey = await storage.secureBinaryRead(
      SecureBinary.privateKey);
    await crypto.signCryptographicId(cryptoID, privateKey!);
    final data = cryptoID.writeToBuffer();
    final str = base64.encode(data);
    setState(() {
      _signing = false;
    });
    if (mounted) {
      final localization = AppLocalizations.of(context)!;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => ShowQR(
            title: localization.shareID,
            data: str,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    if (_signing) {
      return loadingScreen(localization.waitForSignature);
    }
    final elements = <Widget>[];
    elements.add(
      ListTile(
        title: TextFormField(
          controller: _msgController,
          decoration: InputDecoration(
            labelText: localization.shareMessage,
            icon: const Icon(Icons.message),
          ),
          keyboardType: TextInputType.text,
        ),
      ),
    );

    for (final pit in CryptographicId_PersonalInformationType.values) {
      if (widget.id.personalInformation.containsKey(pit)) {
        final val = widget.id.personalInformation[pit]!;
        elements.add(
          CheckboxListTile(
            title: IgnorePointer(child: pitToDisabledTextFormField(
              pit: val.property,
              value: val.value,
              localization: localization)),
            value: _toShare.contains(pit),
            onChanged: (bool? value) {
              if (value == null) {
                return;
              }
              setState(() {
                if (value) {
                  _toShare.add(pit);
                } else {
                  _toShare.remove(pit);
                }
              });
            },
          )
        );
      }
    }
    final button = ElevatedButton(
      onPressed: showQR,
      child: Text(
        localization.createQRCode,
      ),
    );
    // add gap for floatingActionButton
    elements.add(const SizedBox(height: 75));
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.shareID),
      ),
      body: ListView(
        children: elements,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: button,
    );
  }
}
