import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fixnum/fixnum.dart' as fixnum;

import '../crypto.dart' as crypto;
import '../personal_information.dart';
import '../protocol/cryptograhic_id.pb.dart';
import '../qr_show.dart';
import '../storage.dart';

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
        content: e.value,
        timestamp: now,
      )
    );
  }
  return result;
}

class SignOwnID extends StatefulWidget {
  const SignOwnID({
    Key? key,
    required this.id,
  }) : super(key: key);
  final DBKeyInfo id;

  @override
  State<SignOwnID> createState() => _SignOwnIDState();
}

class _SignOwnIDState extends State<SignOwnID> {
  final _toShare = <CryptographicId_PersonalInformationType>{};

  void showQR() async {
    final useID = filterIDFromSet(widget.id, _toShare);
    final cryptoID = cryptographicIdFromDB(useID);
    final storage = await getStorage();
    final privateKey = await storage.secureBinaryRead(
      SecureBinary.privateKey);
    await crypto.signCryptographicId(cryptoID, privateKey!);
    final data = cryptoID.writeToBuffer();
    if (mounted) {
      final localization = AppLocalizations.of(context)!;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => ShowQR(
            title: localization.shareID,
            data: data,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final elements = <Widget>[];

    for (final pit in CryptographicId_PersonalInformationType.values) {
      if (widget.id.personalInformation.containsKey(pit)) {
        final val = widget.id.personalInformation[pit]!;
        final prop = localizePersonalInformationType(localization, pit);
        String title = localization.addDetail(prop, val.value);
        elements.add(
          CheckboxListTile(
            title: Text(title),
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
    elements.add(ElevatedButton(
      onPressed: showQR,
      child: Text(
        localization.createQRCode,
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.shareID),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: elements,
        ),
      ),
    );
  }
}
