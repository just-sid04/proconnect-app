import 'package:flutter/material.dart';
import '../models/wallet_transaction_model.dart';
import '../services/wallet_service.dart';

class WalletProvider with ChangeNotifier {
  double _balance = 0.0;
  String? _referralCode;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  double get balance => _balance;
  String? get referralCode => _referralCode;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWalletData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        WalletService.getWalletBalance(),
        WalletService.getReferralCode(),
        WalletService.getTransactionHistory(),
      ]);

      _balance = results[0] as double;
      _referralCode = results[1] as String?;
      _transactions = results[2] as List<WalletTransaction>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> applyReferral(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await WalletService.applyReferralCode(code);
      await loadWalletData(); // Refresh data
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
