import 'dart:typed_data';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter_gen/protobuf/cryptographic_id.pb.dart';
import 'package:sqflite_common/utils/utils.dart' as utils;

import "package:pointycastle/digests/sha256.dart";
import "package:pointycastle/ecc/curves/prime256v1.dart";
import "package:pointycastle/ecc/api.dart";
import "package:pointycastle/api.dart";
import "package:pointycastle/asn1.dart";
import "package:pointycastle/signers/ecdsa_signer.dart";
import './tuple.dart';

Future<Tuple<Uint8List, Uint8List>> createKey() async {
  final algorithm = cryptography.Ed25519();
  final key = await algorithm.newKeyPair();
  final pubKey = await key.extractPublicKey();
  final publicBytes = Uint8List.fromList(pubKey.bytes);
  final privateBytes = Uint8List.fromList(await key.extractPrivateKeyBytes());
  return Tuple(item1: privateBytes, item2: publicBytes);
}

Future<bool> verifyEd25519(Uint8List message, Uint8List signature,
                           Uint8List publicKey) async {
  final algorithm = cryptography.Ed25519();
  final pubkey = cryptography.SimplePublicKey(
    publicKey,
    type: cryptography.KeyPairType.ed25519);
  final sig = cryptography.Signature(signature, publicKey: pubkey);
  final isSignatureCorrect = await algorithm.verify(
    message,
    signature: sig,
  );
  return isSignatureCorrect;
}

Future<Uint8List> sign(Uint8List message, Uint8List key) async {
  final algorithm = cryptography.Ed25519();
  final keyPair = await algorithm.newKeyPairFromSeed(key);
  final signature = await algorithm.sign(
    message,
    keyPair: keyPair,
  );
  return Uint8List.fromList(signature.bytes);
}

Future<bool> verifyPrime256v1Sha256(Uint8List message, Uint8List signature,
                                    Uint8List publicKey) async {
  final sigParser = ASN1Parser(Uint8List.fromList(signature));
  final sigElements = (sigParser.nextObject() as ASN1Sequence).elements!;

  final sigR = (sigElements[0] as ASN1Integer).integer!;
  final sigS = (sigElements[1] as ASN1Integer).integer!;
  final eccDomain = ECCurve_prime256v1();
  ECPoint Q = eccDomain.curve.decodePoint(publicKey)!;
  final key = ECPublicKey(Q, eccDomain);
  final signer = ECDSASigner(SHA256Digest());
  signer.init(false, PublicKeyParameter(key));
  final sigObj = ECSignature(sigR, sigS);
  final ok = signer.verifySignature(Uint8List.fromList(message), sigObj);
  return ok;
}

Uint8List idToDataToSign(CryptographicId id) {
  final date = id.timestamp;
  final key = Uint8List.fromList(id.publicKey);
  final msg = Uint8List.fromList(id.msg);
  final list = Uint8List(8 + key.length + msg.length);
  final data = ByteData.sublistView(list);
  data.setUint64(0, date.toInt(), Endian.big);
  list.setAll(8, key);
  list.setAll(8 + key.length, msg);
  return list;
}

Uint8List personalInformationToDataToSign(CryptographicId_PersonalInformation entry) {
  final list = Uint8List(8 + 4 + entry.value.length);
  final data = ByteData.sublistView(list);
  data.setUint64(0, entry.timestamp.toInt(), Endian.big);
  data.setInt32(8, entry.type.value, Endian.big);
  list.setAll(12, entry.value);
  return list;
}

Future<bool> verifyCryptographicId(CryptographicId id) async {
  final sig = Uint8List.fromList(id.signature);
  final key = Uint8List.fromList(id.publicKey);
  final verifyList = idToDataToSign(id);

  var verify = verifyEd25519;
  switch (id.publicKeyType) {
  case CryptographicId_PublicKeyType.Ed25519:
    verify = verifyEd25519;
    break;
  case CryptographicId_PublicKeyType.Prime256v1:
    verify = verifyPrime256v1Sha256;
    break;
  default:
    throw Exception("Unknown signature type");
  }
  if (!await verify(verifyList, sig, key)) {
    return false;
  }
  for (final entry in id.personalInformation) {
    final verifyEntryList = personalInformationToDataToSign(entry);
    final signature = Uint8List.fromList(entry.signature);
    if (!await verify(verifyEntryList, signature, key)) {
      return false;
    }
  }
  return true;
}

Future<void> signCryptographicId(CryptographicId id, Uint8List privateKey) async {
  final data = idToDataToSign(id);
  id.signature = await sign(data, privateKey);
  for (final entry in id.personalInformation) {
    final entryData = personalInformationToDataToSign(entry);
    entry.signature = await sign(entryData, privateKey);
  }
}

int now() {
  return DateTime.now().millisecondsSinceEpoch;
}

const timestampRecentDiff = 60 * 1000;
bool _isTsRecent(int now, fixnum.Int64 ts) {
  return ts >= now - timestampRecentDiff && ts <= now;
}

fixnum.Int64 timestampToMS(fixnum.Int64 ts) {
  if (ts > 1672527600000) { // ms timestamp of 2023
    return ts;
  } else {
    return ts * 1000;
  }
}

int oldestTimestamp(CryptographicId id) {
  int oldest = timestampToMS(id.timestamp).toInt();
  for (final entry in id.personalInformation) {
    final int ts = timestampToMS(entry.timestamp).toInt();
    if (ts < oldest) {
      oldest = ts;
    }
  }
  return oldest;
}

bool isSignatureRecent(CryptographicId id) {
  // do not use oldestTimestamp, since future-timestamps are not checked
  final int timestamp = now();
  for (final entry in id.personalInformation) {
    if (!_isTsRecent(timestamp, timestampToMS(entry.timestamp))) {
      return false;
    }
  }
  return _isTsRecent(timestamp, timestampToMS(id.timestamp));
}

Uint8List encodeBigIntUncompressed(BigInt number) {
  const size = 32;
  final lastByte = BigInt.from(0xff);
  var result = Uint8List(size);
  for (var i = 0; i < size; i++) {
    result[size - i - 1] = (number & lastByte).toInt();
    number = number >> 8;
  }
  if (number != BigInt.from(0)) {
    throw Exception("BigInt is too big to encode it");
  }
  return result;
}

String fingerprintFromPublicKey(
  Uint8List key,
  CryptographicId_PublicKeyType type,
  [bool legacy = false]
) {
  var data = key;
  if (type == CryptographicId_PublicKeyType.Prime256v1) {
    if (legacy) {
      final digest = SHA256Digest();
      data = digest.process(key);
    } else {
      final eccDomain = ECCurve_prime256v1();
      ECPoint? q = eccDomain.curve.decodePoint(key);
      if (q == null || q.x == null || q.y == null) {
        return "Invalid public key";
      }
      final digest = SHA256Digest();
      final bytes = BytesBuilder();
      bytes.add(encodeBigIntUncompressed(q.x!.toBigInteger()!));
      bytes.add(encodeBigIntUncompressed(q.y!.toBigInteger()!));
      data = digest.process(bytes.toBytes());
    }
  } else {
    if (!legacy) {
      if (key.length != 32) {
        return "Invalid ED25519 public key";
      }
      final digest = SHA256Digest();
      final bytes = BytesBuilder();
      bytes.add(key);
      data = digest.process(bytes.toBytes());
    }
  }
  final hex = utils.hex(data);
  if (hex.length != 64) {
    return hex;
  }
  final withColon = hex.replaceAllMapped(
    RegExp(r".{2}"),
    (match) => "${match.group(0)}:");
  return [
    withColon.substring(0, 23),
    withColon.substring(24, 47),
    withColon.substring(48, 71),
    withColon.substring(72, 95)].join("\n");
}
