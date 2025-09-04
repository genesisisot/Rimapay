import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en', '');
  
  Locale get currentLocale => _currentLocale;
  String get currentLanguage => _currentLocale.languageCode;
  
  void setLanguage(String languageCode) {
    _currentLocale = Locale(languageCode, '');
    notifyListeners();
  }
  
  void toggleLanguage() {
    setLanguage(_currentLocale.languageCode == 'en' ? 'ha' : 'en');
  }
  
  // Translation function
  String t(String key) {
    return _translations[_currentLocale.languageCode]?[key] ?? key;
  }
  
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // Greeting messages
      'goodMorning': 'Good Morning',
      'goodAfternoon': 'Good Afternoon',
      'goodEvening': 'Good Evening',
      
      // Balance and account
      'availableBalance': 'Available Balance',
      'account': 'Account',
      'dailyLimit': 'Daily Limit',
      
      // Tier related
      'upgrade': 'Upgrade',
      'upgradeToUnlock': 'Upgrade to unlock',
      
      // Quick actions
      'sendMoney': 'Send',
      'sendMoneyDesc': 'Transfer funds',
      'addMoney': 'Add Money',
      'addMoneyDesc': 'Fund wallet',
      'quickActions': 'Quick Actions',
      
      // Services
      'airtime': 'Airtime',
      'airtimeDesc': 'Buy airtime',
      'data': 'Data',
      'dataDesc': 'Buy data',
      'electricity': 'Electricity',
      'electricityDesc': 'Pay bills',
      'loans': 'Loans',
      'loansDesc': 'Get loans',
      'cableTV': 'Cable TV',
      'cableTVDesc': 'Pay for TV',
      'moreServices': 'More Services',
      'moreServicesDesc': 'Other services',
      
      // Activity
      'recentActivity': 'Recent Activity',
      'viewAll': 'View All',
      
      // Welcome and onboarding
      'welcome': 'Welcome to RimaPay',
      'getStarted': 'Get Started',
      'createAccount': 'Create Account',
      'signIn': 'Sign In',
      'skipForNow': 'Skip for now',
      
      // Authentication
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'email': 'Email Address',
      'phoneNumber': 'Phone Number',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'signUp': 'Sign Up',
      'login': 'Login',
      'forgotPassword': 'Forgot Password?',
      
      // Navigation
      'home': 'Home',
      'transactions': 'Transactions',
      'cards': 'Cards',
      'profile': 'Profile',
      
      // Common
      'next': 'Next',
      'back': 'Back',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'done': 'Done',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      
      // Promotional Carousel
      'switchToHausa': 'Switch to Hausa',
      'changeLanguageOneTap': 'Change language with one tap',
      'upgradeYourAccount': 'Upgrade Your Account',
      'unlockMoreFeatures': 'Unlock premium features',
      'upgradeAccountNow': 'Upgrade Now',
      'getLoansToday': 'Get Loans Today',
      'quickApprovalProcess': 'Quick approval process',
      'applyForLoan': 'Apply Now',
      'sendMoneyFaster': 'Send Money Faster',
      'instantTransfersToAnyBank': 'Instant transfers to any bank',
      'startSending': 'Start Sending',
      
      // Tier names and benefits
      'underbankingAccount': 'Underbanking Account',
      'basicTier': 'Basic Tier',
      'premiumTier': 'Premium Tier',
      'eliteTier': 'Elite Tier',
      
      // Account types
      'linkedToCooperative': 'Linked to Cooperative',
      'fullBankingAccess': 'Full Banking Access',
    },
    'ha': {
      // Greeting messages
      'goodMorning': 'Barka da safe',
      'goodAfternoon': 'Barka da rana',
      'goodEvening': 'Barka da yamma',
      
      // Balance and account
      'availableBalance': 'Kudin da ke akwai',
      'account': 'Asusu',
      'dailyLimit': 'Iyakar yau da yau',
      
      // Tier related
      'upgrade': 'Inganta',
      'upgradeToUnlock': 'Inganta don buɗewa',
      
      // Quick actions
      'sendMoney': 'Aika',
      'sendMoneyDesc': 'Tura kudi',
      'addMoney': 'Kara Kudi',
      'addMoneyDesc': 'Cika kudi',
      'quickActions': 'Ayyuka masu sauri',
      
      // Services
      'airtime': 'Kredit',
      'airtimeDesc': 'Sayi kredit',
      'data': 'Data',
      'dataDesc': 'Sayi data',
      'electricity': 'Wutar lantarki',
      'electricityDesc': 'Biya kudade',
      'loans': 'Bashi',
      'loansDesc': 'Karbi bashi',
      'cableTV': 'Cable TV',
      'cableTVDesc': 'Biya TV',
      'moreServices': 'Sauran ayyuka',
      'moreServicesDesc': 'Wasu ayyuka',
      
      // Activity
      'recentActivity': 'Ayyukan kwanan nan',
      'viewAll': 'Duba duka',
      
      // Welcome and onboarding
      'welcome': 'Maraba da RimaPay',
      'getStarted': 'Fara',
      'createAccount': 'Kirkiro Asusu',
      'signIn': 'Shiga',
      'skipForNow': 'Tsallake yanzu',
      
      // Authentication
      'firstName': 'Suna na farko',
      'lastName': 'Suna na karshe',
      'email': 'Adireshin Email',
      'phoneNumber': 'Lambar Waya',
      'password': 'Kalmar sirri',
      'confirmPassword': 'Tabbatar da kalmar sirri',
      'signUp': 'Yi rajista',
      'login': 'Shiga',
      'forgotPassword': 'Kun manta da kalmar sirri?',
      
      // Navigation
      'home': 'Gida',
      'transactions': 'Ma\'amaloli',
      'cards': 'Katuna',
      'profile': 'Bayani',
      
      // Common
      'next': 'Na gaba',
      'back': 'Koma baya',
      'cancel': 'Soke',
      'confirm': 'Tabbatar',
      'done': 'An gama',
      'save': 'Ajiye',
      'edit': 'Gyara',
      'delete': 'Share',
      'search': 'Bincike',
      'filter': 'Tace',
      'sort': 'Jera',
      
      // Promotional Carousel
      'switchToHausa': 'Canza zuwa Turanci',
      'changeLanguageOneTap': 'Canza harshe da danna daya',
      'upgradeYourAccount': 'Inganta Asusunka',
      'unlockMoreFeatures': 'Buɗe ƙarin ayyuka',
      'upgradeAccountNow': 'Inganta Yanzu',
      'getLoansToday': 'Samu Bashi Yau',
      'quickApprovalProcess': 'Saurin amincewa',
      'applyForLoan': 'Nema Yanzu',
      'sendMoneyFaster': 'Aika Kudi Da Sauri',
      'instantTransfersToAnyBank': 'Tura kudi nan take zuwa kowane banki',
      'startSending': 'Fara Aikawa',
      
      // Tier names and benefits
      'underbankingAccount': 'Asusu na Underbanking',
      'basicTier': 'Mataki na Asali',
      'premiumTier': 'Mataki na Premium',
      'eliteTier': 'Mataki na Elite',
      
      // Account types
      'linkedToCooperative': 'An haɗa da kamfani',
      'fullBankingAccess': 'Cikakken shiga banki',
    },
  };
}