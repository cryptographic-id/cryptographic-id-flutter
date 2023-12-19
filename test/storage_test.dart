import "dart:io";
import "dart:typed_data";
import "package:cryptographic_id/storage.dart" as storage;
import "package:flutter_gen/protobuf/cryptographic_id.pb.dart";
import "package:flutter_test/flutter_test.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";
import "./crypto_test.dart";

void expectDBIdentity(storage.DBIdentity a, storage.DBIdentity b) {
  expect(a.toMap(), b.toMap());
  final keysA = a.personalInformation.keys.toList();
  final keysB = b.personalInformation.keys.toList();
  expect(keysA, keysB);
  for (final e in keysA) {
    expect(
      a.personalInformation[e]!.toMap(),
      b.personalInformation[e]!.toMap());
  }
}

void expectDBIdentities(List<storage.DBIdentity> a,
                        List<storage.DBIdentity> b) {
  expect(a.length, b.length);
  for (var i = 0; i < a.length; i++) {
    expectDBIdentity(a[i], b[i]);
  }
}

Future<void> initTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

Future<void> initTestDatabaseFuture = initTestDatabase();

Future<storage.Storage> useDatabase(String name) async {
  await initTestDatabaseFuture;
  await File("test/files/storage/" + name + ".db").copy(
    ".dart_tool/sqflite_common_ffi/databases/main.db");
  TestWidgetsFlutterBinding.ensureInitialized();
  return await storage.createForTestsOnly();
}

const ronFingerprint = "2B:7A:CF:2A:10:07:4D:F9\nDB:E8:01:2D:F6:A0:D6:A1\n"
                       "D6:ED:AF:72:4D:CC:06:E8\n37:37:DC:72:A9:C2:57:1A";
final upgradeIdentitiesV3 = [
  storage.DBIdentity(
    name: "andrea",
    publicKey: Uint8List.fromList([
      4, 254, 108, 226, 103, 251, 196, 213, 2, 237, 184, 190, 201, 76,
      85, 239, 241, 221, 192, 57, 229, 1, 74, 197, 214, 156, 214, 238,
      101, 177, 72, 63, 143, 87, 35, 95, 211, 53, 219, 167, 132, 193,
      128, 183, 7, 109, 184, 103, 62, 66, 142, 149, 148, 25, 210, 24,
      248, 146, 173, 134, 155, 145, 211, 20, 253]),
    date: 112,
    duplicate: false,
    fingerprint: "D8:C7:0C:8A:58:25:19:09\nCD:38:CD:52:FB:47:72:6E\n"
                 "A4:05:28:4F:6F:FF:39:E8\n59:FF:F1:C9:3F:75:93:5E",
    signature: Uint8List.fromList([1, 1, 2]),
    publicKeyType: CryptographicId_PublicKeyType.Prime256v1,
    personalInformation: {
      CryptographicId_PersonalInformationType.FIRST_NAME:
        storage.PersonalInformation(
          property: CryptographicId_PersonalInformationType.FIRST_NAME,
          value: "Andrea",
          date: 12,
          signature: Uint8List.fromList([1, 2]),
        ),
    },
  ),
  storage.DBIdentity(
    name: "ron",
    publicKey: prime256v1PublicKey(),
    date: 123,
    duplicate: false,
    fingerprint: ronFingerprint,
    signature: Uint8List.fromList([1, 2, 3]),
    publicKeyType: CryptographicId_PublicKeyType.Prime256v1,
    personalInformation: {
      CryptographicId_PersonalInformationType.NICK_NAME:
        storage.PersonalInformation(
          property: CryptographicId_PersonalInformationType.NICK_NAME,
          value: "Ronny",
          date: 1234,
          signature: Uint8List.fromList([1, 2, 3, 4, 5]),
        ),
    },
  ),
  storage.DBIdentity(
    name: "ron_encoded",
    publicKey: prime256v1PublicKeyEncoded(),
    date: 12345,
    duplicate: true,
    fingerprint: ronFingerprint,
    signature: Uint8List.fromList([1, 2, 3, 4, 5]),
    publicKeyType: CryptographicId_PublicKeyType.Prime256v1,
    personalInformation: {
      CryptographicId_PersonalInformationType.FIRST_NAME:
        storage.PersonalInformation(
          property: CryptographicId_PersonalInformationType.FIRST_NAME,
          value: "Ron",
          date: 123456,
          signature: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7]),
        ),
    },
  ),
];

void main() {
  test("upgrade_to_v3", () async {
    final store = await useDatabase("upgrade_to_v3");
    expectDBIdentities(await store.fetchKeyInfos(), upgradeIdentitiesV3);
    await store.close();
  });

  test("upgrade_v3_to_v4", () async {
    final store = await useDatabase("upgrade_v3_to_v4");
    expectDBIdentities(await store.fetchKeyInfos(), [
      storage.DBIdentity(
        name: "alice",
        publicKey: alicePublicKey(),
        date: 8357323,
        duplicate: false,
        fingerprint: aliceFingerprint(),
        publicKeyType: CryptographicId_PublicKeyType.Ed25519,
        signature: Uint8List.fromList([17, 12, 102, 61, 41]),
        personalInformation: {
          CryptographicId_PersonalInformationType.FIRST_NAME:
            storage.PersonalInformation(
              property: CryptographicId_PersonalInformationType.FIRST_NAME,
              value: "Alice",
              date: 84362,
              signature: Uint8List.fromList([72, 136, 16, 72, 182]),
            ),
          CryptographicId_PersonalInformationType.LAST_NAME:
            storage.PersonalInformation(
              property: CryptographicId_PersonalInformationType.LAST_NAME,
              value: "Jo",
              date: 8436211,
              signature: Uint8List.fromList([72, 136, 16, 72, 182, 13]),
            ),
        },
      ),
      upgradeIdentitiesV3[0],
      storage.DBIdentity(
        name: "bob",
        publicKey: bobPublicKey(),
        date: 8357323,
        duplicate: false,
        fingerprint: bobFingerprint(),
        publicKeyType: CryptographicId_PublicKeyType.Ed25519,
        signature: Uint8List.fromList([17, 102, 61, 41, 18]),
        personalInformation: {
          CryptographicId_PersonalInformationType.FIRST_NAME:
            storage.PersonalInformation(
              property: CryptographicId_PersonalInformationType.FIRST_NAME,
              value: "Bob",
              date: 8436213,
              signature: Uint8List.fromList([72, 136, 16, 72, 182]),
            ),
          CryptographicId_PersonalInformationType.NICK_NAME:
            storage.PersonalInformation(
              property: CryptographicId_PersonalInformationType.NICK_NAME,
              value: "Bobby",
              date: 81431621,
              signature: Uint8List.fromList([13, 16, 211, 12, 13]),
            ),
        },
      ),
      upgradeIdentitiesV3[1],
      upgradeIdentitiesV3[2],
    ]);
    await store.close();
  });
}
