# Cryptographic ID

## Attest the trustworthiness of a device using asymmetric cryptography

This is an Android App to create and verify identities based on ed25519
signatures. This app can also verify prime256v1 signatures to support signatures
generated by a tpm2. It can be used to verify devices (e.g. replace `tpm2-otp`) or
people who are in posession of a private key.

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
  alt="Get it on F-Droid"
  height="80">](https://f-droid.org/packages/io.gitlab.cryptographic_id)

## Setup development environment

Install the dart protobuf plugin:
```bash
flutter pub global activate protoc_plugin
```

Generate the protobuf dart files:
```bash
git submodule update --init --recursive
mkdir .dart_tool/flutter_gen/protobuf/
protoc --proto_path=lib/cryptographic-id-protocol --dart_out=.dart_tool/flutter_gen/protobuf lib/cryptographic-id-protocol/cryptographic_id.proto
```

### Build

You can build the app via
```
flutter build apk
```

### Development

To run the app in development mode on your phone, run
```
flutter build
```

## Contributing

Please use `flutter analyze` before opening a pull request.
