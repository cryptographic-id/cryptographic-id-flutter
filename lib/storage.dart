import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_gen/protobuf/cryptographic_id.pb.dart';
import '../crypto.dart';

enum SecureBinary {
  privateKey,
}

String ownIdentityDBName = "";

Future<String> loadSQL(String file) async {
  return await rootBundle.loadString('sql/' + file + '.sql');
}

Future<void> executeMany(Database db, String sql) async {
  for (final query in sql.split(";\n")) {
    if (query.trim() != "") {
      await db.execute(query);
    }
  }
}

Future<void> executeManyFromFile(Database db, String file) async {
  String sql = await loadSQL(file);
  await executeMany(db, sql);
}

Future<void> databaseUpdateFingerprint(Database db) async {
  final List<Map<String, dynamic>> maps = await db.query(
    'dbkeyInfos',
    orderBy: 'name ASC',
  );
  final fingerprints = <String, int>{};
  final batch = db.batch();
  for (final readonly in maps) {
    final e = Map<String, dynamic>.from(readonly);
    final type = publicKeyTypeFromInt(e['public_key_type']);
    var fingerprint = fingerprintFromPublicKey(e['public_key'], type);
    if (fingerprints.containsKey(fingerprint)) {
      final count = fingerprints[fingerprint]!;
      e['duplicate'] = 1;
      // fingerprint is unique
      e['fingerprint'] = fingerprint + "_DUP" + count.toString();
      fingerprints[fingerprint] = count + 1;
    } else {
      e['duplicate'] = 0;
      e['fingerprint'] = fingerprint;
      fingerprints[fingerprint] = 1;
    }
    batch.insert(
      'dbkeyInfos', e, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  await batch.commit();
}

Future<Database> openOrCreateDatabase() async {
  var databasesPath = await getDatabasesPath();
  var path = databasesPath + '/main.db';
  return await openDatabase(path, version: 4,
    onCreate: (Database db, int version) async {
      await executeManyFromFile(db, "create_tables");
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await executeManyFromFile(db, "upgrade/2");
      }
      if (oldVersion < 3) {
        await executeManyFromFile(db, "upgrade/3_pre");
        await databaseUpdateFingerprint(db);
        await executeManyFromFile(db, "upgrade/3_post");
      }
      if (oldVersion < 4) {
        // Fix also ed25519 keys
        await databaseUpdateFingerprint(db);
      }
    },
  );
}

class PersonalInformation {
  final CryptographicId_PersonalInformationType property;
  final String value;
  final int date;
  final Uint8List signature;

  PersonalInformation({
    required this.property,
    required this.value,
    required this.date,
    required this.signature
  });

  Map<String, Object> toMap() {
    return <String, Object>{
      "property": property.name,
      "value": value,
      "date": date,
      "signature": signature,
    };
  }

  @override
  String toString() {
    return '$property: $value';
  }
}

class DBIdentity {
  final String name;
  final Uint8List publicKey;
  final String fingerprint;
  final bool duplicate;
  final CryptographicId_PublicKeyType publicKeyType;
  final Uint8List signature;
  final int date;
  final Map<CryptographicId_PersonalInformationType,
            PersonalInformation> personalInformation;

  DBIdentity({
    required this.name,
    required this.publicKey,
    required this.fingerprint,
    required this.duplicate,
    required this.publicKeyType,
    required this.date,
    required this.signature,
    required this.personalInformation,
  });

  Map<String, Object> toMap() {
    return <String, Object>{
      "name": name,
      "public_key": publicKey,
      "fingerprint": fingerprint,
      "duplicate": duplicate ? 1 : 0,
      "public_key_type": publicKeyType.value,
      "date": date,
      "signature": signature,
    };
  }

  @override
  String toString() {
    return '$name: $fingerprint ( ' + personalInformation.toString() + ' )';
  }
}


Future<DBIdentity> identityFromMap(Storage storage, Map<String, dynamic> entry) async {
  final pi = await storage.fetchPersonalInformation(entry["name"]);
  final duplicate = entry["duplicate"] != 0;
  var fingerprint = entry["fingerprint"];
  if (duplicate) {
    fingerprint = fingerprint.split("_DUP")[0];
  }
  return DBIdentity(
    name: entry["name"],
    date: entry["date"],
    publicKey: entry["public_key"],
    fingerprint: fingerprint,
    duplicate: duplicate,
    publicKeyType: publicKeyTypeFromInt(entry["public_key_type"]),
    signature: entry["signature"],
    personalInformation: pi,
  );
}

String binaryToString(Uint8List l) {
  return l.join(",");
}

Uint8List stringToBinary(String s) {
  return Uint8List.fromList(s.split(",").map(int.parse).toList().cast<int>());
}

CryptographicId_PersonalInformationType personalInformationTypeFromString(String s) {
  // protobuf enum should never have information removed
  // so this should always find something
  return CryptographicId_PersonalInformationType.values.firstWhere(
    (e) => e.toString().split(".").last == s);
}

CryptographicId_PublicKeyType publicKeyTypeFromInt(int s) {
  return CryptographicId_PublicKeyType.values.firstWhere((e) => e.value == s);
}

class Storage {
  final AndroidOptions aOptions = const AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const FlutterSecureStorage storage = FlutterSecureStorage();
  final Database database;
  final int slot = 0;

  Storage._create(this.database);

  static Future<Storage> _createWithDB() async {
    var db = await openOrCreateDatabase();
    return Storage._create(db);
  }

  String _secureBinaryKeyName(SecureBinary s) {
    return slot.toString() + "_" + s.name;
  }

  Future<Uint8List?> secureBinaryRead(SecureBinary s) async {
    final key = _secureBinaryKeyName(s);
    final val = await storage.read(key: key, aOptions: aOptions);
    if (val == null) {
      return null;
    }
    return stringToBinary(val);
  }

  Future<void> secureBinaryWrite(SecureBinary s, Uint8List val) async {
    final key = _secureBinaryKeyName(s);
    final str = binaryToString(val);
    await storage.write(key: key, value: str, aOptions: aOptions);
  }

  Future<void> _upsertPersonalInfo(Batch batch, DBIdentity key) async {
    for (final entry in key.personalInformation.entries) {
      final map = entry.value.toMap();
      map["public_key_name"] = key.name;
      batch.insert("PersonalInformation",
                   map,
                   conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> upsertPersonalInfo(DBIdentity key) async {
    final batch = database.batch();
    await _upsertPersonalInfo(batch, key);
    await batch.commit();
  }

  Future<DBIdentity> insertKeyInfo(DBIdentity key) async {
    var map = key.toMap();
    map["slot"] = slot;
    final batch = database.batch();
    await database.insert("dbkeyinfos", map);
    await _upsertPersonalInfo(batch, key);
    await batch.commit();
    return key;
  }

  Future<Map<CryptographicId_PersonalInformationType, PersonalInformation>>
      fetchPersonalInformation(String name) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'PersonalInformation',
      where: 'public_key_name = ?',
      whereArgs: [name]);
    return Map.fromEntries(maps.where((e) => !e["value"].isEmpty).map((e) {
      final prop = personalInformationTypeFromString(e["property"]);
      return MapEntry(prop, PersonalInformation(
        property: prop,
        value: e["value"],
        date: e["date"],
        signature: e["signature"],
      ));
    }));
  }

  Future<List<DBIdentity>> fetchKeyInfos() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'dbkeyInfos',
      where: 'slot = ? AND NOT deleted AND name != ?',
      whereArgs: [slot, ownIdentityDBName],
      orderBy: 'name ASC',
    );
    return await Future.wait(List.generate(maps.length, (i) async {
      return await identityFromMap(this, maps[i]);
    }));
  }

  Future<bool> existsKeyInfoWithName(String name) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'dbkeyinfos',
      where: 'name = ? AND slot = ? AND NOT deleted',
      whereArgs: [name, slot]);
    if (maps.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<DBIdentity?> fetchKeyInfo(String name) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'dbkeyinfos',
      where: 'name = ? AND slot = ? AND NOT deleted',
      whereArgs: [name, slot]);
    if (maps.isNotEmpty) {
      return await identityFromMap(this, maps.first);
    }
    return null;
  }

  Future<DBIdentity?> fetchOwnKeyInfo() async {
    return fetchKeyInfo(ownIdentityDBName);
  }

  Future<DBIdentity?> fetchKeyInfoFromKey(
    Uint8List key,
    CryptographicId_PublicKeyType type
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'dbkeyinfos',
      where: 'fingerprint = ? AND slot = ? AND NOT deleted',
      whereArgs: [fingerprintFromPublicKey(key, type), slot]);
    if (maps.isNotEmpty) {
      return await identityFromMap(this, maps.first);
    }
    return null;
  }

  Future<void> close() {
    return database.close();
  }
}

DBIdentity createPlaceholderOwnID() {
  return DBIdentity(
    name: ownIdentityDBName,
    publicKey: Uint8List(0),
    fingerprint: "",
    duplicate: false,
    date: 0,
    signature: Uint8List(0),
    publicKeyType: CryptographicId_PublicKeyType.Ed25519,
    personalInformation: {},
  );
}

bool isPlaceholderOwnID(DBIdentity id) {
  return id.fingerprint == "";
}

Future<Storage> storage = Storage._createWithDB();

Future<Storage> getStorage() {
  return storage;
}

Future<Storage> createForTestsOnly() {
  return Storage._createWithDB();
}
