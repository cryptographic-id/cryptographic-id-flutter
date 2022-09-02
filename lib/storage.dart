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

Future<Database> openOrCreateDatabase() async {
  var databasesPath = await getDatabasesPath();
  var path = databasesPath + '/main.db';
  return await openDatabase(path, version: 1,
    onCreate: (Database db, int version) async {
      await db.execute(await createTableSQL);
    }
  );
}

class PublicKey {
  final int? id;
  final String name;
  final List<int> publicKey;

  PublicKey({
    required this.name,
    required this.publicKey,
    this.id,
  });

  String toString() {
    return '$id: $name: $publicKey';
  }
}

class Storage {
  final AndroidOptions aOptions = const AndroidOptions(
    encryptedSharedPreferences: true,
  );
  final FlutterSecureStorage storage = new FlutterSecureStorage();
  final Database database;

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

  Future<PublicKey> insertPubKey(PublicKey key) async {
    final id = await database.rawInsert(
      await insertPubKeySQL,
      [key.name, key.publicKey.join(",")]);
    return PublicKey(id: id, name: key.name, publicKey: key.publicKey);
  }

  Future<List<PublicKey>> fetchPubKeys() async {
    final List<Map<String, dynamic>> maps = await database.query('PublicKeys');
    return List.generate(maps.length, (i) {
      return PublicKey(
        id: maps[i]["id"],
        name: maps[i]["name"],
        publicKey: maps[i]["key"].split(",").map(
          int.parse).toList().cast<int>(),
      );
    });
  }
}

Future<Storage> storage = Storage._createWithDB();

Future<Storage> getStorage() {
  return storage;
}
