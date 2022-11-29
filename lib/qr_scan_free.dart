import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

Uint8List fixBrokenRawBytes(List<int> code) {
  var toNext = 0;
  var res = <int>[];
  for (var i = 0; i < code.length; i++) {
    if (i != 0) {
      final use = (code[i] & 0xF0);
      res.add(toNext << 4 | use >> 4);
    }
    toNext = code[i] & 0x0F;
  }
  while (res.first == 0) {
    res = res.sublist(1);
  }
  final len2 = res[0] << 8 + res[1];
  if (res.length > len2) {
    return Uint8List.fromList(res.sublist(2, len2 + 2));
  }
  final len1 = res[0];
  return Uint8List.fromList(res.sublist(1, len1 + 1));
}

class ScanQR extends StatefulWidget {
  const ScanQR({Key? key, required this.title, required this.onScanned}) : super(key: key);
  final String title;
  final Function(BuildContext, Uint8List) onScanned;

  @override
  State<StatefulWidget> createState() => _ScanQRState();
}


class _ScanQRState extends State<ScanQR> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  void _onQRViewCreated(QRViewController controller, BuildContext context) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if (scanData.rawBytes == null) {
        debugPrint('Failed to scan Barcode');
      } else {
        final Uint8List code = fixBrokenRawBytes(scanData.rawBytes!);
        debugPrint('Barcode found! $code');
        widget.onScanned(context, code);
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
