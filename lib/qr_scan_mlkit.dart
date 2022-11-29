import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQR extends StatelessWidget {
  const ScanQR({Key? key, required this.title, required this.onScanned}) : super(key: key);
  final String title;
  final Function(BuildContext, String) onScanned;

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
                if (barcode.rawValue == null) {
                  debugPrint('Failed to scan Barcode');
                } else {
                  final String code = barcode.rawValue!;
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
