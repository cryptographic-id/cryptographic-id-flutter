import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';

void scanQRCode(String purpose, BuildContext context, Function(String) onScanned) {
  debugPrint('Scan QR Code');
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (c) => ScanQR(title: "Purpose", onScanned: (s) {
        Navigator.of(context).pop();
        debugPrint('after scan');
        onScanned(s);
      })
    )
  );
}

Future<String> scanQRCodeAsync(String purpose, BuildContext context) {
  var completer = new Completer<String>();
  scanQRCode(purpose, context, (s) {
    completer.complete(s);
  });
  return completer.future;
}

class ScanQR extends StatefulWidget {
  const ScanQR({Key? key, required this.title, required this.onScanned}) : super(key: key);
  final String title;
  final Function(String) onScanned;

  @override
  State<ScanQR> createState() => ScanQRState();
}

class ScanQRState extends State<ScanQR> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR-Code ' + widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MobileScanner(
              allowDuplicates: false,
              controller: MobileScannerController(
                facing: CameraFacing.back, torchEnabled: true),
              onDetect: (barcode, args) {
                if (barcode.rawValue == null) {
                  debugPrint('Failed to scan Barcode');
                } else {
                  final String code = barcode.rawValue!;
                  debugPrint('Barcode found! $code');
                  widget.onScanned(code);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
