import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';


enum Secure {
  publicKey,
  privateKey,
}

Future<String> loadSQL(String file) async {
  return await rootBundle.loadString('sql/' + file + '.sql');
}

Future<String> createTableSQL = loadSQL("create_tables");
Future<String> insertPubKeySQL = loadSQL("insert_publickey");
Future<String> upsertPersonalInfoSQL = loadSQL("upsert_personal_information");

Future<Database> openOrCreateDatabase() async {
  var databasesPath = await getDatabasesPath();
  var path = databasesPath + '/main.db';
  return await openDatabase(path, version: 1,
    onCreate: (Database db, int version) async {
      await db.execute(await createTableSQL);
    }
  );
}

class PersonalInformation {
  final String property;
  final String value;
  final int date;
  final List<int> signature;

  PersonalInformation({
    required this.property,
    required this.value,
    required this.date,
    required this.signature
  });

  String toString() {
    return '$property: $value';
  }
}


class PublicKey {
  final String name;
  final int? slot;
  final List<int> publicKey;
  final List<int> signature;
  final int date;
  final Map<String, PersonalInformation> personalInformation;

  PublicKey({
    required this.name,
    this.slot,
    required this.publicKey,
    required this.date,
    required this.signature,
    required this.personalInformation,
  });

  String toString() {
    return '$name: $publicKey ( ' + personalInformation.toString() + ' )';
  }
}

List<int> stringToIntList(String s) {
  return s.split(",").map(int.parse).toList().cast<int>();
}

String intListToString(List<int> key) {
  return key.join(",");
}

Future<PublicKey> publicKeyFromMap(Storage storage, Map<String, dynamic> entry) async {
  final pi = await storage.fetchPersonalInformation(entry["name"]);
  return PublicKey(
    name: entry["name"],
    date: entry["date"],
    slot: entry["slot"],
    publicKey: stringToIntList(entry["public_key"]),
    signature: stringToIntList(entry["signature"]),
    personalInformation: pi,
  );
}

class Storage {
  final AndroidOptions aOptions = const AndroidOptions(
    encryptedSharedPreferences: true,
  );
  final FlutterSecureStorage storage = new FlutterSecureStorage();
  final Database database;
  final int slot = 0;

  Storage._create(this.database);

  static Future<Storage> _createWithDB() async {
    var db = await openOrCreateDatabase();
    return new Storage._create(db);
  }

  Future<String?> secureRead(Secure s) async {
    return await storage.read(key: s.name, aOptions: aOptions);
  }

  Future<void> secureWrite(Secure s, String val) async {
    await storage.write(key: s.name, value: val, aOptions: aOptions);
  }

  Future<void> upsertPersonalInfo(
      String name, Map<String, PersonalInformation> piMap) async {
    final batch = database.batch();
    for (final entry in piMap.entries) {
      final pi = entry.value;
      batch.rawInsert(
        await upsertPersonalInfoSQL,
        [name,
         pi.property,
         pi.value,
         pi.date,
         intListToString(pi.signature)]);
    }
    await batch.commit();
  }

  Future<PublicKey> insertPublicKey(PublicKey key) async {
    await database.rawInsert(
      await insertPubKeySQL,
      [key.name,
       slot,
       intListToString(key.publicKey),
       key.date,
       intListToString(key.signature)]);
    await upsertPersonalInfo(key.name, key.personalInformation);
    return key;
  }

  Future<Map<String, PersonalInformation>> fetchPersonalInformation(
      String name) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'PersonalInformation',
      where: 'slot = ? AND public_key_name = ?',
      whereArgs: [slot, name]);
    return {
      for (final e in maps)
        e["property"]: PersonalInformation(
          property: e["property"],
          value: e["value"],
          date: e["date"],
          signature: stringToIntList(e["signature"])
        )
    };
  }

  Future<List<PublicKey>> fetchPublicKeys() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'PublicKeys',
      where: 'slot = ?',
      whereArgs: [slot]);
    return await Future.wait(List.generate(maps.length, (i) async {
      return await publicKeyFromMap(this, maps[i]);
    }));
  }

  Future<PublicKey?> fetchPublicKey(String name) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'PublicKeys',
      where: 'name = ? AND slot = ? AND NOT deleted',
      whereArgs: [name, slot]);
    if (maps.length > 0) {
      return await publicKeyFromMap(this, maps.first);
    }
    return null;
  }

  Future<PublicKey?> fetchPublicKeyFromKey(List<int> key) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'PublicKeys',
      where: 'key = ? AND slot = ? AND NOT deleted',
      whereArgs: [intListToString(key), slot]);
    if (maps.length > 0) {
      return await publicKeyFromMap(this, maps.first);
    }
    return null;
  }
}

Future<Storage> storage = Storage._createWithDB();

Future<Storage> getStorage() {
  return storage;
}
