import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Complete translations with all screens and features
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Home Screen
      'goodMorning': 'Good morning ✨',
      'goodAfternoon': 'Good afternoon ✨',
      'goodEvening': 'Good evening ✨',
      'availableBalance': 'Available Balance',
      'account': 'Account',
      'sendMoney': 'Send Money',
      'sendMoneyDesc': 'To friends & family',
      'addMoney': 'Add Money',
      'addMoneyDesc': 'Top up wallet',
      'quickActions': 'Quick Actions',
      'recentActivity': 'Recent Activity',
      'viewAll': 'View all →',
      
      // Services
      'airtime': 'Airtime',
      'airtimeDesc': 'Top up phone',
      'data': 'Data',
      'dataDesc': 'Buy plans',
      'electricity': 'Electricity',
      'electricityDesc': 'Pay bills',
      'loans': 'Loans',
      'loansDesc': 'Quick approval',
      'cableTV': 'Cable TV',
      'cableTVDesc': 'Subscriptions',
      'moreServices': 'More Services',
      'moreServicesDesc': 'All bill services',
      'upgradeToUnlock': 'Upgrade to Unlock',
      
      // Navigation
      'home': 'Home',
      'transactions': 'History',
      'cards': 'Cards',
      'profile': 'Profile',
      'settings': 'Settings',
      
      // Bill Payment Services
      'education': 'Education',
      'educationDesc': 'School fees & more',
      'transport': 'Transport',
      'transportDesc': 'Bus & flight tickets',
      'betting': 'Betting',
      'bettingDesc': 'Sports & lottery',
      'pension': 'Pension',
      'pensionDesc': 'Voluntary contributions',
      'government': 'Government',
      'governmentDesc': 'Tax & permits',
      'airtimeToCash': 'Airtime to Cash',
      'airtimeToCashDesc': 'Convert airtime',
      'eventTickets': 'Event Tickets',
      'eventTicketsDesc': 'Movies & concerts',
      
      // Underbanking specific
      'underbankingAccount': 'Underbanking Account',
      'cooperativeName': 'Nigerian Unity Cooperative',
      'linkedToCooperative': 'Linked to: Nigerian Unity Cooperative',
      'dailyLimit': 'Daily limit: ₦50,000',
      
      // Authentication & Onboarding
      'welcomeBack': 'Welcome Back',
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'createAccount': 'Create Account',
      'forgotPassword': 'Forgot Password?',
      'enterEmail': 'Enter Email',
      'enterPassword': 'Enter Password',
      'fullName': 'Full Name',
      'phoneNumber': 'Phone Number',
      'welcomeToRimaPay': 'Welcome to RimaPay',
      'getStarted': 'Get Started',
      'alreadyHaveAccount': 'Already have an account?',
      'dontHaveAccount': "Don't have an account?",
      
      // Promotional Carousel
      'upgradeYourAccount': 'Upgrade Your Account',
      'unlockMoreFeatures': 'Unlock more features and higher limits',
      'getLoansToday': 'Get Loans Today',
      'quickApprovalProcess': 'Quick approval process',
      'sendMoneyFaster': 'Send Money Faster',
      'instantTransfersToAnyBank': 'Instant transfers to any bank',
      'upgradeAccountNow': 'Upgrade Now',
      'applyForLoan': 'Apply for Loan',
      'startSending': 'Start Sending',
      
      // Language Toggle
      'switchToHausa': 'Switch to Hausa Language',
      'changeLanguageOneTap': 'Change your app language with one tap',
      
      // Onboarding Slides
      'slide1Title': 'We are Indigenous,\\nOpen for Us',
      'slide1Subtitle': 'Nigerian Heritage',
      'slide1Description': 'Built by Nigerians, for Nigerians. Experience financial freedom rooted in our rich culture and unwavering spirit of excellence.',
      'slide2Title': 'RimaPay is\\nfor Everyone',
      'slide2Subtitle': 'Every Nigerian',
      'slide2Description': 'From corporate professionals to market entrepreneurs - financial freedom for all Nigerians, everywhere.',
      'slide3Title': 'Payments Made\\nSeamless',
      'slide3Subtitle': 'Effortless Experience',
      'slide3Description': 'Tap, pay, done. Experience the future of payments with instant, secure, and intuitive transactions.',
      
      // Common Actions
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'back': 'Back',
      'next': 'Next',
      'continue': 'Continue',
      'done': 'Done',
      'close': 'Close',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'amount': 'Amount',
      'recipient': 'Recipient',
      'description': 'Description',
      'reference': 'Reference',
      'fee': 'Fee',
      'total': 'Total',
      'success': 'Success',
      'failed': 'Failed',
      'pending': 'Pending',
      
      // Transfer & Money Management
      'transfer': 'Transfer',
      'transferMoney': 'Transfer Money',
      'bankTransfer': 'Bank Transfer',
      'walletTransfer': 'Wallet Transfer',
      'selectBank': 'Select Bank',
      'accountNumber': 'Account Number',
      'enterAmount': 'Enter Amount',
      'transferFee': 'Transfer Fee',
      'addMoneyToWallet': 'Add Money to Wallet',
      'fundWallet': 'Fund Wallet',
      'bankAccount': 'Bank Account',
      'debitCard': 'Debit Card',
      
      // PIN and Security
      'enterPin': 'Enter PIN',
      'confirmTransaction': 'Confirm Transaction',
      'verifyTransaction': 'Verify Transaction',
      'transactionPin': 'Transaction PIN',
      'createPin': 'Create PIN',
      'confirmPin': 'Confirm PIN',
      'biometricAuth': 'Biometric Authentication',
      'useFaceId': 'Use Face ID',
      'useFingerprint': 'Use Fingerprint',
      
      // Account Management
      'accountTiers': 'Account Tiers',
      'tierUpgrade': 'Tier Upgrade',
      'currentTier': 'Current Tier',
      'upgradeTier': 'Upgrade Tier',
      'tierBenefits': 'Tier Benefits',
      'dailyTransactionLimit': 'Daily Transaction Limit',
      'monthlyTransactionLimit': 'Monthly Transaction Limit',
      'bvnVerification': 'BVN Verification',
      'kycVerification': 'KYC Verification',
      'idVerification': 'ID Verification',
      
      // Receipt and Transaction Details
      'receipt': 'Receipt',
      'transactionReceipt': 'Transaction Receipt',
      'transactionDetails': 'Transaction Details',
      'transactionHistory': 'Transaction History',
      'downloadReceipt': 'Download Receipt',
      'shareReceipt': 'Share Receipt',
      'repeatTransaction': 'Repeat Transaction',
      'saveBeneficiary': 'Save Beneficiary',
      'savedBeneficiaries': 'Saved Beneficiaries',
      
      // NEW RECEIPT SCREEN SPECIFIC TRANSLATIONS
      'type': 'Type',
      'network': 'Network',
      'bank': 'Bank',
      'date': 'Date',
      'time': 'Time',
      'secureTransaction': 'Secure & encrypted transaction',
      'cbnLicensed': 'CBN licensed and regulated',
      'receiptShared': 'Receipt shared successfully',
      'receiptDownloaded': 'Receipt downloaded successfully',
      'backToHome': 'Back to Home',
      
      // Bill Payment Specific
      'selectProvider': 'Select Provider',
      'selectPlan': 'Select Plan',
      'meterNumber': 'Meter Number',
      'customerNumber': 'Customer Number',
      'smartCardNumber': 'Smart Card Number',
      'institution': 'Institution',
      'route': 'Route',
      'destination': 'Destination',
      'departure': 'Departure',
      'returnDate': 'Return Date',
      'passengers': 'Passengers',
      'seatNumber': 'Seat Number',
      
      // Settings
      'notifications': 'Notifications',
      'security': 'Security',
      'privacy': 'Privacy',
      'helpSupport': 'Help & Support',
      'aboutApp': 'About App',
      'logout': 'Logout',
      'changeLanguage': 'Change Language',
      'darkMode': 'Dark Mode',
      'pushNotifications': 'Push Notifications',
      'emailNotifications': 'Email Notifications',
      'smsNotifications': 'SMS Notifications',
      'changePin': 'Change PIN',
      'changeBiometric': 'Change Biometric',
      'twoFactorAuth': 'Two-Factor Authentication',
      'deleteAccount': 'Delete Account',
      
      // Error Messages
      'errorOccurred': 'An error occurred',
      'networkError': 'Network error. Please try again.',
      'invalidPin': 'Invalid PIN. Please try again.',
      'insufficientFunds': 'Insufficient funds',
      'transactionFailed': 'Transaction failed',
      'serviceUnavailable': 'Service temporarily unavailable',
      'invalidAmount': 'Invalid amount',
      'invalidPhoneNumber': 'Invalid phone number',
      'invalidAccountNumber': 'Invalid account number',
      
      // Success Messages
      'transactionSuccessful': 'Transaction Successful',
      'paymentCompleted': 'Payment Completed',
      'transferSuccessful': 'Transfer Successful',
      'topupSuccessful': 'Top-up Successful',
      'billPaidSuccessfully': 'Bill Paid Successfully',

      // ==================== NEW TRANSFER SCREEN KEYS ====================
      // Transfer Tab Labels
      'recent': 'Recent',
      'recentRecipients': 'Recent Recipients',
      
      // Wallet Transfer Options
      'scanQRCode': 'Scan QR Code',
      'scanToTransfer': 'Scan QR code to transfer',
      'phoneTransfer': 'Phone Transfer',
      'transferUsingPhone': 'Transfer using phone number',
      'contacts': 'Contacts',
      'transferToContacts': 'Transfer to your contacts',
      
      // Form Labels and Placeholders
      'optional': 'Optional',
      'enterDescription': 'Enter description (optional)',
      
      // Validation Messages
      'accountNumberRequired': 'Account number is required',
      'amountRequired': 'Amount is required',
      'minimumAmount100': 'Minimum amount is ₦100',
      'selectBankFirst': 'Please select a bank first',
      'validateAccountFirst': 'Please validate account number first',
      'selectTransferMethod': 'Please select a transfer method',
      
      // Recent Recipients
      'lastUsed': 'Last used',
    },
    
    'ha': {
      // Home Screen
      'goodMorning': 'Barka da safiya ✨',
      'goodAfternoon': 'Barka da yamma ✨',
      'goodEvening': 'Barka da maraice ✨',
      'availableBalance': 'Kudade da ake da su',
      'account': 'Asusun',
      'sendMoney': 'Aika Kudi',
      'sendMoneyDesc': 'Ga abokanka da iyalanka',
      'addMoney': 'Kara Kudi',
      'addMoneyDesc': 'Cika jakar kudi',
      'quickActions': 'Saurin Ayyuka',
      'recentActivity': 'Ayyukan Kwanakin Baya',
      'viewAll': 'Duba duka →',
      
      // Services
      'airtime': 'Airtime',
      'airtimeDesc': 'Cika wayar',
      'data': 'Data',
      'dataDesc': 'Sayi tsare-tsare',
      'electricity': 'Wutar Lantarki',
      'electricityDesc': 'Biya kudade',
      'loans': 'Rancen Kudi',
      'loansDesc': 'Saurin amincewa',
      'cableTV': 'Talabijin',
      'cableTVDesc': 'Biyan kuɗin watanni',
      'moreServices': 'Wasu Hidimomi',
      'moreServicesDesc': 'Duk sabis na biyan kuɗi',
      'upgradeToUnlock': 'Haɓaka don Buɗewa',
      
      // Navigation
      'home': 'Gida',
      'transactions': 'Tarihi',
      'cards': 'Katuna',
      'profile': 'Bayani',
      'settings': 'Saitunan',
      
      // Bill Payment Services
      'education': 'Ilimi',
      'educationDesc': 'Kuɗin makaranta da sauransu',
      'transport': 'Sufuri',
      'transportDesc': 'Tikitin bus da jirgin sama',
      'betting': 'Caca',
      'bettingDesc': 'Wasannin motsa jiki da caca',
      'pension': 'Pension',
      'pensionDesc': 'Gudummawar son rai',
      'government': 'Gwamnati',
      'governmentDesc': 'Haraji da izini',
      'airtimeToCash': 'Airtime zuwa Kuɗi',
      'airtimeToCashDesc': 'Canza airtime',
      'eventTickets': 'Tikitin Taron',
      'eventTicketsDesc': 'Fim da wasan kwaikwayo',
      
      // Underbanking specific
      'underbankingAccount': 'Asusun Underbanking',
      'cooperativeName': 'Ƙungiyar Haɗin Kan Najeriya',
      'linkedToCooperative': 'Haɗe da: Ƙungiyar Haɗin Kan Najeriya',
      'dailyLimit': 'Iyakar yau da kullun: ₦50,000',
      
      // Authentication & Onboarding
      'welcomeBack': 'Maraba da komowa',
      'signIn': 'Shiga',
      'signUp': 'Yi Rijista',
      'createAccount': 'Ƙirƙiri Asusun',
      'forgotPassword': 'Ka manta da kalmar sirri?',
      'enterEmail': 'Shigar da Imel',
      'enterPassword': 'Shigar da Kalmar Sirri',
      'fullName': 'Cikakken Suna',
      'phoneNumber': 'Lambar Waya',
      'welcomeToRimaPay': 'Maraba zuwa RimaPay',
      'getStarted': 'Fara',
      'alreadyHaveAccount': 'Kana da asusun?',
      'dontHaveAccount': 'Ba ka da asusun?',
      
      // Promotional Carousel - Optimized for mobile
      'upgradeYourAccount': 'Haɓaka Asusunka',
      'unlockMoreFeatures': 'Buɗe ƙarin abubuwa',
      'getLoansToday': 'Sami Bashi Yau',
      'quickApprovalProcess': 'Saurin amincewa',
      'sendMoneyFaster': 'Aika Kudi Sauri',
      'instantTransfersToAnyBank': 'Canja kuɗi nan take',
      'upgradeAccountNow': 'Haɓaka Yanzu',
      'applyForLoan': 'Nemi Bashi',
      'startSending': 'Fara Aikawa',
      
      // Language Toggle
      'switchToHausa': 'Canza zuwa Turanci',
      'changeLanguageOneTap': 'Canja harshen app da dannawa ɗaya',
      
      // Onboarding Slides
      'slide1Title': 'Mu \'yan ƙasa ne,\\nBuɗe mana',
      'slide1Subtitle': 'Al\'adun Najeriya',
      'slide1Description': 'Muka gina shi da Najeriyawa, domin Najeriyawa. Ku ji \'yancin kuɗi wanda ya dogara ga al\'adunmu.',
      'slide2Title': 'RimaPay na\\nKowa da Kowa',
      'slide2Subtitle': 'Kowane Banajeriyanci',
      'slide2Description': 'Daga ma\'aikatan kamfanoni zuwa \'yan kasuwa - \'yancin kuɗi ga dukan Najeriyawa.',
      'slide3Title': 'Biyan Kuɗi\\nCikin Sauƙi',
      'slide3Subtitle': 'Gogayya ba tare da wahala',
      'slide3Description': 'Danna, biya, gama. Ku ji makomar biyan kuɗi da sauri, aminci, da sauƙi.',
      
      // Common Actions
      'save': 'Ajiye',
      'edit': 'Gyara',
      'delete': 'Share',
      'back': 'Koma',
      'next': 'Na gaba',
      'continue': 'Ci gaba',
      'done': 'An gama',
      'close': 'Rufe',
      'confirm': 'Tabbatar',
      'cancel': 'Soke',
      'amount': 'Adadin',
      'recipient': 'Mai karɓa',
      'description': 'Bayanin',
      'reference': 'Tunani',
      'fee': 'Kuɗin sabis',
      'total': 'Jimillar',
      'success': 'Nasara',
      'failed': 'Ya kasa',
      'pending': 'Ana jira',
      
      // Transfer & Money Management
      'transfer': 'Canja wurin',
      'transferMoney': 'Canja Kuɗi',
      'bankTransfer': 'Canja Banki',
      'walletTransfer': 'Canja Jaka',
      'selectBank': 'Zaɓi Banki',
      'accountNumber': 'Lambar Asusun',
      'enterAmount': 'Shigar da Adadin',
      'transferFee': 'Kuɗin Canja wurin',
      'addMoneyToWallet': 'Kara Kuɗi ga Jaka',
      'fundWallet': 'Cika Jaka',
      'bankAccount': 'Asusun Banki',
      'debitCard': 'Katin Debit',
      
      // PIN and Security
      'enterPin': 'Shigar da PIN',
      'confirmTransaction': 'Tabbatar da Ma\'amala',
      'verifyTransaction': 'Tabbatar da Ma\'amala',
      'transactionPin': 'PIN na Ma\'amala',
      'createPin': 'Ƙirƙiri PIN',
      'confirmPin': 'Tabbatar da PIN',
      'biometricAuth': 'Tabbatar da Biometric',
      'useFaceId': 'Yi amfani da Face ID',
      'useFingerprint': 'Yi amfani da Hoton Yatsa',
      
      // Account Management
      'accountTiers': 'Matakan Asusun',
      'tierUpgrade': 'Haɓaka Matsayi',
      'currentTier': 'Matsayin Yanzu',
      'upgradeTier': 'Haɓaka Matsayi',
      'tierBenefits': 'Fa\'idodin Matsayi',
      'dailyTransactionLimit': 'Iyakar Ma\'amala ta Yau da kullun',
      'monthlyTransactionLimit': 'Iyakar Ma\'amala ta Wata',
      'bvnVerification': 'Tabbatar da BVN',
      'kycVerification': 'Tabbatar da KYC',
      'idVerification': 'Tabbatar da ID',
      
      // Receipt and Transaction Details
      'receipt': 'Rasit',
      'transactionReceipt': 'Rasitin Ma\'amala',
      'transactionDetails': 'Cikakkun Bayanai na Ma\'amala',
      'transactionHistory': 'Tarihin Ma\'amala',
      'downloadReceipt': 'Sauke Rasit',
      'shareReceipt': 'Raba Rasit',
      'repeatTransaction': 'Maimaita Ma\'amala',
      'saveBeneficiary': 'Ajiye Mai karɓa',
      'savedBeneficiaries': 'Masu karɓa da aka ajiye',
      
      // NEW RECEIPT SCREEN SPECIFIC TRANSLATIONS (HAUSA)
      'type': 'Nau\'i',
      'network': 'Hanyar sadarwa',
      'bank': 'Banki',
      'date': 'Kwanan wata',
      'time': 'Lokaci',
      'secureTransaction': 'Ma\'amala mai tsaro da ɓoyewa',
      'cbnLicensed': 'CBN ta ba da lasisi kuma tana lura',
      'receiptShared': 'An raba rasitin cikin nasara',
      'receiptDownloaded': 'An sauke rasitin cikin nasara',
      'backToHome': 'Koma Gida',
      
      // Bill Payment Specific
      'selectProvider': 'Zaɓi Mai bayarwa',
      'selectPlan': 'Zaɓi Tsari',
      'meterNumber': 'Lambar Mita',
      'customerNumber': 'Lambar Abokin ciniki',
      'smartCardNumber': 'Lambar Katin Wayo',
      'institution': 'Cibiya',
      'route': 'Hanya',
      'destination': 'Wurin zuwa',
      'departure': 'Wurin tashi',
      'returnDate': 'Ranar komawa',
      'passengers': 'Fasinjoji',
      'seatNumber': 'Lambar Kujera',
      
      // Settings
      'notifications': 'Sanarwa',
      'security': 'Tsaro',
      'privacy': 'Sirri',
      'helpSupport': 'Taimako & Tallafi',
      'aboutApp': 'Game da App',
      'logout': 'Fita',
      'changeLanguage': 'Canja Harshe',
      'darkMode': 'Yanayin Duhu',
      'pushNotifications': 'Sanarwar Turawa',
      'emailNotifications': 'Sanarwar Imel',
      'smsNotifications': 'Sanarwar SMS',
      'changePin': 'Canja PIN',
      'changeBiometric': 'Canja Biometric',
      'twoFactorAuth': 'Tabbatar da Kashi Biyu',
      'deleteAccount': 'Share Asusun',
      
      // Error Messages
      'errorOccurred': 'Kuskure ya faru',
      'networkError': 'Kuskuren hanyar sadarwa. Ka sake gwadawa.',
      'invalidPin': 'PIN mara inganci. Ka sake gwadawa.',
      'insufficientFunds': 'Kuɗi ba su isa ba',
      'transactionFailed': 'Ma\'amalar ta kasa',
      'serviceUnavailable': 'Sabis ba ya samuwa a yanzu',
      'invalidAmount': 'Adadin mara inganci',
      'invalidPhoneNumber': 'Lambar waya mara inganci',
      'invalidAccountNumber': 'Lambar asusun mara inganci',
      
      // Success Messages
      'transactionSuccessful': 'Ma\'amalar ta yi nasara',
      'paymentCompleted': 'An kammala biyan kuɗi',
      'transferSuccessful': 'Canja wurin ya yi nasara',
      'topupSuccessful': 'Cika ya yi nasara',
      'billPaidSuccessfully': 'An biya bill cikin nasara',

      // ==================== NEW TRANSFER SCREEN KEYS (HAUSA) ====================
      // Transfer Tab Labels
      'recent': 'Kwanakin baya',
      'recentRecipients': 'Masu karɓa na kwanakin baya',
      
      // Wallet Transfer Options
      'scanQRCode': 'Duba Lambar QR',
      'scanToTransfer': 'Duba lambar QR don canja wurin',
      'phoneTransfer': 'Canja ta Waya',
      'transferUsingPhone': 'Canja ta amfani da lambar waya',
      'contacts': 'Lambobin',
      'transferToContacts': 'Canja zuwa lambobin ku',
      
      // Form Labels and Placeholders
      'optional': 'Ba lallai ba',
      'enterDescription': 'Shigar da bayanin (ba lallai ba)',
      
      // Validation Messages
      'accountNumberRequired': 'Ana buƙatar lambar asusun',
      'amountRequired': 'Ana buƙatar adadin',
      'minimumAmount100': 'Mafi ƙarancin adadin shine ₦100',
      'selectBankFirst': 'Da fatan za a zaɓi banki da farko',
      'validateAccountFirst': 'Da fatan za a tabbatar da lambar asusun da farko',
      'selectTransferMethod': 'Da fatan za a zaɓi hanyar canja wurin',
      
      // Recent Recipients
      'lastUsed': 'An yi amfani da shi karshe',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters for common translations
  String get goodMorning => translate('goodMorning');
  String get availableBalance => translate('availableBalance');
  String get account => translate('account');
  String get sendMoney => translate('sendMoney');
  String get sendMoneyDesc => translate('sendMoneyDesc');
  String get addMoney => translate('addMoney');
  String get addMoneyDesc => translate('addMoneyDesc');
  String get quickActions => translate('quickActions');
  String get recentActivity => translate('recentActivity');
  String get viewAll => translate('viewAll');
  String get airtime => translate('airtime');
  String get airtimeDesc => translate('airtimeDesc');
  String get data => translate('data');
  String get dataDesc => translate('dataDesc');
  String get electricity => translate('electricity');
  String get electricityDesc => translate('electricityDesc');
  String get loans => translate('loans');
  String get loansDesc => translate('loansDesc');
  String get cableTV => translate('cableTV');
  String get cableTVDesc => translate('cableTVDesc');
  String get moreServices => translate('moreServices');
  String get moreServicesDesc => translate('moreServicesDesc');
  String get upgradeToUnlock => translate('upgradeToUnlock');
  String get home => translate('home');
  String get transactions => translate('transactions');
  String get cards => translate('cards');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get underbankingAccount => translate('underbankingAccount');
  String get cooperativeName => translate('cooperativeName');
  String get linkedToCooperative => translate('linkedToCooperative');
  String get dailyLimit => translate('dailyLimit');
  String get upgradeYourAccount => translate('upgradeYourAccount');
  String get unlockMoreFeatures => translate('unlockMoreFeatures');
  String get switchToHausa => translate('switchToHausa');
  String get changeLanguageOneTap => translate('changeLanguageOneTap');
  
  // Convenience getters for receipt screen
  String get receipt => translate('receipt');
  String get amount => translate('amount');
  String get recipient => translate('recipient');
  String get accountNumber => translate('accountNumber');
  String get reference => translate('reference');
  String get fee => translate('fee');
  String get description => translate('description');

  // NEW CONVENIENCE GETTERS FOR TRANSFER SCREEN
  String get transfer => translate('transfer');
  String get bankTransfer => translate('bankTransfer');
  String get walletTransfer => translate('walletTransfer');
  String get recent => translate('recent');
  String get selectBank => translate('selectBank');
  String get recentRecipients => translate('recentRecipients');
  String get scanQRCode => translate('scanQRCode');
  String get phoneTransfer => translate('phoneTransfer');
  String get contacts => translate('contacts');
  String get optional => translate('optional');
  String get lastUsed => translate('lastUsed');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ha'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Add supportedLocales static getter to AppLocalizations
extension AppLocalizationsExtension on AppLocalizations {
  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('ha', ''), // Hausa
  ];
}