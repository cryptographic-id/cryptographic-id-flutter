import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import 'dart:typed_data';

void scanQRCode(String purpose, BuildContext context, Function(Uint8List) onScanned) {
  debugPrint('Scan QR Code');
  var fired = false;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (c) => ScanQR(title: purpose, onScanned: (s) {
        debugPrint('after scan');
        if (!fired) {
          Navigator.of(context).pop();
          fired = true;
        }
        onScanned(s);
      })
    )
  );
}

Future<Uint8List> scanQRCodeAsync(String purpose, BuildContext context) {
  var completer = Completer<Uint8List>();
  scanQRCode(purpose, context, (s) {
    if (!completer.isCompleted) {
      completer.complete(s);
    }
  });
  return completer.future;
}

class ScanQR extends StatelessWidget {
  const ScanQR({Key? key, required this.title, required this.onScanned}) : super(key: key);
  final String title;
  final Function(Uint8List) onScanned;

  @override
  Widget build(BuildContext context) {
    final controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MobileScanner(
              allowDuplicates: true, // otherwise binary qr code did not scan
              controller: controller,
              onDetect: (barcode, args) {
                if (barcode.rawBytes == null) {
                  debugPrint('Failed to scan Barcode');
                } else {
                  final Uint8List code = barcode.rawBytes!;
                  debugPrint('Barcode found! $code');
                  onScanned(code);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
