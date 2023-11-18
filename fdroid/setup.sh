#!/usr/bin/sh
cp fdroid/qr_scan_free.dart lib
rm lib/qr_scan_mlkit.dart
git apply fdroid/qr_scan.patch
