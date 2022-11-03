import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../protocol/cryptograhic_id.pb.dart';
import '../storage.dart';

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

PublicKey createDatabaseObject(String name,
                               CryptographicId id,
                               List<ValueAddUpdate> values,
                               PublicKey? dbKey) {
  final Map<String, PersonalInformation> updateInfo = {
    for (final v in values)
      if (v.checked)
        v.property: new PersonalInformation(
          property: v.property,
          value: v.value,
          date: v.timestamp,
          signature: Uint8List.fromList(v.signature),
        )
  };
  if (dbKey == null) {
    return PublicKey(
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
    required this.dbPublicKey,
    required this.values,
    required this.id}) : super(key: key);
  final PublicKey? dbPublicKey;
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
    final missingDetails = widget.values.map((ValueAddUpdate val) {
      String old = (val.oldValue != null ? " (was " + val.oldValue! + ")" : "");
      return new CheckboxListTile(
        title: new Text(val.property + ": " + val.value + old),
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
    final elements = <Widget>[];
    if (widget.dbPublicKey != null) {
      elements.add(new Text("ID: " + widget.dbPublicKey!.name));
      elements.add(const Text(""));
      nameValid = true;
    } else {
      elements.add(new Text("Enter name:"));
      elements.add(IntrinsicWidth(child: TextField(
        onChanged: (text) async {
          final storage = await getStorage();
          final exists = await storage.existsPublicKeyWithName(text);
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
          hintText: 'Enter name, allowed: a-z0-9',
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
        // error handling?
        final storage = await getStorage();
        final dbObj = createDatabaseObject(
          currName, widget.id, widget.values, widget.dbPublicKey);
        if (widget.dbPublicKey == null) {
          await storage.insertPublicKey(dbObj);
        } else {
          await storage.upsertPersonalInfo(dbObj);
        }
        Navigator.of(context).pop();
      },
      child: Text(
        "Add or update",
        style: TextStyle(color: Colors.indigo)),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Insert or update"),
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
