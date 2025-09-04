import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  int _currentNavigationIndex = 0;
  String _currentScreen = 'home';
  Map<String, dynamic> _screenData = {};
  bool _isPinVerificationRequired = false;
  Map<String, dynamic>? _pendingTransaction;
  
  int get currentNavigationIndex => _currentNavigationIndex;
  String get currentScreen => _currentScreen;
  Map<String, dynamic> get screenData => _screenData;
  bool get isPinVerificationRequired => _isPinVerificationRequired;
  Map<String, dynamic>? get pendingTransaction => _pendingTransaction;
  
  void setNavigationIndex(int index) {
    _currentNavigationIndex = index;
    
    // Map navigation index to screen names
    switch (index) {
      case 0:
        _currentScreen = 'home';
        break;
      case 1:
        _currentScreen = 'transactions';
        break;
      case 2:
        _currentScreen = 'cards';
        break;
      case 3:
        _currentScreen = 'profile';
        break;
    }
    
    notifyListeners();
  }
  
  void setCurrentScreen(String screen, {Map<String, dynamic>? data}) {
    _currentScreen = screen;
    if (data != null) {
      _screenData = data;
    } else {
      _screenData.clear();
    }
    notifyListeners();
  }
  
  void updateScreenData(Map<String, dynamic> data) {
    _screenData.addAll(data);
    notifyListeners();
  }
  
  void clearScreenData() {
    _screenData.clear();
    notifyListeners();
  }
  
  void requirePinVerification(Map<String, dynamic> transactionData) {
    _isPinVerificationRequired = true;
    _pendingTransaction = transactionData;
    notifyListeners();
  }
  
  void completePinVerification() {
    _isPinVerificationRequired = false;
    _pendingTransaction = null;
    notifyListeners();
  }
  
  void cancelPinVerification() {
    _isPinVerificationRequired = false;
    _pendingTransaction = null;
    notifyListeners();
  }
  
  // Navigation helpers
  void navigateToHome() {
    setCurrentScreen('home');
    setNavigationIndex(0);
  }
  
  void navigateToTransactions() {
    setCurrentScreen('transactions');
    setNavigationIndex(1);
  }
  
  void navigateToCards() {
    setCurrentScreen('cards');
    setNavigationIndex(2);
  }
  
  void navigateToProfile() {
    setCurrentScreen('profile');
    setNavigationIndex(3);
  }
  
  // Screen navigation
  void navigateToBillPayments() {
    setCurrentScreen('bills');
  }
  
  void navigateToTransfer() {
    setCurrentScreen('transfer');
  }
  
  void navigateToAddMoney() {
    setCurrentScreen('add-money');
  }
  
  void navigateToAirtime() {
    setCurrentScreen('airtime');
  }
  
  void navigateToData() {
    setCurrentScreen('data');
  }
  
  void navigateToElectricity() {
    setCurrentScreen('electricity');
  }
  
  void navigateToCable() {
    setCurrentScreen('cable');
  }
  
  void navigateToLoans() {
    setCurrentScreen('loan-service');
  }
  
  void navigateToSettings() {
    setCurrentScreen('settings');
  }
  
  void navigateToSuccess(Map<String, dynamic> transactionData) {
    setCurrentScreen('success', data: transactionData);
  }
  
  void navigateToReceipt(Map<String, dynamic> receiptData) {
    setCurrentScreen('receipt', data: receiptData);
  }
  
  void navigateToPinVerification(Map<String, dynamic> transactionData) {
    requirePinVerification(transactionData);
    setCurrentScreen('pin-verification', data: transactionData);
  }
  
  // Service-specific navigation
  void navigateToEducation() {
    setCurrentScreen('education-bills');
  }
  
  void navigateToAirtimeToCash() {
    setCurrentScreen('airtime-to-cash');
  }
  
  void navigateToEventTickets() {
    setCurrentScreen('buy-events-tickets');
  }
  
  void navigateToBetting() {
    setCurrentScreen('betting-lottery');
  }
  
  void navigateToPension() {
    setCurrentScreen('voluntary-pension');
  }
  
  void navigateToRoadTransport() {
    setCurrentScreen('road-transport');
  }
  
  void navigateToAirTransport() {
    setCurrentScreen('air-transport');
  }
  
  void navigateToStateGovernment() {
    setCurrentScreen('state-government');
  }
  
  // Utility methods
  bool isBottomNavScreen() {
    return ['home', 'transactions', 'cards', 'profile'].contains(_currentScreen);
  }
  
  bool canGoBack() {
    return !isBottomNavScreen() && _currentScreen != 'splash' && _currentScreen != 'welcome';
  }
  
  void goBack() {
    if (canGoBack()) {
      navigateToHome();
    }
  }
}