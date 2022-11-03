import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/utils/utils.dart' as utils;

enum Secure {
  publicKey,
  privateKey,
}

Future<String> loadSQL(String file) async {
  return await rootBundle.loadString('sql/' + file + '.sql');
}

Future<String> createTableSQL = loadSQL("create_tables");

Future<Database> openOrCreateDatabase() async {
  var databasesPath = await getDatabasesPath();
  var path = databasesPath + '/main.db';
  return await openDatabase(path, version: 1,
    onCreate: (Database db, int version) async {
      final sql = await createTableSQL;
      for (final query in sql.split(";\n")) {
        if (query.trim() != "") {
          await db.execute(query);
        }
      }
    }
  );
}

class PersonalInformation {
  final String property;
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
      "property": property,
      "value": value,
      "date": date,
      "signature": signature,
    };
  }

  String toString() {
    return '$property: $value';
  }
}

class DBKeyInfo {
  final String name;
  final Uint8List publicKey;
  final Uint8List signature;
  final int date;
  final Map<String, PersonalInformation> personalInformation;

  DBKeyInfo({
    required this.name,
    required this.publicKey,
    required this.date,
    required this.signature,
    required this.personalInformation,
  });

  Map<String, Object> toMap() {
    return <String, Object>{
      "name": name,
      "public_key": publicKey,
      "date": date,
      "signature": signature,
    };
  }

  String toString() {
    return '$name: $publicKey ( ' + personalInformation.toString() + ' )';
  }
}


Future<DBKeyInfo> publicKeyFromMap(Storage storage, Map<String, dynamic> entry) async {
  final pi = await storage.fetchPersonalInformation(entry["name"]);
  return DBKeyInfo(
    name: entry["name"],
    date: entry["date"],
    publicKey: entry["public_key"],
    signature: entry["signature"],
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

  Future<void> upsertPersonalInfo(DBKeyInfo key) async {
    final batch = database.batch();
    for (final entry in key.personalInformation.entries) {
      final map = entry.value.toMap();
      map["public_key_name"] = key.name;
      batch.insert("PersonalInformation",
                   map,
                   conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<DBKeyInfo> insertKeyInfo(DBKeyInfo key) async {
    var map = key.toMap();
    map["slot"] = slot;
    await database.insert("dbkeyinfos", map);
    await upsertPersonalInfo(key);
    return key;
  }

  Future<Map<String, PersonalInformation>> fetchPersonalInformation(
      String name) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'PersonalInformation',
      where: 'public_key_name = ?',
      whereArgs: [name]);
    return {
      for (final e in maps)
        e["property"]: PersonalInformation(
          property: e["property"],
          value: e["value"],
          date: e["date"],
          signature: e["signature"],
        )
    };
  }

  Future<List<DBKeyInfo>> fetchKeyInfos() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'dbkeyInfos',
      where: 'slot = ?',
      whereArgs: [slot]);
    return await Future.wait(List.generate(maps.length, (i) async {
      return await publicKeyFromMap(this, maps[i]);
    }));
  }

  Future<bool> existsKeyInfoWithName(String name) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'dbkeyinfos',
      where: 'name = ? AND slot = ?',
      whereArgs: [name, slot]);
    if (maps.length > 0) {
      return true;
    }
    return false;
  }

  Future<DBKeyInfo?> fetchKeyInfo(String name) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'dbkeyinfos',
      where: 'name = ? AND slot = ? AND NOT deleted',
      whereArgs: [name, slot]);
    if (maps.length > 0) {
      return await publicKeyFromMap(this, maps.first);
    }
    return null;
  }

  Future<DBKeyInfo?> fetchKeyInfoFromKey(Uint8List key) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'dbkeyinfos',
      where: 'hex(public_key) = ? AND slot = ? AND NOT deleted',
      whereArgs: [utils.hex(key), slot]);
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
