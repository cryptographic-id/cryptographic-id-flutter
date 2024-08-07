import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/protobuf/cryptographic_id.pb.dart';
import '../personal_information.dart';
import '../storage.dart';
import '../crypto.dart';
import './error_screen.dart';
import './loading_screen.dart';

class ModifyOwnID extends StatefulWidget {
  const ModifyOwnID({
    Key? key,
    required this.ownID,
    required this.onSaved,
  }) : super(key: key);
  final Function(BuildContext context) onSaved;
  final DBIdentity ownID;

  @override
  State<ModifyOwnID> createState() => _ModifyOwnIDState();
}

class _ModifyOwnIDState extends State<ModifyOwnID> {
  bool _saving = false;
  String? _error;
  DBIdentity _ownID = createPlaceholderOwnID();
  final _formKey = GlobalKey<FormState>();
  CryptographicId_PersonalInformationType? _lastAdded;
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
      const publicKeyType = CryptographicId_PublicKeyType.Ed25519;
      if (isPlaceholderOwnID(_ownID)) {
        final key = await createKey();
        await storage.secureBinaryWrite(
          SecureBinary.privateKey, key.item1);
        final insertKey = DBIdentity(
          name: ownIdentityDBName,
          publicKey: key.item2,
          fingerprint: fingerprintFromPublicKey(
            key.item2, publicKeyType, false),
          duplicate: false,
          date: 0,
          signature: Uint8List(0),
          publicKeyType: publicKeyType,
          personalInformation: update,
        );
        await storage.insertKeyInfo(insertKey);
      } else {
        final insertKey = DBIdentity(
          name: ownIdentityDBName,
          publicKey: _ownID.publicKey,
          fingerprint: fingerprintFromPublicKey(
            _ownID.publicKey, publicKeyType, false),
          date: 0,
          duplicate: false,
          signature: Uint8List(0),
          publicKeyType: publicKeyType,
          personalInformation: update,
        );
        await storage.upsertPersonalInfo(insertKey);
      }
      if (context.mounted) {
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
        FocusNode focusNode = FocusNode();
        formList.add(
          pitToTextFormField(
            pit: pit,
            controller: _textControllers[pit],
            focusNode: focusNode,
            localization: localization)
        );
        if (_lastAdded == pit) {
          focusNode.requestFocus();
        }
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
          _lastAdded = selected;
        });
      },
      items: dropDownList,
    );
    if (!isPlaceholderOwnID(_ownID)) {
      formList.add(fingerprintFormField(localization, _ownID.publicKeyType,
                                        _ownID.publicKey, false));
      formList.add(fingerprintFormField(localization, _ownID.publicKeyType,
                                        _ownID.publicKey, true));
    }

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
        // otherwise it won't work to reset the value to null (show label)
        Form(
          key: GlobalKey<FormState>(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [dropdown],
          ),
        ),
      ],
    );
    final title = isPlaceholderOwnID(_ownID) ?
      localization.createID : localization.modifyID;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save),
            iconSize: 30,
            padding: const EdgeInsets.fromLTRB(40, 5, 10, 5),
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
