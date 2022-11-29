import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
