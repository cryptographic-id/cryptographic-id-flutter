import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/protobuf/cryptographic_id.pb.dart';

import '../storage.dart';
import '../personal_information.dart';
import './error_screen.dart';

class ValueAddUpdate {
  bool update = false;
  final CryptographicId_PersonalInformationType property;
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

DBKeyInfo createDatabaseObject(String name,
                               CryptographicId id,
                               List<ValueAddUpdate> values,
                               DBKeyInfo? dbKey) {
  final Map<CryptographicId_PersonalInformationType,
            PersonalInformation> updateInfo = {
    for (final v in values)
      if (v.update)
        v.property: PersonalInformation(
          property: v.property,
          value: v.value,
          date: v.timestamp,
          signature: Uint8List.fromList(v.signature),
        )
  };
  if (dbKey == null) {
    return DBKeyInfo(
      name: name,
      publicKey: Uint8List.fromList(id.publicKey),
      date: id.timestamp.toInt(),
      signature: Uint8List.fromList(id.signature),
      personalInformation: updateInfo,
    );
  }
  for (final e in updateInfo.entries) {
    dbKey.personalInformation[e.value.property] = e.value;
  }
  return dbKey;
}

class AddOrUpdate extends StatefulWidget {
  const AddOrUpdate({
    Key? key,
    required this.dbKeyInfo,
    required this.values,
    required this.id}) : super(key: key);
  final DBKeyInfo? dbKeyInfo;
  final List<ValueAddUpdate> values;
  final CryptographicId id;

  @override
  State<AddOrUpdate> createState() => _AddOrUpdateState();
}

class _AddOrUpdateState extends State<AddOrUpdate> {
  bool nameValid = false;
  String currName = "";

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final missingDetails = widget.values.map((ValueAddUpdate val) {
      String value = val.oldValue == null ?
        val.value :
        localization.updateDetail(val.value, val.oldValue!);
      return CheckboxListTile(
        title: pitToDisabledTextFormField(
          pit: val.property,
          value: value,
          localization: localization),
        value: val.update,
        onChanged: (bool? value) {
          if (value == null) {
            return;
          }
          setState(() {
            val.update = value;
          });
        },
      );
    }).toList();
    final elements = <Widget>[const SizedBox(height: 40)];
    if (widget.dbKeyInfo != null) {
      elements.add(Text(
        localization.showName(widget.dbKeyInfo!.name),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold)));
      elements.add(const SizedBox(height: 10));
      nameValid = true;
    } else {
      elements.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber),
          Text(localization.nameCannotBeChanged),
        ],
      ));
      elements.add(Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        child: TextFormField(
          onChanged: (text) async {
            final storage = await getStorage();
            final exists = await storage.existsKeyInfoWithName(text);
            setState(() {
              nameValid = text != "" && !exists;
              currName = text;
            });
          },
          keyboardType: TextInputType.text,
          maxLines: 1,
          autocorrect: false,
          autofocus: true,
          enableSuggestions: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp("[a-z0-9]")),
          ],
          decoration: InputDecoration(
            hintText: localization.allowedNameChars,
            labelText: localization.name,
            icon: const Icon(Icons.person),
          ),
        ),
      ));
    }
    missingDetails.forEach(elements.add);
    final button = ElevatedButton(
      onPressed: !nameValid ? null : () async {
        try {
          final storage = await getStorage();
          final dbObj = createDatabaseObject(
            currName, widget.id, widget.values, widget.dbKeyInfo);
          if (widget.dbKeyInfo == null) {
            await storage.insertKeyInfo(dbObj);
          } else {
            await storage.upsertPersonalInfo(dbObj);
          }
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } catch (e) {
          if (mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (c) => showError(localization.insertError, e.toString()),
              ),
            );
          }
        }
      },
      child: Text(
        widget.dbKeyInfo == null ? localization.addButton : localization.updateButton,
      ),
    );
    // add gap for floatingActionButton
    elements.add(const SizedBox(height: 75));

    final title = widget.dbKeyInfo == null ?
      localization.addNewContact : localization.updateContact;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        children: elements,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: button,
    );
  }
}
