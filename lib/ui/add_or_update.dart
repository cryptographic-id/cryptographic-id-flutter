import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../protocol/cryptograhic_id.pb.dart';
import '../storage.dart';
import './error_screen.dart';

class ValueAddUpdate {
  bool update = false;
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

DBKeyInfo createDatabaseObject(String name,
                               CryptographicId id,
                               List<ValueAddUpdate> values,
                               DBKeyInfo? dbKey) {
  final Map<String, PersonalInformation> updateInfo = {
    for (final v in values)
      if (v.update)
        v.property: new PersonalInformation(
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
  final useKey = dbKey!;
  for (final e in updateInfo.entries) {
    useKey.personalInformation[e.value.property] = e.value;
  }
  return useKey;
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
      // TODO: translate val.property
      String title = val.oldValue == null ?
        localization.addDetail(val.property, val.value) :
        localization.updateDetail(val.property, val.value, val.oldValue!);
      return new CheckboxListTile(
        title: new Text(title),
        value: val.update,
        onChanged: (bool? value) {
          if (value == null) {
            return;
          }
          setState(() {
            val.update = value!;
          });
        },
      );
    }).toList();
    final elements = <Widget>[];
    if (widget.dbKeyInfo != null) {
      elements.add(new Text(localization.showName(widget.dbKeyInfo!.name)));
      elements.add(const Text(""));
      nameValid = true;
    } else {
      elements.add(new Text(localization.enterName));
      elements.add(IntrinsicWidth(child: TextField(
        onChanged: (text) async {
          final storage = await getStorage();
          final exists = await storage.existsKeyInfoWithName(text);
          setState(() {
            nameValid = text != "" && !exists;
            currName = text;
          });
        },
        keyboardType: TextInputType.name,
        maxLines: 1,
        autocorrect: false,
        enableSuggestions: false,
        inputFormatters: [
          new FilteringTextInputFormatter.allow(RegExp("[a-z0-9]")),
        ],
        selectionWidthStyle: BoxWidthStyle.tight,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          isDense: true,
          hintText: localization.allowedNameChars,
        ),
      )));
    }
    missingDetails.forEach(elements.add);
    elements.add(TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.indigo),
        ),
        backgroundColor: !nameValid ? Colors.grey : null,
      ),
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
          Navigator.of(context).pop();
        } catch (e) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (c) => showError(localization.insertError, e.toString()),
            ),
          );
        }
      },
      child: Text(
        widget.dbKeyInfo == null ? localization.addButton : localization.updateButton,
        style: TextStyle(color: Colors.indigo)),
    ));

    final title = widget.dbKeyInfo == null ?
      localization.addNewContact : localization.updateContact;
    return Scaffold(
      appBar: AppBar(
        title: new Text(title),
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
