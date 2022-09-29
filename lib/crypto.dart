import 'package:cryptography/cryptography.dart';
import './tuple.dart';
import './protocol/cryptograhic_id.pb.dart';
import 'dart:typed_data';

Future<Tuple<List<int>, List<int>>> createKey() async {
  final algorithm = Ed25519();
  final key = await algorithm.newKeyPair();
  final pubKey = await key.extractPublicKey();
  final publicBytes = pubKey.bytes;
  final privateBytes = await key.extractPrivateKeyBytes();
  return Tuple(item1: privateBytes, item2: publicBytes);
}

Future<bool> verify(List<int> message, List<int> signature, List<int> publicKey) async {
  final algorithm = Ed25519();
  final pubkey = SimplePublicKey(publicKey, type: KeyPairType.ed25519);
  final sig = Signature(signature, publicKey: pubkey);
  final isSignatureCorrect = await algorithm.verify(
    message,
    signature: sig,
  );
  return isSignatureCorrect;
}

Future<List<int>> sign(List<int> message, List<int> key) async {
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPairFromSeed(key);
  final signature = await algorithm.sign(
    message,
    keyPair: keyPair,
  );
  return signature.bytes;
}

Future<bool> verifyCryptographicId(CryptographicId id) async {
  final sig = id.signature;
  final date = id.timestamp;
  final key = id.publicKey;
  final verifyList = Uint8List(8 + key.length);
  final dataToVerify = ByteData.sublistView(verifyList);
  dataToVerify.setUint64(0, date.toInt(), Endian.big);
  verifyList.setAll(8, key);
  if (!await verify(verifyList, sig, key)) {
    return false;
  }
  for (final entry in id.personalInformation) {
    final verifyEntryList = Uint8List(8 + 4 + entry.content.length);
    final entryDataToVerify = ByteData.sublistView(verifyEntryList);
    entryDataToVerify.setUint64(0, entry.timestamp.toInt(), Endian.big);
    entryDataToVerify.setInt32(8, entry.type.value, Endian.big);
    verifyEntryList.setAll(12, entry.content.codeUnits);
    if (!await verify(verifyEntryList, entry.signature, key)) {
      return false;
    }
  }
  return true;
}

int TIMESTAMP_RECENT_DIFF = 60;
bool isSignatureRecent(CryptographicId id) {
  final int timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
  for (final entry in id.personalInformation) {
    if (entry.timestamp < timestamp - TIMESTAMP_RECENT_DIFF) {
      return false;
    }
  }
  return id.timestamp < timestamp - TIMESTAMP_RECENT_DIFF;
}

Map<String, Tuple<String, int>> idToPersonalInfo(CryptographicId id) {
  Map<String, Tuple<String, int>> result = {
    for (final e in id.personalInformation)
      e.type.toString() : Tuple(item1: e.content, item2: e.timestamp.toInt())
  };
  return result;
}
