import 'dart:async';
import 'package:flutter/material.dart';
import './qr_scan_mlkit.dart';

void scanQRCode(String purpose, BuildContext context,
                Function(BuildContext, String) onScanned) async {
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

Future<String> scanQRCodeAsync(String purpose, BuildContext context) {
  final completer = Completer<String>();
  scanQRCode(purpose, context, (c, s) {
    if (!completer.isCompleted) {
      completer.complete(s);
    }
  });
  return completer.future;
}
