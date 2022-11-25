import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../personal_information.dart';
import '../protocol/cryptograhic_id.pb.dart';
import '../storage.dart';
import '../crypto.dart';
import './error_screen.dart';
import './loading_screen.dart';

class UpdateOwnID extends StatefulWidget {
  const UpdateOwnID({
    Key? key,
    required this.ownID,
    required this.onSaved,
  }) : super(key: key);
  final Function(BuildContext context) onSaved;
  final DBKeyInfo ownID;

  @override
  State<UpdateOwnID> createState() => _UpdateOwnIDState();
}

class _UpdateOwnIDState extends State<UpdateOwnID> {
  bool _saving = false;
  String? _error;
  DBKeyInfo _ownID = createPlaceholderOwnID();
  final _formKey = GlobalKey<FormState>();
  final Map<CryptographicId_PersonalInformationType,
            TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _ownID = widget.ownID;
    for (final val in _ownID.personalInformation.values) {
      final edit = TextEditingController();
      edit.text = val.value;
      _textControllers[val.property] = edit;
    }
  }

  void saveID(BuildContext context) async {
    try {
      setState(() {
        _saving = true;
      });
      final storage = await getStorage();
      final Map<CryptographicId_PersonalInformationType,
                PersonalInformation> update = {};
      for (final e in _textControllers.entries) {
        update[e.key] = PersonalInformation(
            property: e.key,
            value: e.value.text,
            date: 0,
            signature: Uint8List(0),
            );
      }
      if (isPlaceholderOwnID(_ownID)) {
        final key = await createKey();
        await storage.secureBinaryWrite(
          SecureBinary.privateKey, key.item1);
        final insertKey = DBKeyInfo(
          name: ownPublicKeyInfoName,
          publicKey: key.item2,
          date: 0,
          signature: Uint8List(0),
          personalInformation: update,
        );
        await storage.insertKeyInfo(insertKey);
      } else {
        final insertKey = DBKeyInfo(
          name: ownPublicKeyInfoName,
          publicKey: _ownID.publicKey,
          date: 0,
          signature: Uint8List(0),
          personalInformation: update,
        );
        await storage.upsertPersonalInfo(insertKey);
      }
      if (mounted) {
        widget.onSaved(context);
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    if (_saving) {
      return loadingScreen(localization.saveOwnID);
    }
    if (_error != null) {
      return showError(localization.modifyOwnIDFailed, _error!);
    }

    final dropDownList = <DropdownMenuItem<
      CryptographicId_PersonalInformationType>>[];
    final formList = <Widget>[];
    // iterate over pits, so the order makes sense and is deterministic
    for (final pit in CryptographicId_PersonalInformationType.values) {
      final text = localizePersonalInformationType(localization, pit);
      final enableInput = _textControllers.containsKey(pit);
      if (enableInput) {
        formList.add(
          pitToTextFormField(
            pit: pit,
            controller: _textControllers[pit],
            localization: localization)
        );
      } else {
        dropDownList.add(
          DropdownMenuItem(
            value: pit,
            child: Text(text),
          )
        );
      }
    }
    final dropdown = DropdownButtonFormField<CryptographicId_PersonalInformationType>(
      decoration: InputDecoration(
        labelText: localization.addFormField,
        icon: const Icon(Icons.add),
      ),
      value: null,
      onChanged: (CryptographicId_PersonalInformationType? selected) {
        if (selected == null) {
          return;
        }
        final edit = TextEditingController();
        edit.text = "";
        setState(() {
          _textControllers[selected] = edit;
        });
      },
      items: dropDownList,
    );

    ListView body = ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: formList,
          ),
        ),
        // use own form for dropdown, so own GlobalKey can be used
        // otherwise it wont work to reset to value to null (show label)
        Form(
          key: GlobalKey<FormState>(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [dropdown],
          ),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.createID),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: localization.saveID,
            onPressed: () {
              saveID(context);
            },
          ),
        ],
      ),
      body: body,
    );
  }
}
