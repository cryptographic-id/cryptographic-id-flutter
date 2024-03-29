import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/protobuf/cryptographic_id.pb.dart';
import '../personal_information.dart';
import '../storage.dart';

class ShowID extends StatelessWidget {
  const ShowID({Key? key, required this.id, required this.scan}) : super(key: key);
  final DBIdentity id;
  final Function(BuildContext context) scan;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final formList = <Widget>[];
    // iterate over pits, so the order makes sense and is deterministic
    for (final pit in CryptographicId_PersonalInformationType.values) {
      if (id.personalInformation.containsKey(pit)) {
        final elem = TextEditingController();
        elem.text = id.personalInformation[pit]!.value;
        formList.add(
          pitToDisabledTextFormField(
            pit: pit,
            value: id.personalInformation[pit]!.value,
            localization: localization)
        );
      }
    }
    formList.add(fingerprintFormField(localization, id.publicKeyType,
                                      id.publicKey));
    if (id.publicKeyType == CryptographicId_PublicKeyType.Prime256v1) {
      formList.add(fingerprintFormField(localization, id.publicKeyType,
                                        id.publicKey, true));
    }

    ListView body = ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        const SizedBox(height: 20),
        Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: formList,
          ),
        )
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.showID(id.name)),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            iconSize: 30,
            padding: const EdgeInsets.fromLTRB(40, 5, 10, 5),
            tooltip: localization.scanContactName(id.name),
            onPressed: () {
              // data will be outdated, if updated
              Navigator.of(context).pop();
              scan(context);
            },
          ),
        ],
      ),
      body: body,
    );
  }
}
