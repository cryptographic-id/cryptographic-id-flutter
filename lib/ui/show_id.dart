import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../crypto.dart';
import '../personal_information.dart';
import '../protocol/cryptograhic_id.pb.dart';
import '../storage.dart';

class ShowID extends StatelessWidget {
  const ShowID({Key? key, required this.id, required this.scan}) : super(key: key);
  final DBKeyInfo id;
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
          TextFormField(
            controller: elem,
            enabled: false,
            decoration: InputDecoration(
              labelText: localizePersonalInformationType(localization, pit),
              icon: Icon(pitToIcon(pit)),
            ),
          )
        );
      }
    }
    final pubKeyController = TextEditingController();
    pubKeyController.text = formatPublicKey(id.publicKey);
    formList.add(
      TextFormField(
        controller: pubKeyController,
        readOnly: true,
        minLines: 4,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: localization.publicKey,
          icon: const Icon(Icons.fingerprint),
        ),
      )
    );

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
