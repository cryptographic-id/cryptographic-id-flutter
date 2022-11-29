import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// import './qr_scan_mlkit.dart';
import './qr_scan_free.dart';

void scanQRCode(String purpose, BuildContext context,
                Function(BuildContext, Uint8List) onScanned) async {
  debugPrint('Scan QR Code');
  var fired = false;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (c) => ScanQR(title: purpose, onScanned: (c, s) {
        debugPrint('after scan');
        if (!fired) {
          Navigator.of(context).pop();
          fired = true;
          onScanned(c, s);
        }
      })
    )
  );
}

Future<Uint8List> scanQRCodeAsync(String purpose, BuildContext context) {
  final completer = Completer<Uint8List>();
  scanQRCode(purpose, context, (c, s) {
    if (!completer.isCompleted) {
      completer.complete(s);
    }
  });
  return completer.future;
}
