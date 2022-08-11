import 'package:cryptography/cryptography.dart';
import './tuple.dart';

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
