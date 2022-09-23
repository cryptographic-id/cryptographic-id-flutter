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
  return await verify(verifyList, sig, key);
}
