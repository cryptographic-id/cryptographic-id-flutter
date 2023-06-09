import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

BarcodeWidget showQRCode(String data) {
  return BarcodeWidget(
    data: data,
    barcode: Barcode.qrCode());
}

class ShowQR extends StatelessWidget {
  const ShowQR({Key? key, required this.title, required this.data}) : super(key: key);
  final String title;
  final String data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        color: Colors.white, // needed for dark mode
        child: showQRCode(data),
      ),
    );
  }
}
