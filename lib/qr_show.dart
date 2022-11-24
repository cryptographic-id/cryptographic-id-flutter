import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

BarcodeWidget showQRCode(Uint8List data) {
  return BarcodeWidget.fromBytes(
    data: data,
    barcode: Barcode.qrCode());
}

class ShowQR extends StatelessWidget {
  const ShowQR({Key? key, required this.title, required this.data}) : super(key: key);
  final String title;
  final Uint8List data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          showQRCode(data),
        ],
      ),
    );
  }
}
