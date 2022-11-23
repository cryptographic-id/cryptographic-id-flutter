import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../personal_information.dart';
import '../protocol/cryptograhic_id.pb.dart';
import '../storage.dart';
import '../crypto.dart';
import './error_screen.dart';
import './loading_screen.dart';

class UpdateOwnID extends StatefulWidget {
  const UpdateOwnID({Key? key, required this.onSaved}) : super(key: key);
  final Function(BuildContext context) onSaved;

  @override
  State<UpdateOwnID> createState() => _UpdateOwnIDState();
}

class _UpdateOwnIDState extends State<UpdateOwnID> {
  bool _loaded = false;
  String? _error;
  DBKeyInfo _ownID = DBKeyInfo(
    name: ownPublicKeyInfoName,
    publicKey: Uint8List(0),
    date: 0,
    signature: Uint8List(0),
    personalInformation: {},
  );
  final _formKey = GlobalKey<FormState>();
  final Map<CryptographicId_PersonalInformationType,
            TextEditingController> _textControllers = {};

  void _loadData() async {
    try {
      final storage = await getStorage();
      final tmpOwnID = await storage.fetchOwnKeyInfo();
      setState(() {
        _loaded = true;
        if (tmpOwnID != null) {
          _ownID = tmpOwnID;
        }
        _error = null;
        for (final val in _ownID.personalInformation.values) {
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

  void saveID(BuildContext context) async {
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
      if (_ownID.publicKey.isEmpty) {
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
        _loaded = true;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    if (!_loaded) {
      return loadingScreen(localization.modifyOwnID);
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
