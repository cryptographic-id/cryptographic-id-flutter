import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/protobuf/cryptographic_id.pb.dart';
import './crypto.dart' as crypto;

String localizePersonalInformationType(
    AppLocalizations localization,
    CryptographicId_PersonalInformationType t) {
  switch (t) {
    case CryptographicId_PersonalInformationType.FIRST_NAME:
      return localization.pitFirstName;
    case CryptographicId_PersonalInformationType.LAST_NAME:
      return localization.pitLastName;
    case CryptographicId_PersonalInformationType.NICK_NAME:
      return localization.pitNickName;
    case CryptographicId_PersonalInformationType.E_MAIL:
      return localization.pitEMail;
    case CryptographicId_PersonalInformationType.WEBSITE:
      return localization.pitWebsite;
    case CryptographicId_PersonalInformationType.PHONE_NUMBER:
      return localization.pitPhoneNumber;
    case CryptographicId_PersonalInformationType.COUNTRY:
      return localization.pitCountry;
    case CryptographicId_PersonalInformationType.STATE:
      return localization.pitState;
    case CryptographicId_PersonalInformationType.CITY:
      return localization.pitCity;
    case CryptographicId_PersonalInformationType.POST_CODE:
      return localization.pitPostCode;
    case CryptographicId_PersonalInformationType.STREET:
      return localization.pitStreet;
    case CryptographicId_PersonalInformationType.HOUSE_NUMBER:
      return localization.pitHouseNumber;
    case CryptographicId_PersonalInformationType.MATRIX_ID:
      return localization.pitMatrixID;
    default:
      return t.toString();
  }
}

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

TextFormField pitToTextFormField({
  required CryptographicId_PersonalInformationType pit,
  required TextEditingController? controller,
  required AppLocalizations localization,
  bool enabled = true,
  FocusNode? focusNode = null,
}) {
  return TextFormField(
    controller: controller,
    readOnly: !enabled,
    focusNode: focusNode,
    decoration: InputDecoration(
      labelText: localizePersonalInformationType(localization, pit),
      icon: Icon(pitToIcon(pit)),
    ),
    inputFormatters: [
      LengthLimitingTextInputFormatter(45),
    ],
    keyboardType: pitToKeyboardType(pit),
  );
}

TextFormField pitToDisabledTextFormField({
  required CryptographicId_PersonalInformationType pit,
  required String value,
  required AppLocalizations localization,
}) {
  final elem = TextEditingController();
  elem.text = value;
  return pitToTextFormField(
    pit: pit,
    controller: elem,
    localization: localization,
    enabled: false);
}

TextFormField publicKeyFormField(AppLocalizations localization,
                                 CryptographicId_PublicKeyType type,
                                 Uint8List key) {
  final pubKeyController = TextEditingController();
  pubKeyController.text = crypto.formatPublicKey(key, type);
  return TextFormField(
    controller: pubKeyController,
    readOnly: true,
    minLines: 4,
    maxLines: 4,
    decoration: InputDecoration(
      labelText: localization.publicKey(type.toString()),
      icon: const Icon(Icons.fingerprint),
    ),
  );
}
