#!/usr/bin/bash
set -x -e
export PATH="$(pwd)/flutter/bin:${PATH}"
export PATH="${PATH}:${HOME}/.pub-cache/bin"
flutter pub global activate protoc_plugin
mkdir -p .dart_tool/flutter_gen/protobuf/
mkdir -p .dart_tool/sqflite_common_ffi/databases/
protoc --proto_path=lib/cryptographic-id-protocol \
	--dart_out=.dart_tool/flutter_gen/protobuf \
	lib/cryptographic-id-protocol/cryptographic_id.proto
printf '%s\n%s\n%s\nstoreFile=%s\n' \
	'storePassword=111111' \
	'keyPassword=111111' \
	'keyAlias=c' \
	"$(pwd)/k.jks" > android/key.properties
keytool -genkeypair -v -keystore "$(pwd)/k.jks" \
	-keyalg RSA -keysize 4096 -validity 1 \
	-alias c -keypass 111111 -storepass 111111 \
	-dname 'CN=Android Debug,O=Android,C=US'
run_tests() {
	flutter analyze
	flutter test test
	flutter build apk
	flutter build appbundle
}
run_tests
bash fdroid/setup.sh
run_tests
