import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../localization.dart';
import '../protocol/cryptograhic_id.pb.dart';
import '../storage.dart';
import '../crypto.dart';
import './error_screen.dart';
import './loading_screen.dart';

TextInputType pitToKeyboardType(CryptographicId_PersonalInformationType t) {
  switch (t) {
    case CryptographicId_PersonalInformationType.FIRST_NAME:
      return TextInputType.text;
    case CryptographicId_PersonalInformationType.LAST_NAME:
      return TextInputType.text;
    case CryptographicId_PersonalInformationType.NICK_NAME:
      return TextInputType.text;
    case CryptographicId_PersonalInformationType.E_MAIL:
      return TextInputType.emailAddress;
    case CryptographicId_PersonalInformationType.PHONE_NUMBER:
      return TextInputType.phone;
    case CryptographicId_PersonalInformationType.WEBSITE:
      return TextInputType.url;
    case CryptographicId_PersonalInformationType.STATE:
      return TextInputType.text;
    case CryptographicId_PersonalInformationType.COUNTRY:
      return TextInputType.text;
    case CryptographicId_PersonalInformationType.CITY:
      return TextInputType.text;
    case CryptographicId_PersonalInformationType.POST_CODE:
      return TextInputType.number;
    case CryptographicId_PersonalInformationType.STREET:
      return TextInputType.streetAddress;
    case CryptographicId_PersonalInformationType.HOUSE_NUMBER:
      return TextInputType.number;
    case CryptographicId_PersonalInformationType.MATRIX_ID:
      return TextInputType.text;
  }
  return TextInputType.text;
}

IconData pitToIcon(CryptographicId_PersonalInformationType t) {
  switch (t) {
    case CryptographicId_PersonalInformationType.FIRST_NAME:
      return Icons.person;
    case CryptographicId_PersonalInformationType.LAST_NAME:
      return Icons.person;
    case CryptographicId_PersonalInformationType.NICK_NAME:
      return Icons.person;
    case CryptographicId_PersonalInformationType.E_MAIL:
      return Icons.email;
    case CryptographicId_PersonalInformationType.WEBSITE:
      return Icons.web;
    case CryptographicId_PersonalInformationType.PHONE_NUMBER:
      return Icons.phone;
    case CryptographicId_PersonalInformationType.COUNTRY:
      return Icons.public;
    case CryptographicId_PersonalInformationType.STATE:
      return Icons.flag;
    case CryptographicId_PersonalInformationType.CITY:
      return Icons.location_city;
    case CryptographicId_PersonalInformationType.POST_CODE:
      return Icons.local_post_office;
    case CryptographicId_PersonalInformationType.STREET:
      return Icons.house;
    case CryptographicId_PersonalInformationType.HOUSE_NUMBER:
      return Icons.house;
    case CryptographicId_PersonalInformationType.MATRIX_ID:
      return Icons.message;
  }
  return Icons.person;
}

class UpdateOwnKey extends StatefulWidget {
  const UpdateOwnKey({Key? key, required this.onSaved}) : super(key: key);
  final Function(BuildContext context) onSaved;

  @override
  State<UpdateOwnKey> createState() => _UpdateOwnKeyState();
}

class _UpdateOwnKeyState extends State<UpdateOwnKey> {
  bool _loaded = false;
  String? _error;
  DBKeyInfo _ownKey = DBKeyInfo(
    name: ownPublicKeyInfoName,
    publicKey: Uint8List(0),
    date: 0,
    signature: Uint8List(0),
    personalInformation: {},
  );
  final _formKey = GlobalKey<FormState>();
  final Map<CryptographicId_PersonalInformationType,
            TextEditingController> _textControllers = {};
  CryptographicId_PersonalInformationType? _lastDropDownElem;

  void _loadData() async {
    try {
      final storage = await getStorage();
      final tmpOwnKey = await storage.fetchOwnKeyInfo();
      setState(() {
        _loaded = true;
        if (tmpOwnKey != null) {
          _ownKey = tmpOwnKey;
        }
        _error = null;
        for (final val in _ownKey.personalInformation.values) {
          final edit = TextEditingController();
          edit.text = val.value;
          _textControllers[val.property] = edit;
        }
      });
    } catch (e) {
      setState(() {
        _loaded = true;
        _error = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void saveKey(BuildContext context) async {
    try {
      setState(() {
        _loaded = false;
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
      if (_ownKey.publicKey.isEmpty) {
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
          publicKey: _ownKey.publicKey,
          date: 0,
          signature: Uint8List(0),
          personalInformation: update,
        );
        await storage.upsertPersonalInfo(insertKey);
      }
      widget.onSaved(context);
    } catch (e) {
      setState(() {
        _loaded = true;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    if (!_loaded) {
      return loadingScreen(localization.modifyOwnKey);
    }
    if (_error != null) {
      return showError(localization.modifyOwnKeyFailed, _error!);
    }

    final dropDownList = <DropdownMenuItem<
      CryptographicId_PersonalInformationType>>[];
    if (_lastDropDownElem != null) {
      // DropdownButtonFormField does not allow to remove the selected item
      // and value cannot be reset to null
      // This workaround results in a gap at the top of the menu
      dropDownList.add(
        DropdownMenuItem(
          enabled: false,
          value: _lastDropDownElem,
          child: const SizedBox(height: 0),
        )
      );
    }
    final formList = <Widget>[];
    // iterate over pits, so the order makes sense and is deterministic
    for (final pit in CryptographicId_PersonalInformationType.values) {
      final text = localizePersonalInformationType(localization, pit);
      final enableInput = _textControllers.containsKey(pit);
      if (enableInput) {
        final elem = _textControllers[pit];
        formList.add(
          TextFormField(
            controller: elem,
            inputFormatters: [
              LengthLimitingTextInputFormatter(45),
            ],
            keyboardType: pitToKeyboardType(pit),
            decoration: InputDecoration(
              labelText: text,
              icon: Icon(pitToIcon(pit)),
            ),
          )
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
    final dropdown = DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: localization.addFormField,
        icon: const Icon(Icons.person),
      ),
      onChanged: (CryptographicId_PersonalInformationType? selected) {
        if (selected == null) {
          return;
        }
        final edit = TextEditingController();
        edit.text = "";
        setState(() {
          _lastDropDownElem = selected;
          _textControllers[selected] = edit;
        });
      },
      items: dropDownList,
    );
    formList.add(dropdown);

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
        )
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
              saveKey(context);
            },
          ),
        ],
      ),
      body: body,
    );
  }
}
