import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.g.dart';
import 'app_localizations_ha.g.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.g.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ha')
  ];

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountCreatedAndVerified.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully created and verified'**
  String get accountCreatedAndVerified;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @accountDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Account details copied'**
  String get accountDetailsCopied;

  /// No description provided for @accountLimits.
  ///
  /// In en, this message translates to:
  /// **'Account Limits'**
  String get accountLimits;

  /// No description provided for @accountLinked.
  ///
  /// In en, this message translates to:
  /// **'Account Linked!'**
  String get accountLinked;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @accountNoPrefix.
  ///
  /// In en, this message translates to:
  /// **'Account No. {number}'**
  String accountNoPrefix(String number);

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @accountNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Account number copied'**
  String get accountNumberCopied;

  /// No description provided for @accountNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Account number is required'**
  String get accountNumberRequired;

  /// No description provided for @accountTiers.
  ///
  /// In en, this message translates to:
  /// **'Account Tiers'**
  String get accountTiers;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get addMoney;

  /// No description provided for @addMoneyDesc.
  ///
  /// In en, this message translates to:
  /// **'Top up wallet'**
  String get addMoneyDesc;

  /// No description provided for @addMoneyToWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Money to Wallet'**
  String get addMoneyToWallet;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy'**
  String get agreeToTerms;

  /// No description provided for @aidAndDonations.
  ///
  /// In en, this message translates to:
  /// **'Aid & donations'**
  String get aidAndDonations;

  /// No description provided for @airtime.
  ///
  /// In en, this message translates to:
  /// **'Airtime'**
  String get airtime;

  /// No description provided for @airtimeAndDataBundles.
  ///
  /// In en, this message translates to:
  /// **'Airtime & data bundles'**
  String get airtimeAndDataBundles;

  /// No description provided for @airtimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Top up phone'**
  String get airtimeDesc;

  /// No description provided for @airtimePurchase.
  ///
  /// In en, this message translates to:
  /// **'Airtime Purchase'**
  String get airtimePurchase;

  /// No description provided for @airtimeToCash.
  ///
  /// In en, this message translates to:
  /// **'Airtime to Cash'**
  String get airtimeToCash;

  /// No description provided for @airtimeToCashDesc.
  ///
  /// In en, this message translates to:
  /// **'Convert airtime'**
  String get airtimeToCashDesc;

  /// No description provided for @allNetworks.
  ///
  /// In en, this message translates to:
  /// **'All networks'**
  String get allNetworks;

  /// No description provided for @alreadyBankWithRima.
  ///
  /// In en, this message translates to:
  /// **'Already bank with Rima?'**
  String get alreadyBankWithRima;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @applyForLoan.
  ///
  /// In en, this message translates to:
  /// **'Apply for Loan'**
  String get applyForLoan;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// No description provided for @authenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get authenticating;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccount;

  /// No description provided for @bankDeposit.
  ///
  /// In en, this message translates to:
  /// **'Bank Deposit'**
  String get bankDeposit;

  /// No description provided for @bankDepositLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank deposit'**
  String get bankDepositLabel;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @beneficiarySaved.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary saved successfully'**
  String get beneficiarySaved;

  /// No description provided for @betting.
  ///
  /// In en, this message translates to:
  /// **'Betting'**
  String get betting;

  /// No description provided for @bettingDesc.
  ///
  /// In en, this message translates to:
  /// **'Sports & lottery'**
  String get bettingDesc;

  /// No description provided for @billPaidSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Bill Paid Successfully'**
  String get billPaidSuccessfully;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometrics;

  /// No description provided for @bookFlights.
  ///
  /// In en, this message translates to:
  /// **'Book flights'**
  String get bookFlights;

  /// No description provided for @busTickets.
  ///
  /// In en, this message translates to:
  /// **'Bus tickets'**
  String get busTickets;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @bvnVerification.
  ///
  /// In en, this message translates to:
  /// **'BVN Verification'**
  String get bvnVerification;

  /// No description provided for @cableProviders.
  ///
  /// In en, this message translates to:
  /// **'DSTV, GOtv, etc.'**
  String get cableProviders;

  /// No description provided for @cableTV.
  ///
  /// In en, this message translates to:
  /// **'Cable TV'**
  String get cableTV;

  /// No description provided for @cableTVDesc.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get cableTVDesc;

  /// No description provided for @callOrChatWithUs.
  ///
  /// In en, this message translates to:
  /// **'Call or chat with us'**
  String get callOrChatWithUs;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @canNowUseDevice.
  ///
  /// In en, this message translates to:
  /// **'You can now use this device to access your account.'**
  String get canNowUseDevice;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cardPayment.
  ///
  /// In en, this message translates to:
  /// **'Card payment'**
  String get cardPayment;

  /// No description provided for @cardSchemes.
  ///
  /// In en, this message translates to:
  /// **'Visa, Mastercard, Verve'**
  String get cardSchemes;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cards;

  /// No description provided for @cardsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Cards coming soon'**
  String get cardsComingSoon;

  /// No description provided for @cbnLicensed.
  ///
  /// In en, this message translates to:
  /// **'CBN licensed and regulated'**
  String get cbnLicensed;

  /// No description provided for @changeBiometric.
  ///
  /// In en, this message translates to:
  /// **'Change Biometric'**
  String get changeBiometric;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @changeLanguageOneTap.
  ///
  /// In en, this message translates to:
  /// **'Change your app language with one tap'**
  String get changeLanguageOneTap;

  /// No description provided for @changeLoginPin.
  ///
  /// In en, this message translates to:
  /// **'Change Login PIN'**
  String get changeLoginPin;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @changeTransactionPin.
  ///
  /// In en, this message translates to:
  /// **'Change Transaction PIN'**
  String get changeTransactionPin;

  /// No description provided for @chooseAccountType.
  ///
  /// In en, this message translates to:
  /// **'Choose the account type that fits your needs'**
  String get chooseAccountType;

  /// No description provided for @chooseNetwork.
  ///
  /// In en, this message translates to:
  /// **'Choose Network'**
  String get chooseNetwork;

  /// No description provided for @choosePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose Payment Method'**
  String get choosePaymentMethod;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @comingSoonFeature.
  ///
  /// In en, this message translates to:
  /// **'{label} is coming soon!'**
  String comingSoonFeature(String label);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @confirmTransaction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transaction'**
  String get confirmTransaction;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @continueArrow.
  ///
  /// In en, this message translates to:
  /// **'Continue →'**
  String get continueArrow;

  /// No description provided for @continueToAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue to Account'**
  String get continueToAccount;

  /// No description provided for @cooperativeName.
  ///
  /// In en, this message translates to:
  /// **'Nigerian Unity Cooperative'**
  String get cooperativeName;

  /// No description provided for @copyAllDetails.
  ///
  /// In en, this message translates to:
  /// **'Copy All Details'**
  String get copyAllDetails;

  /// No description provided for @corporateAccount.
  ///
  /// In en, this message translates to:
  /// **'Corporate Account'**
  String get corporateAccount;

  /// No description provided for @corporateAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'For businesses and organizations'**
  String get corporateAccountDesc;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create Password'**
  String get createPassword;

  /// No description provided for @createPasswordToSecure.
  ///
  /// In en, this message translates to:
  /// **'Create a password to secure your account'**
  String get createPasswordToSecure;

  /// No description provided for @createPin.
  ///
  /// In en, this message translates to:
  /// **'Create PIN'**
  String get createPin;

  /// No description provided for @createTransactionPin.
  ///
  /// In en, this message translates to:
  /// **'Create Transaction PIN'**
  String get createTransactionPin;

  /// No description provided for @currentTier.
  ///
  /// In en, this message translates to:
  /// **'Current Tier'**
  String get currentTier;

  /// No description provided for @customerCare.
  ///
  /// In en, this message translates to:
  /// **'Customer Care'**
  String get customerCare;

  /// No description provided for @customerNumber.
  ///
  /// In en, this message translates to:
  /// **'Customer Number'**
  String get customerNumber;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @dailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily limit: {amount}'**
  String dailyLimit(String amount);

  /// No description provided for @dailyTransactionLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily Transaction Limit'**
  String get dailyTransactionLimit;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @dataBundle.
  ///
  /// In en, this message translates to:
  /// **'Data Bundle'**
  String get dataBundle;

  /// No description provided for @dataBundles.
  ///
  /// In en, this message translates to:
  /// **'Data bundles'**
  String get dataBundles;

  /// No description provided for @dataDesc.
  ///
  /// In en, this message translates to:
  /// **'Buy plans'**
  String get dataDesc;

  /// No description provided for @dataPurchase.
  ///
  /// In en, this message translates to:
  /// **'Data Purchase'**
  String get dataPurchase;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateAndTime;

  /// No description provided for @debitCard.
  ///
  /// In en, this message translates to:
  /// **'Debit Card'**
  String get debitCard;

  /// No description provided for @debitCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Debit / Credit Card'**
  String get debitCreditCard;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @departure.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get departure;

  /// No description provided for @depositCashAtBranch.
  ///
  /// In en, this message translates to:
  /// **'Deposit cash at any bank branch'**
  String get depositCashAtBranch;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @deviceLinkedPleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Device linked successfully. Please log in.'**
  String get deviceLinkedPleaseLogIn;

  /// No description provided for @deviceLinkedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Device Linked Successfully'**
  String get deviceLinkedSuccessfully;

  /// No description provided for @dialCodeFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Dial a code from your phone'**
  String get dialCodeFromPhone;

  /// No description provided for @discoPayments.
  ///
  /// In en, this message translates to:
  /// **'DISCO payments'**
  String get discoPayments;

  /// No description provided for @dispute.
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get dispute;

  /// No description provided for @disputeSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Dispute submitted. Our team will review it shortly.'**
  String get disputeSubmitted;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @downloadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download Receipt'**
  String get downloadReceipt;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @educationDesc.
  ///
  /// In en, this message translates to:
  /// **'School fees & more'**
  String get educationDesc;

  /// No description provided for @electricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get electricity;

  /// No description provided for @electricityDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay bills'**
  String get electricityDesc;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get enterAmount;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description (optional)'**
  String get enterDescription;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter Email'**
  String get enterEmail;

  /// No description provided for @enterLinkedPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter the phone number linked to your RimaPay account.'**
  String get enterLinkedPhone;

  /// No description provided for @enterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get enterNickname;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get enterPassword;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @enterValidTenDigitPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit phone number'**
  String get enterValidTenDigitPhone;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @eventTickets.
  ///
  /// In en, this message translates to:
  /// **'Event Tickets'**
  String get eventTickets;

  /// No description provided for @eventTicketsDesc.
  ///
  /// In en, this message translates to:
  /// **'Movies & concerts'**
  String get eventTicketsDesc;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @examBodies.
  ///
  /// In en, this message translates to:
  /// **'WAEC, JAMB, NECO'**
  String get examBodies;

  /// No description provided for @faceVerification.
  ///
  /// In en, this message translates to:
  /// **'Face Verification'**
  String get faceVerification;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @faqsAndSupport.
  ///
  /// In en, this message translates to:
  /// **'FAQs and customer support'**
  String get faqsAndSupport;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @feeApplies.
  ///
  /// In en, this message translates to:
  /// **'Fee applies'**
  String get feeApplies;

  /// No description provided for @firstBankCustodian.
  ///
  /// In en, this message translates to:
  /// **'First Bank Custodian'**
  String get firstBankCustodian;

  /// No description provided for @flights.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get flights;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @forgotPinResetHere.
  ///
  /// In en, this message translates to:
  /// **'Forgot your PIN? Reset it here'**
  String get forgotPinResetHere;

  /// No description provided for @freeInstant.
  ///
  /// In en, this message translates to:
  /// **'Free · Instant'**
  String get freeInstant;

  /// No description provided for @freeNoInternet.
  ///
  /// In en, this message translates to:
  /// **'Free · No internet'**
  String get freeNoInternet;

  /// No description provided for @freeOneToThreeHours.
  ///
  /// In en, this message translates to:
  /// **'Free · 1–3 hours'**
  String get freeOneToThreeHours;

  /// No description provided for @frequentBeneficiaries.
  ///
  /// In en, this message translates to:
  /// **'Frequent Beneficiaries'**
  String get frequentBeneficiaries;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fundWallet.
  ///
  /// In en, this message translates to:
  /// **'Fund Wallet'**
  String get fundWallet;

  /// No description provided for @fundYourWallet.
  ///
  /// In en, this message translates to:
  /// **'Fund your RimaPay wallet'**
  String get fundYourWallet;

  /// No description provided for @getAlertsForTransactions.
  ///
  /// In en, this message translates to:
  /// **'Get alerts for transactions'**
  String get getAlertsForTransactions;

  /// No description provided for @getLoansToday.
  ///
  /// In en, this message translates to:
  /// **'Get Loans Today'**
  String get getLoansToday;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon ✨'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening ✨'**
  String get goodEvening;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning ✨'**
  String get goodMorning;

  /// No description provided for @govPayments.
  ///
  /// In en, this message translates to:
  /// **'Gov. Payments'**
  String get govPayments;

  /// No description provided for @government.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get government;

  /// No description provided for @governmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Tax & permits'**
  String get governmentDesc;

  /// No description provided for @govtPayments.
  ///
  /// In en, this message translates to:
  /// **'Govt. payments'**
  String get govtPayments;

  /// No description provided for @grants.
  ///
  /// In en, this message translates to:
  /// **'Grants'**
  String get grants;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get greetingEvening;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get greetingMorning;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @holdOnAMoment.
  ///
  /// In en, this message translates to:
  /// **'Hold on a moment ...'**
  String get holdOnAMoment;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @idVerification.
  ///
  /// In en, this message translates to:
  /// **'ID Verification'**
  String get idVerification;

  /// No description provided for @instantTransfersToAnyBank.
  ///
  /// In en, this message translates to:
  /// **'Instant transfers to any bank'**
  String get instantTransfersToAnyBank;

  /// No description provided for @institution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institution;

  /// No description provided for @insufficientBalanceIs.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance. Your wallet balance is {balance}.'**
  String insufficientBalanceIs(String balance);

  /// No description provided for @insufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds'**
  String get insufficientFunds;

  /// No description provided for @internet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get internet;

  /// No description provided for @internetProviders.
  ///
  /// In en, this message translates to:
  /// **'Spectranet, Smile'**
  String get internetProviders;

  /// No description provided for @invalidAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid account number'**
  String get invalidAccountNumber;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @invalidPin.
  ///
  /// In en, this message translates to:
  /// **'Invalid PIN. Please try again.'**
  String get invalidPin;

  /// No description provided for @kycVerification.
  ///
  /// In en, this message translates to:
  /// **'KYC Verification'**
  String get kycVerification;

  /// No description provided for @labelCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String labelCopied(String label);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageChanged;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsed;

  /// No description provided for @linkAccount.
  ///
  /// In en, this message translates to:
  /// **'Link Account'**
  String get linkAccount;

  /// No description provided for @linkExistingAccount.
  ///
  /// In en, this message translates to:
  /// **'Link existing account'**
  String get linkExistingAccount;

  /// No description provided for @linkExistingAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Link Existing Account'**
  String get linkExistingAccountTitle;

  /// No description provided for @linkThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Link this device'**
  String get linkThisDevice;

  /// No description provided for @linkYourDevice.
  ///
  /// In en, this message translates to:
  /// **'Link Your Device'**
  String get linkYourDevice;

  /// No description provided for @linkedToCooperative.
  ///
  /// In en, this message translates to:
  /// **'Linked to: Nigerian Unity Cooperative'**
  String get linkedToCooperative;

  /// No description provided for @loanComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Loan application coming soon!'**
  String get loanComingSoon;

  /// No description provided for @loanPitch.
  ///
  /// In en, this message translates to:
  /// **'Get up to {amount} at low interest. Quick approval.'**
  String loanPitch(String amount);

  /// No description provided for @loans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loans;

  /// No description provided for @loansDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick approval'**
  String get loansDesc;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @markAsFavorite.
  ///
  /// In en, this message translates to:
  /// **'Mark as Favorite'**
  String get markAsFavorite;

  /// No description provided for @meterNumber.
  ///
  /// In en, this message translates to:
  /// **'Meter Number'**
  String get meterNumber;

  /// No description provided for @methodComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{method} coming soon'**
  String methodComingSoon(String method);

  /// No description provided for @minEightCharacters.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get minEightCharacters;

  /// No description provided for @minMaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Min: {min}, Max: {max}'**
  String minMaxAmount(String min, String max);

  /// No description provided for @minimumAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum amount is {amount}'**
  String minimumAmount(String amount);

  /// No description provided for @mobileTopUp.
  ///
  /// In en, this message translates to:
  /// **'Mobile Top-Up'**
  String get mobileTopUp;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @monthlyTransactionLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly Transaction Limit'**
  String get monthlyTransactionLimit;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @moreInfo.
  ///
  /// In en, this message translates to:
  /// **'More Info'**
  String get moreInfo;

  /// No description provided for @moreServices.
  ///
  /// In en, this message translates to:
  /// **'More Services'**
  String get moreServices;

  /// No description provided for @moreServicesDesc.
  ///
  /// In en, this message translates to:
  /// **'All bill services'**
  String get moreServicesDesc;

  /// No description provided for @myCard.
  ///
  /// In en, this message translates to:
  /// **'My Card'**
  String get myCard;

  /// No description provided for @myNumber.
  ///
  /// In en, this message translates to:
  /// **'My Number'**
  String get myNumber;

  /// No description provided for @needALoan.
  ///
  /// In en, this message translates to:
  /// **'Need a Loan?'**
  String get needALoan;

  /// No description provided for @needTransactionPinToSend.
  ///
  /// In en, this message translates to:
  /// **'You need to create a transaction PIN before you can send money.'**
  String get needTransactionPinToSend;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get networkError;

  /// No description provided for @newPhone.
  ///
  /// In en, this message translates to:
  /// **'New phone?'**
  String get newPhone;

  /// No description provided for @newToRimaPay.
  ///
  /// In en, this message translates to:
  /// **'New to RimaPay?'**
  String get newToRimaPay;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @nicknameOptional.
  ///
  /// In en, this message translates to:
  /// **'Nickname (Optional)'**
  String get nicknameOptional;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @passengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get passengers;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Min 8 chars with uppercase, lowercase & number'**
  String get passwordRequirements;

  /// No description provided for @payBillsManageServices.
  ///
  /// In en, this message translates to:
  /// **'Pay bills & manage services'**
  String get payBillsManageServices;

  /// No description provided for @paymentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment Completed'**
  String get paymentCompleted;

  /// No description provided for @paymentSuccessfulCelebrate.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful! 🎉'**
  String get paymentSuccessfulCelebrate;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @pension.
  ///
  /// In en, this message translates to:
  /// **'Pension'**
  String get pension;

  /// No description provided for @pensionDesc.
  ///
  /// In en, this message translates to:
  /// **'Voluntary contributions'**
  String get pensionDesc;

  /// No description provided for @personalAccount.
  ///
  /// In en, this message translates to:
  /// **'Personal Account'**
  String get personalAccount;

  /// No description provided for @personalAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'For individuals — send, receive & pay bills'**
  String get personalAccountDesc;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneTransfer.
  ///
  /// In en, this message translates to:
  /// **'Phone Transfer'**
  String get phoneTransfer;

  /// No description provided for @pinFourToEightDigits.
  ///
  /// In en, this message translates to:
  /// **'PIN (4-8 digits)'**
  String get pinFourToEightDigits;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @planBlurb.
  ///
  /// In en, this message translates to:
  /// **'Get {data} for {price}. Valid for {validity}'**
  String planBlurb(String data, String price, String validity);

  /// No description provided for @pleaseHoldStill.
  ///
  /// In en, this message translates to:
  /// **'Please hold still'**
  String get pleaseHoldStill;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @proceedArrow.
  ///
  /// In en, this message translates to:
  /// **'Proceed →'**
  String get proceedArrow;

  /// No description provided for @processedSecurelyBy.
  ///
  /// In en, this message translates to:
  /// **'Transaction processed securely by RimaPay'**
  String get processedSecurelyBy;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @quickAccessFutureTransfers.
  ///
  /// In en, this message translates to:
  /// **'Quick access for future transfers'**
  String get quickAccessFutureTransfers;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @quickApprovalProcess.
  ///
  /// In en, this message translates to:
  /// **'Quick approval process'**
  String get quickApprovalProcess;

  /// No description provided for @quickSelectAmount.
  ///
  /// In en, this message translates to:
  /// **'Quick Select Amount'**
  String get quickSelectAmount;

  /// No description provided for @quickServices.
  ///
  /// In en, this message translates to:
  /// **'Quick Services'**
  String get quickServices;

  /// No description provided for @reEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reEnterPassword;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @receiptDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Receipt downloaded successfully'**
  String get receiptDownloaded;

  /// No description provided for @receiptShared.
  ///
  /// In en, this message translates to:
  /// **'Receipt shared successfully'**
  String get receiptShared;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @recentRecipients.
  ///
  /// In en, this message translates to:
  /// **'Recent Recipients'**
  String get recentRecipients;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @registerDeviceToAccount.
  ///
  /// In en, this message translates to:
  /// **'Register this device to your account'**
  String get registerDeviceToAccount;

  /// No description provided for @religiousPayment.
  ///
  /// In en, this message translates to:
  /// **'Religious payment'**
  String get religiousPayment;

  /// No description provided for @remita.
  ///
  /// In en, this message translates to:
  /// **'Remita'**
  String get remita;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatTransaction.
  ///
  /// In en, this message translates to:
  /// **'Repeat Transaction'**
  String get repeatTransaction;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds} s'**
  String resendCodeIn(String seconds);

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resetTransactionPin.
  ///
  /// In en, this message translates to:
  /// **'Reset Transaction PIN'**
  String get resetTransactionPin;

  /// No description provided for @returnDate.
  ///
  /// In en, this message translates to:
  /// **'Return Date'**
  String get returnDate;

  /// No description provided for @rimapayAccountOrPhone.
  ///
  /// In en, this message translates to:
  /// **'RimaPay Account / Phone'**
  String get rimapayAccountOrPhone;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Save Beneficiary'**
  String get saveBeneficiary;

  /// No description provided for @savedBeneficiaries.
  ///
  /// In en, this message translates to:
  /// **'Saved Beneficiaries'**
  String get savedBeneficiaries;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @scanToTransfer.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code to transfer'**
  String get scanToTransfer;

  /// No description provided for @searchBanks.
  ///
  /// In en, this message translates to:
  /// **'Search banks…'**
  String get searchBanks;

  /// No description provided for @searchPlans.
  ///
  /// In en, this message translates to:
  /// **'Search plans...'**
  String get searchPlans;

  /// No description provided for @searchServices.
  ///
  /// In en, this message translates to:
  /// **'Search services...'**
  String get searchServices;

  /// No description provided for @seatNumber.
  ///
  /// In en, this message translates to:
  /// **'Seat Number'**
  String get seatNumber;

  /// No description provided for @secureTransaction.
  ///
  /// In en, this message translates to:
  /// **'Secure & encrypted transaction'**
  String get secureTransaction;

  /// No description provided for @secureWithFourDigitPin.
  ///
  /// In en, this message translates to:
  /// **'Secure your account with a 4-digit PIN'**
  String get secureWithFourDigitPin;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get selectAccount;

  /// No description provided for @selectBank.
  ///
  /// In en, this message translates to:
  /// **'Select Bank'**
  String get selectBank;

  /// No description provided for @selectBankFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a bank first'**
  String get selectBankFirst;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectNetworkFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a network first'**
  String get selectNetworkFirst;

  /// No description provided for @selectPlan.
  ///
  /// In en, this message translates to:
  /// **'Select Plan'**
  String get selectPlan;

  /// No description provided for @selectProvider.
  ///
  /// In en, this message translates to:
  /// **'Select Provider'**
  String get selectProvider;

  /// No description provided for @selectTransferMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a transfer method'**
  String get selectTransferMethod;

  /// No description provided for @sendMoney.
  ///
  /// In en, this message translates to:
  /// **'Send Money'**
  String get sendMoney;

  /// No description provided for @sendMoneyDesc.
  ///
  /// In en, this message translates to:
  /// **'To friends & family'**
  String get sendMoneyDesc;

  /// No description provided for @sendMoneyFaster.
  ///
  /// In en, this message translates to:
  /// **'Send Money Faster'**
  String get sendMoneyFaster;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// No description provided for @sentCodeToPhone.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to your phone'**
  String get sentCodeToPhone;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @serviceRequiresTier.
  ///
  /// In en, this message translates to:
  /// **'This service requires {tier} tier or higher.'**
  String serviceRequiresTier(String tier);

  /// No description provided for @serviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service temporarily unavailable'**
  String get serviceUnavailable;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share Code'**
  String get shareCode;

  /// No description provided for @shareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share Receipt'**
  String get shareReceipt;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your RimaPay account'**
  String get signInToYourAccount;

  /// No description provided for @signOutOfAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutOfAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @slide1Description.
  ///
  /// In en, this message translates to:
  /// **'Built by Nigerians, for Nigerians. Experience financial freedom rooted in our rich culture and unwavering spirit of excellence.'**
  String get slide1Description;

  /// No description provided for @slide1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Nigerian Heritage'**
  String get slide1Subtitle;

  /// No description provided for @slide1Title.
  ///
  /// In en, this message translates to:
  /// **'We are Indigenous,\nOpen for Us'**
  String get slide1Title;

  /// No description provided for @slide2Description.
  ///
  /// In en, this message translates to:
  /// **'From corporate professionals to market entrepreneurs - financial freedom for all Nigerians, everywhere.'**
  String get slide2Description;

  /// No description provided for @slide2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Every Nigerian'**
  String get slide2Subtitle;

  /// No description provided for @slide2Title.
  ///
  /// In en, this message translates to:
  /// **'RimaPay is\nfor Everyone'**
  String get slide2Title;

  /// No description provided for @slide3Description.
  ///
  /// In en, this message translates to:
  /// **'Tap, pay, done. Experience the future of payments with instant, secure, and intuitive transactions.'**
  String get slide3Description;

  /// No description provided for @slide3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Effortless Experience'**
  String get slide3Subtitle;

  /// No description provided for @slide3Title.
  ///
  /// In en, this message translates to:
  /// **'Payments Made\nSeamless'**
  String get slide3Title;

  /// No description provided for @smartCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Smart Card Number'**
  String get smartCardNumber;

  /// No description provided for @smsNotifications.
  ///
  /// In en, this message translates to:
  /// **'SMS Notifications'**
  String get smsNotifications;

  /// No description provided for @startSending.
  ///
  /// In en, this message translates to:
  /// **'Start Sending'**
  String get startSending;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @successful.
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get successful;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportHours.
  ///
  /// In en, this message translates to:
  /// **'Mon – Fri: 8am – 8pm\nSat: 9am – 5pm'**
  String get supportHours;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch to Hausa Language'**
  String get switchLanguage;

  /// No description provided for @switchLanguageAction.
  ///
  /// In en, this message translates to:
  /// **'Switch to HA'**
  String get switchLanguageAction;

  /// No description provided for @switchToDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark theme'**
  String get switchToDarkTheme;

  /// No description provided for @taxesAndFees.
  ///
  /// In en, this message translates to:
  /// **'Taxes & fees'**
  String get taxesAndFees;

  /// No description provided for @ticketsAndConcerts.
  ///
  /// In en, this message translates to:
  /// **'Tickets & concerts'**
  String get ticketsAndConcerts;

  /// No description provided for @tierBenefits.
  ///
  /// In en, this message translates to:
  /// **'Tier Benefits'**
  String get tierBenefits;

  /// No description provided for @tierUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Tier Upgrade'**
  String get tierUpgrade;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @toOtherBanks.
  ///
  /// In en, this message translates to:
  /// **'To Other Banks'**
  String get toOtherBanks;

  /// No description provided for @toOtherBanksDesc.
  ///
  /// In en, this message translates to:
  /// **'Send to any Nigerian bank account'**
  String get toOtherBanksDesc;

  /// No description provided for @toRimaPay.
  ///
  /// In en, this message translates to:
  /// **'To RimaPay'**
  String get toRimaPay;

  /// No description provided for @toRimaPayDesc.
  ///
  /// In en, this message translates to:
  /// **'Send to any RimaPay account instantly'**
  String get toRimaPayDesc;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @topupSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Top-up Successful'**
  String get topupSuccessful;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// No description provided for @transactionAmount.
  ///
  /// In en, this message translates to:
  /// **'Transaction Amount'**
  String get transactionAmount;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @transactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction failed'**
  String get transactionFailed;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @transactionPin.
  ///
  /// In en, this message translates to:
  /// **'Transaction PIN'**
  String get transactionPin;

  /// No description provided for @transactionProcessedOk.
  ///
  /// In en, this message translates to:
  /// **'Your {type} has been processed successfully'**
  String transactionProcessedOk(String type);

  /// No description provided for @transactionReceipt.
  ///
  /// In en, this message translates to:
  /// **'Transaction Receipt'**
  String get transactionReceipt;

  /// No description provided for @transactionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Transaction Successful'**
  String get transactionSuccessful;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get transactions;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transferFee.
  ///
  /// In en, this message translates to:
  /// **'Transfer Fee'**
  String get transferFee;

  /// No description provided for @transferFromAnyBank.
  ///
  /// In en, this message translates to:
  /// **'Transfer from any bank account'**
  String get transferFromAnyBank;

  /// No description provided for @transferMoney.
  ///
  /// In en, this message translates to:
  /// **'Transfer Money'**
  String get transferMoney;

  /// No description provided for @transferSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Transfer Successful'**
  String get transferSuccessful;

  /// No description provided for @transferSuccessfulCelebrate.
  ///
  /// In en, this message translates to:
  /// **'Transfer Successful! 🎉'**
  String get transferSuccessfulCelebrate;

  /// No description provided for @transferToContacts.
  ///
  /// In en, this message translates to:
  /// **'Transfer to your contacts'**
  String get transferToContacts;

  /// No description provided for @transferToFundWallet.
  ///
  /// In en, this message translates to:
  /// **'Transfer to fund your wallet'**
  String get transferToFundWallet;

  /// No description provided for @transferUsingPhone.
  ///
  /// In en, this message translates to:
  /// **'Transfer using phone number'**
  String get transferUsingPhone;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @transportDesc.
  ///
  /// In en, this message translates to:
  /// **'Bus & flight tickets'**
  String get transportDesc;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @underbanked.
  ///
  /// In en, this message translates to:
  /// **'Underbanked'**
  String get underbanked;

  /// No description provided for @underbankedDesc.
  ///
  /// In en, this message translates to:
  /// **'Financial inclusion — micro-loans & savings groups'**
  String get underbankedDesc;

  /// No description provided for @underbankingAccount.
  ///
  /// In en, this message translates to:
  /// **'Underbanking Account'**
  String get underbankingAccount;

  /// No description provided for @unlockHigherLimitsLong.
  ///
  /// In en, this message translates to:
  /// **'Unlock higher limits, lower fees and more amazing features.'**
  String get unlockHigherLimitsLong;

  /// No description provided for @unlockHigherLimitsShort.
  ///
  /// In en, this message translates to:
  /// **'Unlock higher limits & features'**
  String get unlockHigherLimitsShort;

  /// No description provided for @unlockMoreFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock more features and higher limits'**
  String get unlockMoreFeatures;

  /// No description provided for @updateAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get updateAccountPassword;

  /// No description provided for @updateLoginPin.
  ///
  /// In en, this message translates to:
  /// **'Update your login PIN'**
  String get updateLoginPin;

  /// No description provided for @updateTransactionPin.
  ///
  /// In en, this message translates to:
  /// **'Update your transaction PIN'**
  String get updateTransactionPin;

  /// No description provided for @upgradeAccount.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Account'**
  String get upgradeAccount;

  /// No description provided for @upgradeAccountNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get upgradeAccountNow;

  /// No description provided for @upgradeTier.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Tier'**
  String get upgradeTier;

  /// No description provided for @upgradeToTier2.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Tier 2'**
  String get upgradeToTier2;

  /// No description provided for @upgradeToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Unlock'**
  String get upgradeToUnlock;

  /// No description provided for @upgradeToUnlockService.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock {service}'**
  String upgradeToUnlockService(String service);

  /// No description provided for @upgradeYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Your Account'**
  String get upgradeYourAccount;

  /// No description provided for @useAccountNumberToLink.
  ///
  /// In en, this message translates to:
  /// **'Use your account number to link your existing RimaPay account.'**
  String get useAccountNumberToLink;

  /// No description provided for @useFaceId.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID'**
  String get useFaceId;

  /// No description provided for @useFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use Fingerprint'**
  String get useFingerprint;

  /// No description provided for @useFingerprintOrFaceId.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or Face ID'**
  String get useFingerprintOrFaceId;

  /// No description provided for @ussd.
  ///
  /// In en, this message translates to:
  /// **'USSD'**
  String get ussd;

  /// No description provided for @validForPeriod.
  ///
  /// In en, this message translates to:
  /// **'Valid for {period}'**
  String validForPeriod(String period);

  /// No description provided for @validateAccountFirst.
  ///
  /// In en, this message translates to:
  /// **'Please validate account number first'**
  String get validateAccountFirst;

  /// No description provided for @verifyArrow.
  ///
  /// In en, this message translates to:
  /// **'Verify →'**
  String get verifyArrow;

  /// No description provided for @verifyExistingAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify your existing account to continue'**
  String get verifyExistingAccount;

  /// No description provided for @verifyTransaction.
  ///
  /// In en, this message translates to:
  /// **'Verify Transaction'**
  String get verifyTransaction;

  /// No description provided for @verifyingYourFace.
  ///
  /// In en, this message translates to:
  /// **'Verifying your face…'**
  String get verifyingYourFace;

  /// No description provided for @verifyingYourFacePlain.
  ///
  /// In en, this message translates to:
  /// **'Verifying your face'**
  String get verifyingYourFacePlain;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all →'**
  String get viewAll;

  /// No description provided for @viewTransactionLimits.
  ///
  /// In en, this message translates to:
  /// **'View your transaction limits'**
  String get viewTransactionLimits;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @walletTransfer.
  ///
  /// In en, this message translates to:
  /// **'Wallet Transfer'**
  String get walletTransfer;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @welcomeCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get welcomeCreateAccount;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'made for us\nby us'**
  String get welcomeHeadline;

  /// No description provided for @welcomeLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get welcomeLogIn;

  /// No description provided for @welcomeSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get welcomeSignUp;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Safe, fast and reliable\nfinancial services\nbuilt for you.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeToRimaPay.
  ///
  /// In en, this message translates to:
  /// **'Welcome to RimaPay'**
  String get welcomeToRimaPay;

  /// No description provided for @welcomeToRimaPayCelebrate.
  ///
  /// In en, this message translates to:
  /// **'Welcome to RimaPay! 🎉'**
  String get welcomeToRimaPayCelebrate;

  /// No description provided for @welcomeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeWelcomeBack;

  /// No description provided for @wereHereToHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help you'**
  String get wereHereToHelp;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @whereToSendMoney.
  ///
  /// In en, this message translates to:
  /// **'Where would you like to send money?'**
  String get whereToSendMoney;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @yourDedicatedAccount.
  ///
  /// In en, this message translates to:
  /// **'Your Dedicated Account'**
  String get yourDedicatedAccount;

  /// No description provided for @zakat.
  ///
  /// In en, this message translates to:
  /// **'Zakat'**
  String get zakat;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ha'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'ha':
      return AppL10nHa();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
