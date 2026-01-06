import 'package:flutter/material.dart';

class WalletTopupModel extends ChangeNotifier {
  double selectedAmount = 10.0;
  bool isProcessing = false;
  String? paymentUrl;
  String? paymentRequestId;
  DateTime? expiresAt;
  List<Map<String, dynamic>> pendingTopUps = [];

  void setAmount(double amount) {
    selectedAmount = amount;
    notifyListeners();
  }

  void setProcessing(bool processing) {
    isProcessing = processing;
    notifyListeners();
  }

  void setPaymentData({
    required String url,
    required String requestId,
    required DateTime expires,
  }) {
    paymentUrl = url;
    paymentRequestId = requestId;
    expiresAt = expires;
    notifyListeners();
  }

  void clearPaymentData() {
    paymentUrl = null;
    paymentRequestId = null;
    expiresAt = null;
    notifyListeners();
  }

  void setPendingTopUps(List<Map<String, dynamic>> topUps) {
    pendingTopUps = topUps;
    notifyListeners();
  }

  void dispose() {
    super.dispose();
  }
}
