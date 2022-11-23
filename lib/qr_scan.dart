import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:typed_data';

void scanQRCode(String purpose, BuildContext context,
                Function(BuildContext, Uint8List) onScanned) {
  debugPrint('Scan QR Code');
  var fired = false;
  Navigator.of(context).push(
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

class ScanQR extends StatelessWidget {
  const ScanQR({Key? key, required this.title, required this.onScanned}) : super(key: key);
  final String title;
  final Function(BuildContext, Uint8List) onScanned;

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
                  onScanned(context, code);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
