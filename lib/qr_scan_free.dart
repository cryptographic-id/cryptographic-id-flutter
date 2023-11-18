import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';


class ScanQR extends StatefulWidget {
  const ScanQR({Key? key, required this.title, required this.onScanned}) : super(key: key);
  final String title;
  final Function(BuildContext, String) onScanned;

  @override
  State<StatefulWidget> createState() => _ScanQRState();
}


class _ScanQRState extends State<ScanQR> {
  QRViewController? controller;
  String lastScanned = "";
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  void _onQRViewCreated(QRViewController controller, BuildContext context) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code == null) {
        debugPrint('Failed to scan Barcode');
      } else {
        final code = scanData.code!;
        debugPrint('Barcode found! $code');
        if (code == lastScanned) {
          // sometimes qr_code_scanner returns wrong results
          // these cannot be decoded properly and result in an error
          // this hopefully reduces these problems
          widget.onScanned(context, code);
        }
        lastScanned = code;
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(controller != null && mounted) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 6,
            child: QRView(
              key: qrKey,
              onQRViewCreated: (QRViewController controller) {
                _onQRViewCreated(controller, context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
