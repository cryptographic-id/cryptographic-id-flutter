# Cryptographic ID

## Verify identities based on ed25519-signatures

This is an Android App to create and verify identities based on ed25519
signatures. It can be used to verify devices (e.g. replace tpm-otp) or
people who are in posession of a private key.

## Setup development environment

Install the dart protobuf plugin:
```bash
flutter pub global activate protoc_plugin
```

Generate the protobuf dart files:
```bash
git submodule update --init --recursive
protoc --proto_path=lib --dart_out=.dart_tool/flutter_gen/protobuf lib/cryptographic-id-protocol/cryptographic_id.proto
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
