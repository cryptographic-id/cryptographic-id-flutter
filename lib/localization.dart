import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import './protocol/cryptograhic_id.pb.dart';

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
