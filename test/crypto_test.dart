import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptographic_id/crypto.dart' as crypto;
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter_gen/protobuf/cryptographic_id.pb.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List alicePrivateKey() {
  return Uint8List.fromList([
    61, 72, 246, 247, 240, 227, 30, 10, 202, 31, 53, 83, 248, 113, 194, 240,
    9, 175, 251, 252, 126, 234, 184, 239, 101, 102, 104, 154, 108, 20, 144,
    23]);
}

Uint8List alicePublicKey() {
  return Uint8List.fromList([
    245, 139, 151, 242, 108, 95, 189, 236, 97, 8, 109, 99, 140, 3, 135, 66,
    107, 154, 210, 58, 250, 161, 224, 131, 107, 108, 215, 195, 102, 129, 149,
    103]);
}

String aliceFingerprint() {
  return 'B9:67:D2:78:DF:6F:80:46\nA3:A2:E9:D4:FB:F2:E2:7B\n'
         'DA:1E:74:E8:A7:79:37:33\n03:23:B5:AB:AE:3E:8D:68';
}

Uint8List bobPrivateKey() {
  return Uint8List.fromList([
    37, 103, 10, 136, 189, 252, 155, 20, 28, 102, 195, 1, 86, 98, 15, 143, 201,
    109, 107, 252, 74, 175, 200, 125, 133, 209, 62, 81, 32, 144, 6, 161]);
}

Uint8List bobPublicKey() {
  return Uint8List.fromList([
    200, 171, 177, 238, 239, 223, 192, 4, 109, 195, 209, 192, 4, 198, 207, 80,
    151, 40, 154, 100, 234, 145, 221, 219, 198, 110, 135, 32, 121, 81, 109,
    32]);
}

String bobFingerprint() {
  return "F1:E5:58:C8:1D:18:FE:6E\nEB:04:79:BB:99:05:B7:0D\n"
         "9D:4B:6F:82:0A:D3:33:03\n01:AA:DE:C6:E1:CA:EC:41";
}

Uint8List prime256v1PublicKey() {
  return Uint8List.fromList([
    4, 244, 227, 214, 219, 37, 6, 167, 33, 17, 114, 63, 100, 194, 174, 39, 218,
    76, 14, 149, 150, 178, 144, 80, 39, 151, 160, 97, 219, 190, 53, 178, 153,
    129, 184, 57, 116, 40, 38, 14, 241, 73, 226, 198, 88, 101, 152, 123, 9,
    252, 251, 147, 92, 162, 39, 70, 183, 145, 219, 47, 225, 121, 195, 84,
    202]);
}

Uint8List prime256v1PublicKeyEncoded() {
  return Uint8List.fromList([
    2, 244, 227, 214, 219, 37, 6, 167, 33, 17, 114, 63, 100, 194, 174, 39, 218,
    76, 14, 149, 150, 178, 144, 80, 39, 151, 160, 97, 219, 190, 53, 178, 153]);
}

CryptographicId ed25519signedMsg() {
  return CryptographicId.fromBuffer(base64.decode(
    "CiBnc/OgVDUsU9c6yA0Nl49PoOljQIQfphLBKKeZEAdmeBDjnNidBhoKTXkgbWVzc2FnZUpA2"
    "3R1QBZ6+X9eUaEs/nIBtMNeE7oZNUzwtfeYL1mBRPwChSvMxSZaNntFeNwtjLU6odjG7KPIYX"
    "W3euqodukJAlJRCAISBVBpZXR6GOOc2J0GekCvVZBlxain+l62+CB8savD5urT7Z7+k+RPrgW"
    "hgEc+gI9BsvXjcMB056Q0sStDTAzO9oOOkYmEGlPwvtKWP3MCUlIIBxIGKzEyMzQ1GOOc2J0G"
    "ekAUsIy4/f7j79wgnMz5w2eTQTSurEjlSuV0LyWTlBBlkKCUWoxQjENp79DU7puFKr1BcArUi"
    "Ss5+7sQVCMj0CwF"));
}

CryptographicId prime256v1SignedMsg() {
  return CryptographicId.fromBuffer(base64.decode(
    "CkEE9OPW2yUGpyERcj9kwq4n2kwOlZaykFAnl6Bh2741spmBuDl0KCYO8UnixlhlmHsJ/PuTX"
    "KInRreR2y/hecNUyhD+9dudBhoZcHJpbWUyNTZ2MSBzaWduZWQgbWVzc2FnZUABSkcwRQIhAL"
    "sElQfgu7JGenIb+LRTY1r4AC7yK0VZ9KVSZ8dZYEtqAiAbOQ+126hXy4gEatZgiz2qeqCHlxp"
    "SmAbLoc1UBaDDPA=="));
}

void main() {
  test('createKey', () async {
    final key = await crypto.createKey();
    final msg = Uint8List.fromList([57, 21, 98, 23, 64, 73]);
    final sig = await crypto.sign(msg, key.item1);
    expect(await crypto.verifyEd25519(msg, sig, key.item2), true);
    final msg2 = Uint8List.fromList([57, 20, 98, 23, 64, 73]);
    expect(await crypto.verifyEd25519(msg2, sig, key.item2), false);
  });

  test('verifyEd25519', () async {
    final msg = Uint8List.fromList([57, 21, 103, 98, 23, 64, 73, 80, 20]);
    final sig = Uint8List.fromList([
      153, 125, 160, 139, 45, 95, 17, 128, 202, 65, 22, 201, 39, 94, 72, 78,
      19, 228, 45, 10, 174, 76, 66, 160, 184, 67, 140, 183, 71, 215, 191, 60,
      117, 70, 192, 214, 180, 170, 228, 111, 229, 92, 74, 245, 109, 177, 253,
      22, 66, 1, 96, 245, 26, 13, 17, 186, 226, 35, 154, 1, 233, 28, 32, 3]);
    expect(await crypto.verifyEd25519(msg, sig, alicePublicKey()), true);
    expect(await crypto.verifyEd25519(msg, sig, bobPublicKey()), false);
    sig[4] = 15; // corrupt
    expect(await crypto.verifyEd25519(msg, sig, alicePublicKey()), false);
    sig[4] = 45; // reset
    msg[8] = 10; // corrupt
    expect(await crypto.verifyEd25519(msg, sig, alicePublicKey()), false);
  });

  test('sign', () async {
    final msg = Uint8List.fromList([10, 174, 76, 66, 160, 184, 67, 140, 183]);
    final sig = await crypto.sign(msg, alicePrivateKey());
    expect(sig, Uint8List.fromList([
      130, 158, 38, 11, 161, 199, 174, 167, 40, 39, 155, 183, 191, 179, 159,
      154, 209, 74, 55, 234, 176, 204, 24, 121, 73, 38, 38, 78, 143, 138, 126,
      128, 34, 111, 185, 236, 141, 7, 54, 111, 142, 182, 96, 84, 106, 208, 166,
      159, 32, 41, 124, 70, 79, 83, 6, 114, 33, 139, 37, 230, 238, 224, 116,
      6]));
  });

  test('verifyPrime256v1Sha256', () async {
    final sig = Uint8List.fromList([
      48, 69, 2, 33, 0, 187, 4, 149, 7, 224, 187, 178, 70, 122, 114, 27, 248,
      180, 83, 99, 90, 248, 0, 46, 242, 43, 69, 89, 244, 165, 82, 103, 199, 89,
      96, 75, 106, 2, 32, 27, 57, 15, 181, 219, 168, 87, 203, 136, 4, 106, 214,
      96, 139, 61, 170, 122, 160, 135, 151, 26, 82, 152, 6, 203, 161, 205, 84,
      5, 160, 195, 60]);
    final msg = Uint8List.fromList([
      0, 0, 0, 0, 99, 182, 250, 254, 4, 244, 227, 214, 219, 37, 6, 167, 33, 17,
      114, 63, 100, 194, 174, 39, 218, 76, 14, 149, 150, 178, 144, 80, 39, 151,
      160, 97, 219, 190, 53, 178, 153, 129, 184, 57, 116, 40, 38, 14, 241, 73,
      226, 198, 88, 101, 152, 123, 9, 252, 251, 147, 92, 162, 39, 70, 183, 145,
      219, 47, 225, 121, 195, 84, 202, 112, 114, 105, 109, 101, 50, 53, 54,
      118, 49, 32, 115, 105, 103, 110, 101, 100, 32, 109, 101, 115, 115, 97,
      103, 101]);
    expect(await crypto.verifyPrime256v1Sha256(msg, sig, prime256v1PublicKey()),
           true);
    sig[18] = 4; // corrupt
    expect(await crypto.verifyPrime256v1Sha256(msg, sig, prime256v1PublicKey()),
           false);
    sig[18] = 83; // reset
    msg[7] = 4; // corrupt
    expect(await crypto.verifyPrime256v1Sha256(msg, sig, prime256v1PublicKey()),
           false);
    msg[7] = 254; // reset
    final pubkey = prime256v1PublicKey();
    pubkey[19] = 3; // corrupt
    expect(await crypto.verifyPrime256v1Sha256(msg, sig, pubkey),
           false);
  });

  test('idToDataToSign', () {
    final id = CryptographicId();
    id.timestamp = fixnum.Int64(201361621400000009);
    id.msg = [67, 20, 32, 92, 24];
    id.publicKey = [20, 20, 26, 29, 24];
    expect(crypto.idToDataToSign(id),
           [2, 203, 97, 83, 234, 241, 150, 9, 20, 20, 26, 29, 24, 67, 20, 32,
            92, 24]);
  });

  test('personalInformationToDataToSign', () {
    final entry = CryptographicId_PersonalInformation();
    entry.value = [12, 12, 78, 25, 71];
    entry.timestamp = fixnum.Int64(201461421402000109);
    entry.type = CryptographicId_PersonalInformationType.WEBSITE;
    expect(crypto.personalInformationToDataToSign(entry),
           [2, 203, 188, 24, 106, 156, 138, 237, 0, 0, 0, 6, 12, 12, 78, 25,
            71]);
  });

  test('verifyCryptographicId ed25519', () async {
    var msg = ed25519signedMsg();
    expect(await crypto.verifyCryptographicId(msg), true);
    msg.signature[40] = 20;
    expect(await crypto.verifyCryptographicId(msg), false);
    msg = ed25519signedMsg();
    msg.msg[4] = 2;
    expect(await crypto.verifyCryptographicId(msg), false);
    msg = ed25519signedMsg();
    msg.timestamp = fixnum.Int64(200);
    expect(await crypto.verifyCryptographicId(msg), false);
    msg = ed25519signedMsg();
    msg.publicKey[20] = 20;
    expect(await crypto.verifyCryptographicId(msg), false);

    msg = ed25519signedMsg();
    msg.personalInformation[0].type =
      CryptographicId_PersonalInformationType.WEBSITE;
    expect(await crypto.verifyCryptographicId(msg), false);
    msg = ed25519signedMsg();
    msg.personalInformation[0].value[2] = 70;
    expect(await crypto.verifyCryptographicId(msg), false);
    msg = ed25519signedMsg();
    msg.personalInformation[0].timestamp = fixnum.Int64(2000000);
    expect(await crypto.verifyCryptographicId(msg), false);
    msg = ed25519signedMsg();
    msg.personalInformation[0].signature[2] = 70;
    expect(await crypto.verifyCryptographicId(msg), false);
  });

  test('verifyCryptographicId prime256v1', () async {
    var msg = prime256v1SignedMsg();
    expect(await crypto.verifyCryptographicId(msg), true);
    msg.signature[40] = 20;
    expect(await crypto.verifyCryptographicId(msg), false);
    msg = prime256v1SignedMsg();
    msg.msg[4] = 2;
    expect(await crypto.verifyCryptographicId(msg), false);
    msg = prime256v1SignedMsg();
    msg.timestamp = fixnum.Int64(200);
    expect(await crypto.verifyCryptographicId(msg), false);
    msg = prime256v1SignedMsg();
    msg.publicKey[20] = 20;
    expect(await crypto.verifyCryptographicId(msg), false);
  });

  test('signCryptographicId', () async {
    final id = CryptographicId();
    id.timestamp = fixnum.Int64(321367621461);
    id.msg = [20, 32, 92, 24, 150, 9];
    id.publicKey = alicePublicKey();
    await crypto.signCryptographicId(id, alicePrivateKey());
    expect(await crypto.verifyCryptographicId(id), true);

    id.msg[2] = 0;
    final entry = CryptographicId_PersonalInformation();
    entry.value = [78, 29, 71, 28, 20];
    entry.timestamp = fixnum.Int64(201461421402000109);
    entry.type = CryptographicId_PersonalInformationType.STREET;
    id.personalInformation.add(entry);
    await crypto.signCryptographicId(id, alicePrivateKey());
    expect(await crypto.verifyCryptographicId(id), true);
    await crypto.signCryptographicId(id, bobPrivateKey());
    expect(await crypto.verifyCryptographicId(id), false);
  });

  test('now', () {
    final before = DateTime.now().millisecondsSinceEpoch;
    final now = crypto.now();
    final after = DateTime.now().millisecondsSinceEpoch;
    expect(before - 1000 <= now && now <= after + 1000, true);
  });

  test('oldestTimestamp', () {
    final id = CryptographicId();
    id.timestamp = fixnum.Int64(511);
    final entry1 = CryptographicId_PersonalInformation();
    entry1.timestamp = fixnum.Int64(505);
    final entry2 = CryptographicId_PersonalInformation();
    entry2.timestamp = fixnum.Int64(515);
    id.personalInformation.add(entry1);
    id.personalInformation.add(entry2);
    expect(crypto.oldestTimestamp(id), fixnum.Int64(505000));
    id.timestamp = fixnum.Int64(500);
    expect(crypto.oldestTimestamp(id), fixnum.Int64(500000));
    entry2.timestamp = fixnum.Int64(499);
    expect(crypto.oldestTimestamp(id), fixnum.Int64(499000));

    // test in milliseconds
    final msID = CryptographicId();
    msID.timestamp = fixnum.Int64(1702396824351);
    msID.personalInformation.add(entry1);
    expect(crypto.oldestTimestamp(msID), fixnum.Int64(505000));
    entry1.timestamp = fixnum.Int64(1802396824351);
    expect(crypto.oldestTimestamp(msID), fixnum.Int64(1702396824351));
  });

  test('isSignatureRecent', () {
    // test in seconds and milliseconds
    for (int i = 0; i < 2; i++) {
      final ts = (i == 0) ? crypto.now() : crypto.now() / 1000;
      final now = fixnum.Int64(ts.round());
      final id = CryptographicId();
      id.timestamp = now + 2;
      final entry1 = CryptographicId_PersonalInformation();
      entry1.timestamp = now - 1;
      final entry2 = CryptographicId_PersonalInformation();
      entry2.timestamp = now - 10;
      id.personalInformation.add(entry1);
      id.personalInformation.add(entry2);
      expect(crypto.isSignatureRecent(id), false);
      id.timestamp = now - 1;
      expect(crypto.isSignatureRecent(id), true);
      entry2.timestamp = now + 10;
      expect(crypto.isSignatureRecent(id), false);
    }
  });

  test('encodeBigIntUncompressed', () {
    expect(crypto.encodeBigIntUncompressed(BigInt.from(197)),
           [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 197]);
    expect(crypto.encodeBigIntUncompressed(BigInt.parse(
     "11299591275638674629668252309660987941464800843746387481241503097"
     "0410840113039")),
     [249, 209, 107, 145, 252, 59, 243, 121, 61, 75, 24, 227, 108, 210, 5, 27,
      197, 206, 66, 20, 88, 10, 237, 214, 156, 214, 238, 101, 177, 72, 63,
      143]);
    expect(() => crypto.encodeBigIntUncompressed(BigInt.parse(
     "9999999591275638674629668252309660987941464800843746387481241503097"
     "0410840113039")), throwsA(isA<Exception>()));
  });

  test('fingerprintFromPublicKey', () {
    expect(crypto.fingerprintFromPublicKey(alicePublicKey(),
                                  CryptographicId_PublicKeyType.Ed25519,
                                  false),
           aliceFingerprint());
    expect(crypto.fingerprintFromPublicKey(alicePublicKey(),
                                  CryptographicId_PublicKeyType.Ed25519,
                                  true),
           'F5:8B:97:F2:6C:5F:BD:EC\n61:08:6D:63:8C:03:87:42\n'
           '6B:9A:D2:3A:FA:A1:E0:83\n6B:6C:D7:C3:66:81:95:67');
    expect(crypto.fingerprintFromPublicKey(prime256v1PublicKey(),
                                  CryptographicId_PublicKeyType.Ed25519,
                                  false),
           'Invalid ED25519 public key');

    expect(crypto.fingerprintFromPublicKey(prime256v1PublicKey(),
                                  CryptographicId_PublicKeyType.Prime256v1,
                                  true),
           'C3:25:12:8D:DF:E7:79:B4\n59:2E:64:C7:04:DC:FF:17\n'
           'BB:EE:B8:33:69:2F:F0:6E\n12:9B:DC:82:4E:16:6C:ED');
    expect(crypto.fingerprintFromPublicKey(
             prime256v1PublicKeyEncoded(),
             CryptographicId_PublicKeyType.Prime256v1,
             true),
           'A6:ED:7C:17:DE:6E:2A:70\n85:35:7E:E4:52:A2:09:FA\n'
           'D6:E6:C2:08:F6:41:2D:F5\nE2:4D:DB:59:AB:12:DF:94');

    const prime256fingerprint =
      '2B:7A:CF:2A:10:07:4D:F9\nDB:E8:01:2D:F6:A0:D6:A1\n'
      'D6:ED:AF:72:4D:CC:06:E8\n37:37:DC:72:A9:C2:57:1A';
    expect(crypto.fingerprintFromPublicKey(prime256v1PublicKey(),
                                  CryptographicId_PublicKeyType.Prime256v1,
                                  false),
           prime256fingerprint);
    expect(crypto.fingerprintFromPublicKey(prime256v1PublicKeyEncoded(),
                                  CryptographicId_PublicKeyType.Prime256v1,
                                  false),
           prime256fingerprint);

    var key = Uint8List.fromList([
      4, 88, 108, 226, 103, 251, 196, 213, 2, 237, 184, 190, 201, 76, 85, 239,
      241, 221, 192, 57, 229, 1, 74, 197, 214, 156, 214, 238, 101, 177, 72,
      63, 143, 87, 35, 95, 211, 53, 219, 167, 132, 193, 128, 183, 7, 109, 184,
      103, 62, 66, 142, 149, 148, 25, 210, 24, 248, 146, 173, 134, 155, 145,
      211, 20, 133
    ]);
    expect(crypto.fingerprintFromPublicKey(key,
                                  CryptographicId_PublicKeyType.Prime256v1,
                                  false),
           '46:A9:B7:B9:AC:D1:90:62\nB7:43:73:1A:81:35:F2:E3\n'
           '7C:19:45:B2:CC:BF:6D:ED\n79:54:B7:D9:38:12:B3:3E');
    var keyBig = Uint8List.fromList([
      4, 254, 108, 226, 103, 251, 196, 213, 2, 237, 184, 190, 201, 76, 85, 239,
      241, 221, 192, 57, 229, 1, 74, 197, 214, 156, 214, 238, 101, 177, 72, 63,
      143, 87, 35, 95, 211, 53, 219, 167, 132, 193, 128, 183, 7, 109, 184, 103,
      62, 66, 142, 149, 148, 25, 210, 24, 248, 146, 173, 134, 155, 145, 211,
      20, 253
    ]);
    expect(crypto.fingerprintFromPublicKey(keyBig,
                                  CryptographicId_PublicKeyType.Prime256v1,
                                  false),
           'D8:C7:0C:8A:58:25:19:09\nCD:38:CD:52:FB:47:72:6E\n'
           'A4:05:28:4F:6F:FF:39:E8\n59:FF:F1:C9:3F:75:93:5E');
    expect(crypto.fingerprintFromPublicKey(Uint8List.fromList([0]),
                                  CryptographicId_PublicKeyType.Prime256v1),
           "Invalid public key");
  });
}
