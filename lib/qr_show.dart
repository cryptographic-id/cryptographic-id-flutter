import 'dart:typed_data';
import 'package:barcode_widget/barcode_widget.dart';

BarcodeWidget showQRCode(Uint8List data) {
  return BarcodeWidget.fromBytes(
    data: data,
    barcode: Barcode.qrCode());
}
