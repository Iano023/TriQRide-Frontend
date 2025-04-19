import 'package:flutter/material.dart';

class QRProvider with ChangeNotifier {
  String? scannedQRCode;
  Map<String, dynamic>? driverData; // Store driver data

  void setScannedQRCode(String qrCode) {
    scannedQRCode = qrCode;
    notifyListeners();
  }

  void setDriverData(Map<String, dynamic> data) {
    driverData = data; // Store the driver data
    notifyListeners();
  }

  Map<String, dynamic>? get getDriverData => driverData; // Getter for driver data
}