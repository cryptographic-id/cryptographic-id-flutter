import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQR extends StatelessWidget {
  const ScanQR({
    Key? key,
    required this.title,
    required this.onScanned,
  }) : super(key: key);
  final String title;
  final Function(BuildContext, String) onScanned;

  @override
  Widget build(BuildContext context) {
    final controller = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      torchEnabled: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue == null) {
              debugPrint('Failed to scan Barcode');
            } else {
              final String code = barcode.rawValue!;
              debugPrint('Barcode found! $code');
              onScanned(context, code);
            }
            return;
          }
        },
      ),
    );
  }
}
