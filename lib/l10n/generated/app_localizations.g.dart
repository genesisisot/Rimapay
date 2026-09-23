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

  /// No description provided for @aFeeOfFeeWillBe.
  ///
  /// In en, this message translates to:
  /// **'A fee of {fee} will be deducted from your account.'**
  String aFeeOfFeeWillBe(Object fee);

  /// No description provided for @aPepPoliticallyExposedPersonIs.
  ///
  /// In en, this message translates to:
  /// **'A PEP (Politically Exposed Person) is someone who currently holds or has held an important public position, which gives them influence over public funds or decisions. This includes family members and close associates of such persons.'**
  String get aPepPoliticallyExposedPersonIs;

  /// No description provided for @aPepPoliticallyExposedPersonIs2.
  ///
  /// In en, this message translates to:
  /// **'A PEP (Politically Exposed Person) is someone who currently holds or has held an important public position, which gives them influence over public funds or decisions.'**
  String get aPepPoliticallyExposedPersonIs2;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @aboutRemitaPayments.
  ///
  /// In en, this message translates to:
  /// **'About Remita Payments'**
  String get aboutRemitaPayments;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountAccountnumber.
  ///
  /// In en, this message translates to:
  /// **'Account: {accountNumber}'**
  String accountAccountnumber(Object accountNumber);

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account Created!'**
  String get accountCreated;

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
  String accountNoPrefix(Object number);

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

  /// No description provided for @accountUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Account Under Review'**
  String get accountUnderReview;

  /// No description provided for @accountnumberBank.
  ///
  /// In en, this message translates to:
  /// **'{accountNumber} • {bank}'**
  String accountnumberBank(Object accountNumber, Object bank);

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

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

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @affordableIntercityTrips.
  ///
  /// In en, this message translates to:
  /// **'Affordable intercity trips'**
  String get affordableIntercityTrips;

  /// No description provided for @agencyDescription.
  ///
  /// In en, this message translates to:
  /// **'{agency} · {description}'**
  String agencyDescription(Object agency, Object description);

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

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'All Done!'**
  String get allDone;

  /// No description provided for @allNetworks.
  ///
  /// In en, this message translates to:
  /// **'All networks'**
  String get allNetworks;

  /// No description provided for @allRequirementsCompleted.
  ///
  /// In en, this message translates to:
  /// **'All requirements completed'**
  String get allRequirementsCompleted;

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

  /// No description provided for @amount2.
  ///
  /// In en, this message translates to:
  /// **'₦{amount}'**
  String amount2(Object amount);

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @amountcontrollerAirtime.
  ///
  /// In en, this message translates to:
  /// **'₦{_amountController} airtime'**
  String amountcontrollerAirtime(Object _amountController);

  /// No description provided for @anOtpWillBeSentTo.
  ///
  /// In en, this message translates to:
  /// **'An OTP will be sent to your registered phone number to reset your transaction PIN.'**
  String get anOtpWillBeSentTo;

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

  /// No description provided for @approvePaymentsWithoutTypingYourPin.
  ///
  /// In en, this message translates to:
  /// **'Approve payments without typing your PIN'**
  String get approvePaymentsWithoutTypingYourPin;

  /// No description provided for @approxValueOf85gOfGold.
  ///
  /// In en, this message translates to:
  /// **' (approx. value of 85g of gold). Zakat rate: 2.5%.'**
  String get approxValueOf85gOfGold;

  /// No description provided for @areYouAPoliticallyExposedPerson.
  ///
  /// In en, this message translates to:
  /// **'Are you a Politically Exposed Person?'**
  String get areYouAPoliticallyExposedPerson;

  /// No description provided for @areYouAPoliticallyExposedPerson2.
  ///
  /// In en, this message translates to:
  /// **'Are you a Politically Exposed Person or a family member/close associate of a PEP?'**
  String get areYouAPoliticallyExposedPerson2;

  /// No description provided for @areYouSureYouWantTo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your RimaPay account?'**
  String get areYouSureYouWantTo;

  /// No description provided for @areYouSureYouWantTo2.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from your RimaPay account?'**
  String get areYouSureYouWantTo2;

  /// No description provided for @authenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get authenticating;

  /// No description provided for @authorizedAndNregulatedBy.
  ///
  /// In en, this message translates to:
  /// **'AUTHORIZED AND\nREGULATED BY'**
  String get authorizedAndNregulatedBy;

  /// No description provided for @autoRollover.
  ///
  /// In en, this message translates to:
  /// **'Auto-Rollover'**
  String get autoRollover;

  /// No description provided for @automaticallyRenewAtMaturity.
  ///
  /// In en, this message translates to:
  /// **'Automatically renew at maturity'**
  String get automaticallyRenewAtMaturity;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @availableEvents.
  ///
  /// In en, this message translates to:
  /// **'Available Events'**
  String get availableEvents;

  /// No description provided for @axaGroupSubsidiaryInNigeria.
  ///
  /// In en, this message translates to:
  /// **'AXA Group subsidiary in Nigeria'**
  String get axaGroupSubsidiaryInNigeria;

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

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @balance20000Per50000.
  ///
  /// In en, this message translates to:
  /// **'₦50,000 balance • ₦20,000 per txn'**
  String get balance20000Per50000;

  /// No description provided for @balanceCap.
  ///
  /// In en, this message translates to:
  /// **'Balance Cap'**
  String get balanceCap;

  /// No description provided for @balanceCap300000.
  ///
  /// In en, this message translates to:
  /// **'Balance cap: ₦300,000'**
  String get balanceCap300000;

  /// No description provided for @balanceCap5000000After.
  ///
  /// In en, this message translates to:
  /// **'Balance cap: ₦5,000,000 (after approval)'**
  String get balanceCap5000000After;

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

  /// No description provided for @biometricForTransactions.
  ///
  /// In en, this message translates to:
  /// **'Biometric for Transactions'**
  String get biometricForTransactions;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometrics;

  /// No description provided for @blockRequestNew.
  ///
  /// In en, this message translates to:
  /// **'Block & Request New'**
  String get blockRequestNew;

  /// No description provided for @bookFlights.
  ///
  /// In en, this message translates to:
  /// **'Book flights'**
  String get bookFlights;

  /// No description provided for @bookFlights2.
  ///
  /// In en, this message translates to:
  /// **'Book Flights'**
  String get bookFlights2;

  /// No description provided for @bookInterCityTravel.
  ///
  /// In en, this message translates to:
  /// **'Book inter-city travel'**
  String get bookInterCityTravel;

  /// No description provided for @builtWithInNigeria.
  ///
  /// In en, this message translates to:
  /// **'Built with ❤️ in Nigeria'**
  String get builtWithInNigeria;

  /// No description provided for @bulkTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bulk Transfer'**
  String get bulkTransfer;

  /// No description provided for @busTickets.
  ///
  /// In en, this message translates to:
  /// **'Bus tickets'**
  String get busTickets;

  /// No description provided for @busTickets2.
  ///
  /// In en, this message translates to:
  /// **'Bus Tickets'**
  String get busTickets2;

  /// No description provided for @businessAccount.
  ///
  /// In en, this message translates to:
  /// **'Business Account'**
  String get businessAccount;

  /// No description provided for @businessAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Business Analytics'**
  String get businessAnalytics;

  /// No description provided for @businessBalance.
  ///
  /// In en, this message translates to:
  /// **'Business Balance'**
  String get businessBalance;

  /// No description provided for @businessPremisesPhoto.
  ///
  /// In en, this message translates to:
  /// **'Business Premises Photo'**
  String get businessPremisesPhoto;

  /// No description provided for @businessServices.
  ///
  /// In en, this message translates to:
  /// **'Business Services'**
  String get businessServices;

  /// No description provided for @buyAirtimeAndDataBundles.
  ///
  /// In en, this message translates to:
  /// **'Buy airtime and data bundles'**
  String get buyAirtimeAndDataBundles;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @bvn.
  ///
  /// In en, this message translates to:
  /// **'BVN'**
  String get bvn;

  /// No description provided for @bvnGetbvnlabel.
  ///
  /// In en, this message translates to:
  /// **'BVN {_getBvnLabel}'**
  String bvnGetbvnlabel(Object _getBvnLabel);

  /// No description provided for @bvnVerification.
  ///
  /// In en, this message translates to:
  /// **'BVN Verification'**
  String get bvnVerification;

  /// No description provided for @ca.
  ///
  /// In en, this message translates to:
  /// **'CA'**
  String get ca;

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

  /// No description provided for @calculateAndPayYourZakat.
  ///
  /// In en, this message translates to:
  /// **'Calculate and pay your Zakat'**
  String get calculateAndPayYourZakat;

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

  /// No description provided for @cameraPreviewWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Camera preview will appear here'**
  String get cameraPreviewWillAppearHere;

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

  /// No description provided for @candidateRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Candidate / Registration Number'**
  String get candidateRegistrationNumber;

  /// No description provided for @captureSelfie.
  ///
  /// In en, this message translates to:
  /// **'Capture Selfie'**
  String get captureSelfie;

  /// No description provided for @cardFeeOfFeeWillBe.
  ///
  /// In en, this message translates to:
  /// **'Card fee of {fee} will be deducted from your account. Delivery in {deliveryDays} working days.'**
  String cardFeeOfFeeWillBe(Object fee, Object deliveryDays);

  /// No description provided for @cardPayment.
  ///
  /// In en, this message translates to:
  /// **'Card payment'**
  String get cardPayment;

  /// No description provided for @cardRequestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Card request submitted successfully!'**
  String get cardRequestSubmittedSuccessfully;

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

  /// No description provided for @cashbackEarned.
  ///
  /// In en, this message translates to:
  /// **'Cashback Earned'**
  String get cashbackEarned;

  /// No description provided for @cbnLicensed.
  ///
  /// In en, this message translates to:
  /// **'CBN licensed and regulated'**
  String get cbnLicensed;

  /// No description provided for @cbnLicensedPensionFundAdministrator.
  ///
  /// In en, this message translates to:
  /// **'CBN licensed pension fund administrator'**
  String get cbnLicensedPensionFundAdministrator;

  /// No description provided for @cbnRegulatedTransactionLimits.
  ///
  /// In en, this message translates to:
  /// **'CBN-regulated transaction limits'**
  String get cbnRegulatedTransactionLimits;

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

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

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

  /// No description provided for @chooseANew4DigitPin.
  ///
  /// In en, this message translates to:
  /// **'Choose a new 4-digit PIN'**
  String get chooseANew4DigitPin;

  /// No description provided for @chooseAccountType.
  ///
  /// In en, this message translates to:
  /// **'Choose the account type that fits your needs'**
  String get chooseAccountType;

  /// No description provided for @chooseDataPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Data Plan'**
  String get chooseDataPlan;

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

  /// No description provided for @chooseProvider.
  ///
  /// In en, this message translates to:
  /// **'Choose Provider'**
  String get chooseProvider;

  /// No description provided for @chooseTransportOperator.
  ///
  /// In en, this message translates to:
  /// **'Choose Transport Operator'**
  String get chooseTransportOperator;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @codeSentToYourRegisteredPhone.
  ///
  /// In en, this message translates to:
  /// **'Code sent to your registered phone number'**
  String get codeSentToYourRegisteredPhone;

  /// No description provided for @comfortClassOnWheels.
  ///
  /// In en, this message translates to:
  /// **'Comfort & class on wheels'**
  String get comfortClassOnWheels;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @comingSoon2.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon2;

  /// No description provided for @comingSoonFeature.
  ///
  /// In en, this message translates to:
  /// **'{label} is coming soon!'**
  String comingSoonFeature(Object label);

  /// No description provided for @completeLowerTiersFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete lower tiers first'**
  String get completeLowerTiersFirst;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @completeRequiredDocumentsToActivateYour.
  ///
  /// In en, this message translates to:
  /// **'Complete required documents to activate your account'**
  String get completeRequiredDocumentsToActivateYour;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @concertsShowsExperiences.
  ///
  /// In en, this message translates to:
  /// **'Concerts, shows & experiences'**
  String get concertsShowsExperiences;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmAndPay.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Pay {amount}'**
  String confirmAndPay(Object amount);

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

  /// No description provided for @confirmRequest.
  ///
  /// In en, this message translates to:
  /// **'Confirm Request'**
  String get confirmRequest;

  /// No description provided for @confirmTransaction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transaction'**
  String get confirmTransaction;

  /// No description provided for @confirmYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get confirmYourEmail;

  /// No description provided for @confirmYourIdentity.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your Identity'**
  String get confirmYourIdentity;

  /// No description provided for @confirmYourPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get confirmYourPin;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @continueArrow.
  ///
  /// In en, this message translates to:
  /// **'Continue →'**
  String get continueArrow;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @continueToAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue to Account'**
  String get continueToAccount;

  /// No description provided for @contributionType.
  ///
  /// In en, this message translates to:
  /// **'Contribution Type'**
  String get contributionType;

  /// No description provided for @conversionRate500Airtime40080.
  ///
  /// In en, this message translates to:
  /// **'80% conversion rate · ₦500 airtime = ₦400 cash'**
  String get conversionRate500Airtime40080;

  /// No description provided for @convertAirtimeToWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Convert airtime to wallet balance'**
  String get convertAirtimeToWalletBalance;

  /// No description provided for @convertedamount.
  ///
  /// In en, this message translates to:
  /// **'₦{_convertedAmount}'**
  String convertedamount(Object _convertedAmount);

  /// No description provided for @convertsTo.
  ///
  /// In en, this message translates to:
  /// **'converts to'**
  String get convertsTo;

  /// No description provided for @cooperativeName.
  ///
  /// In en, this message translates to:
  /// **'Nigerian Unity Cooperative'**
  String get cooperativeName;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy All'**
  String get copyAll;

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

  /// No description provided for @couldnTCreateTheReceiptPlease.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the receipt. Please try again.'**
  String get couldnTCreateTheReceiptPlease;

  /// No description provided for @couldnTLoadTransactions.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load transactions'**
  String get couldnTLoadTransactions;

  /// No description provided for @createAPin.
  ///
  /// In en, this message translates to:
  /// **'Create a PIN'**
  String get createAPin;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoice;

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

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createYourAccount;

  /// No description provided for @currentAccount.
  ///
  /// In en, this message translates to:
  /// **'Current Account'**
  String get currentAccount;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @currentTier.
  ///
  /// In en, this message translates to:
  /// **'Current Tier'**
  String get currentTier;

  /// No description provided for @currentTier2.
  ///
  /// In en, this message translates to:
  /// **'CURRENT TIER'**
  String get currentTier2;

  /// No description provided for @currentidxLength.
  ///
  /// In en, this message translates to:
  /// **'{currentIdx}/{length}'**
  String currentidxLength(Object currentIdx, Object length);

  /// No description provided for @currentidxTotalsteps.
  ///
  /// In en, this message translates to:
  /// **'{currentIdx}/{_totalSteps}'**
  String currentidxTotalsteps(Object currentIdx, Object _totalSteps);

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
  String dailyLimit(Object amount);

  /// No description provided for @dailyLimitUsage.
  ///
  /// In en, this message translates to:
  /// **'Daily Limit Usage'**
  String get dailyLimitUsage;

  /// No description provided for @dailyTransactionLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily Transaction Limit'**
  String get dailyTransactionLimit;

  /// No description provided for @dailyTransfers100000.
  ///
  /// In en, this message translates to:
  /// **'Daily transfers: ₦100,000'**
  String get dailyTransfers100000;

  /// No description provided for @dailyTransfers1000000.
  ///
  /// In en, this message translates to:
  /// **'Daily transfers: ₦1,000,000'**
  String get dailyTransfers1000000;

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

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @dateOfBirth2.
  ///
  /// In en, this message translates to:
  /// **'DATE OF BIRTH'**
  String get dateOfBirth2;

  /// No description provided for @dayMonthYear.
  ///
  /// In en, this message translates to:
  /// **'{day}/{month}/{year}'**
  String dayMonthYear(Object day, Object month, Object year);

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get days30;

  /// No description provided for @days60.
  ///
  /// In en, this message translates to:
  /// **'60 Days'**
  String get days60;

  /// No description provided for @days90.
  ///
  /// In en, this message translates to:
  /// **'90 Days'**
  String get days90;

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

  /// No description provided for @dedicatedAccountManager.
  ///
  /// In en, this message translates to:
  /// **'Dedicated account manager'**
  String get dedicatedAccountManager;

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

  /// No description provided for @deleteAccount2.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccount2;

  /// No description provided for @deliveryDeliverydaysDays.
  ///
  /// In en, this message translates to:
  /// **'Delivery: {deliveryDays} days'**
  String deliveryDeliverydaysDays(Object deliveryDays);

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

  /// No description provided for @didnTReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code? '**
  String get didnTReceiveCode;

  /// No description provided for @didnTReceiveIt.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive it? '**
  String get didnTReceiveIt;

  /// No description provided for @directorsIdCards.
  ///
  /// In en, this message translates to:
  /// **'Directors ID Cards'**
  String get directorsIdCards;

  /// No description provided for @discoPayments.
  ///
  /// In en, this message translates to:
  /// **'DISCO payments'**
  String get discoPayments;

  /// No description provided for @displaynameDisplayacct.
  ///
  /// In en, this message translates to:
  /// **'{displayName} · {displayAcct}'**
  String displaynameDisplayacct(Object displayName, Object displayAcct);

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

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get documentType;

  /// No description provided for @documentsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Documents Submitted!'**
  String get documentsSubmitted;

  /// No description provided for @domesticFlightsAtBestPrices.
  ///
  /// In en, this message translates to:
  /// **'Domestic flights at best prices'**
  String get domesticFlightsAtBestPrices;

  /// No description provided for @donateApply.
  ///
  /// In en, this message translates to:
  /// **'Donate / Apply'**
  String get donateApply;

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

  /// No description provided for @downloadPdfReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download PDF Receipt'**
  String get downloadPdfReceipt;

  /// No description provided for @downloadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download Receipt'**
  String get downloadReceipt;

  /// No description provided for @driverSLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License'**
  String get driverSLicense;

  /// No description provided for @earnUpTo13PerAnnum.
  ///
  /// In en, this message translates to:
  /// **'Earn up to 13% per annum'**
  String get earnUpTo13PerAnnum;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

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

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get emailAddress;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone'**
  String get emailOrPhone;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified!'**
  String get emailVerified;

  /// No description provided for @ensureGoodLighting.
  ///
  /// In en, this message translates to:
  /// **'Ensure good lighting'**
  String get ensureGoodLighting;

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

  /// No description provided for @enterOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP code'**
  String get enterOtpCode;

  /// No description provided for @enterOtpSentToYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP sent to your phone'**
  String get enterOtpSentToYourPhone;

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

  /// No description provided for @enterResetNcode.
  ///
  /// In en, this message translates to:
  /// **'Enter reset\ncode'**
  String get enterResetNcode;

  /// No description provided for @enterRrn.
  ///
  /// In en, this message translates to:
  /// **'Enter RRN'**
  String get enterRrn;

  /// No description provided for @enterTheCodeSentToYour.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your registered phone number.'**
  String get enterTheCodeSentToYour;

  /// No description provided for @enterTheEmailOrPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter the email or phone number on your account and we\'ll send a reset code.'**
  String get enterTheEmailOrPhoneNumber;

  /// No description provided for @enterTheOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP'**
  String get enterTheOtp;

  /// No description provided for @enterTheVerificationTokenSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification token sent to your email address to activate your account.'**
  String get enterTheVerificationTokenSentTo;

  /// No description provided for @enterTransactionPin.
  ///
  /// In en, this message translates to:
  /// **'Enter Transaction PIN'**
  String get enterTransactionPin;

  /// No description provided for @enterValidTenDigitPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit phone number'**
  String get enterValidTenDigitPhone;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get enterVerificationCode;

  /// No description provided for @enterVerificationCode2.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode2;

  /// No description provided for @enterYour4DigitPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your 4-digit PIN'**
  String get enterYour4DigitPin;

  /// No description provided for @enterYour4DigitPinTo.
  ///
  /// In en, this message translates to:
  /// **'Enter your 4-digit PIN to authorize this transaction'**
  String get enterYour4DigitPinTo;

  /// No description provided for @enterYourBusinessEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your business email address'**
  String get enterYourBusinessEmailAddress;

  /// No description provided for @enterYourDetailsToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Enter your details to get started'**
  String get enterYourDetailsToGetStarted;

  /// No description provided for @enterYourRrnForS.
  ///
  /// In en, this message translates to:
  /// **'Enter your RRN for {s}'**
  String enterYourRrnForS(Object s);

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @errorPickingFileE.
  ///
  /// In en, this message translates to:
  /// **'Error picking file: {e}'**
  String errorPickingFileE(Object e);

  /// No description provided for @errorPickingImageE.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {e}'**
  String errorPickingImageE(Object e);

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

  /// No description provided for @examBody.
  ///
  /// In en, this message translates to:
  /// **'Exam Body'**
  String get examBody;

  /// No description provided for @examType.
  ///
  /// In en, this message translates to:
  /// **'Exam Type'**
  String get examType;

  /// No description provided for @expiresAtOtpexpiresat.
  ///
  /// In en, this message translates to:
  /// **'Expires at {otpExpiresAt}'**
  String expiresAtOtpexpiresat(Object otpExpiresAt);

  /// No description provided for @faceVerification.
  ///
  /// In en, this message translates to:
  /// **'Face Verification'**
  String get faceVerification;

  /// No description provided for @faceVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Face verified successfully!'**
  String get faceVerifiedSuccessfully;

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

  /// No description provided for @feeFee.
  ///
  /// In en, this message translates to:
  /// **'Fee: {fee}'**
  String feeFee(Object fee);

  /// No description provided for @filterTransactions.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get filterTransactions;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @firstBankCustodian.
  ///
  /// In en, this message translates to:
  /// **'First Bank Custodian'**
  String get firstBankCustodian;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @fixedDeposit.
  ///
  /// In en, this message translates to:
  /// **'Fixed Deposit'**
  String get fixedDeposit;

  /// No description provided for @fixedFee.
  ///
  /// In en, this message translates to:
  /// **'Fixed Fee'**
  String get fixedFee;

  /// No description provided for @fixedamount.
  ///
  /// In en, this message translates to:
  /// **'₦{fixedAmount}'**
  String fixedamount(Object fixedAmount);

  /// No description provided for @fixedamount2.
  ///
  /// In en, this message translates to:
  /// **'₦{_fixedAmount}'**
  String fixedamount2(Object _fixedAmount);

  /// No description provided for @flights.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get flights;

  /// No description provided for @forgotIdtype.
  ///
  /// In en, this message translates to:
  /// **'Forgot {_idType}?'**
  String forgotIdtype(Object _idType);

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

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddress;

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

  /// No description provided for @fundYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Fund your account'**
  String get fundYourAccount;

  /// No description provided for @fundYourWallet.
  ///
  /// In en, this message translates to:
  /// **'Fund your RimaPay wallet'**
  String get fundYourWallet;

  /// No description provided for @fundsReflectInstantlyAfterTransfer.
  ///
  /// In en, this message translates to:
  /// **'Funds reflect instantly after transfer'**
  String get fundsReflectInstantlyAfterTransfer;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @gender2.
  ///
  /// In en, this message translates to:
  /// **'GENDER'**
  String get gender2;

  /// No description provided for @generatePaymentLinks.
  ///
  /// In en, this message translates to:
  /// **'Generate payment links'**
  String get generatePaymentLinks;

  /// No description provided for @generateProfessionalInvoices.
  ///
  /// In en, this message translates to:
  /// **'Generate professional invoices'**
  String get generateProfessionalInvoices;

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

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

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

  /// No description provided for @goodMorning2.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning2;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

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

  /// No description provided for @governmentId.
  ///
  /// In en, this message translates to:
  /// **'Government ID'**
  String get governmentId;

  /// No description provided for @governmentIdDocument.
  ///
  /// In en, this message translates to:
  /// **'Government ID Document'**
  String get governmentIdDocument;

  /// No description provided for @governmentInstitutionalPayments.
  ///
  /// In en, this message translates to:
  /// **'Government & institutional payments'**
  String get governmentInstitutionalPayments;

  /// No description provided for @governmentIssuedId.
  ///
  /// In en, this message translates to:
  /// **'Government-Issued ID'**
  String get governmentIssuedId;

  /// No description provided for @governmentService.
  ///
  /// In en, this message translates to:
  /// **'Government Service'**
  String get governmentService;

  /// No description provided for @governmentServices.
  ///
  /// In en, this message translates to:
  /// **'Government Services'**
  String get governmentServices;

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

  /// No description provided for @grantsDonations.
  ///
  /// In en, this message translates to:
  /// **'Grants & Donations'**
  String get grantsDonations;

  /// No description provided for @great.
  ///
  /// In en, this message translates to:
  /// **'Great!'**
  String get great;

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

  /// No description provided for @hideLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideLabel;

  /// No description provided for @holdOnAMoment.
  ///
  /// In en, this message translates to:
  /// **'Hold on a moment ...'**
  String get holdOnAMoment;

  /// No description provided for @holdOnAMomentThisCan.
  ///
  /// In en, this message translates to:
  /// **'Hold on a moment — this can take a few seconds.\nPlease don\'t close or refresh the page.'**
  String get holdOnAMomentThisCan;

  /// No description provided for @holdOnAMomentU2014This.
  ///
  /// In en, this message translates to:
  /// **'Hold on a moment — this can take a few seconds.\nPlease don\'t close or refresh the page.'**
  String get holdOnAMomentU2014This;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @iVeSentTheMoney.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Sent the Money'**
  String get iVeSentTheMoney;

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
  String insufficientBalanceIs(Object balance);

  /// No description provided for @insufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds'**
  String get insufficientFunds;

  /// No description provided for @insuredByNdic.
  ///
  /// In en, this message translates to:
  /// **'Insured by NDIC'**
  String get insuredByNdic;

  /// No description provided for @internationalPassport.
  ///
  /// In en, this message translates to:
  /// **'International Passport'**
  String get internationalPassport;

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

  /// No description provided for @internetServices.
  ///
  /// In en, this message translates to:
  /// **'Internet Services'**
  String get internetServices;

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

  /// No description provided for @invoiceInv2024001.
  ///
  /// In en, this message translates to:
  /// **'Invoice #INV-2024-001'**
  String get invoiceInv2024001;

  /// No description provided for @itemfeeFee.
  ///
  /// In en, this message translates to:
  /// **'+₦{itemFee} fee'**
  String itemfeeFee(Object itemFee);

  /// No description provided for @kycVerification.
  ///
  /// In en, this message translates to:
  /// **'KYC Verification'**
  String get kycVerification;

  /// No description provided for @labelCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String labelCopied(Object label);

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

  /// No description provided for @largestPfaInNigeriaByAum.
  ///
  /// In en, this message translates to:
  /// **'Largest PFA in Nigeria by AUM'**
  String get largestPfaInNigeriaByAum;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @lastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsed;

  /// No description provided for @leadwayGroupPensionArm.
  ///
  /// In en, this message translates to:
  /// **'Leadway Group pension arm'**
  String get leadwayGroupPensionArm;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'{length}'**
  String length(Object length);

  /// No description provided for @lengthFlightsFoundCodeCode2.
  ///
  /// In en, this message translates to:
  /// **'{length} flights found · {code} → {code2}'**
  String lengthFlightsFoundCodeCode2(Object length, Object code, Object code2);

  /// No description provided for @lengthLength2.
  ///
  /// In en, this message translates to:
  /// **'{length}/{length2}'**
  String lengthLength2(Object length, Object length2);

  /// No description provided for @lga.
  ///
  /// In en, this message translates to:
  /// **'LGA'**
  String get lga;

  /// No description provided for @licensedByCbn.
  ///
  /// In en, this message translates to:
  /// **'Licensed by CBN'**
  String get licensedByCbn;

  /// No description provided for @licensedByPencom.
  ///
  /// In en, this message translates to:
  /// **'Licensed by PenCom'**
  String get licensedByPencom;

  /// No description provided for @licensedByTheCbn.
  ///
  /// In en, this message translates to:
  /// **'Licensed by the CBN'**
  String get licensedByTheCbn;

  /// No description provided for @limitsAreSetInAccordanceWith.
  ///
  /// In en, this message translates to:
  /// **'Limits are set in accordance with CBN regulations for microfinance banks. Upgrade your account tier to increase your limits.'**
  String get limitsAreSetInAccordanceWith;

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

  /// No description provided for @loadingPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading payment details…'**
  String get loadingPaymentDetails;

  /// No description provided for @loadingPlans.
  ///
  /// In en, this message translates to:
  /// **'Loading plans…'**
  String get loadingPlans;

  /// No description provided for @loadingProviders.
  ///
  /// In en, this message translates to:
  /// **'Loading providers…'**
  String get loadingProviders;

  /// No description provided for @loanComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Loan application coming soon!'**
  String get loanComingSoon;

  /// No description provided for @loanPitch.
  ///
  /// In en, this message translates to:
  /// **'Get up to {amount} at low interest. Quick approval.'**
  String loanPitch(Object amount);

  /// No description provided for @loanServicesAreNowAvailableIn.
  ///
  /// In en, this message translates to:
  /// **'Loan services are now available in your RimaPay app. Apply for instant loans up to ₦500,000'**
  String get loanServicesAreNowAvailableIn;

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

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logOut2.
  ///
  /// In en, this message translates to:
  /// **'Log Out?'**
  String get logOut2;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Logout Confirmation'**
  String get logoutConfirmation;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @markAsFavorite.
  ///
  /// In en, this message translates to:
  /// **'Mark as Favorite'**
  String get markAsFavorite;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get markRead;

  /// No description provided for @max10TicketsPerOrder.
  ///
  /// In en, this message translates to:
  /// **'Max 10 tickets per order'**
  String get max10TicketsPerOrder;

  /// No description provided for @max4PerBooking.
  ///
  /// In en, this message translates to:
  /// **'Max 4 per booking'**
  String get max4PerBooking;

  /// No description provided for @meterNumber.
  ///
  /// In en, this message translates to:
  /// **'Meter Number'**
  String get meterNumber;

  /// No description provided for @methodComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{method} coming soon'**
  String methodComingSoon(Object method);

  /// No description provided for @min50Max50000.
  ///
  /// In en, this message translates to:
  /// **'Min: ₦50, Max: ₦50,000'**
  String get min50Max50000;

  /// No description provided for @minEightCharacters.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get minEightCharacters;

  /// No description provided for @minMaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Min: {min}, Max: {max}'**
  String minMaxAmount(Object min, Object max);

  /// No description provided for @minimum10000.
  ///
  /// In en, this message translates to:
  /// **'Minimum: ₦10,000'**
  String get minimum10000;

  /// No description provided for @minimumAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum amount is {amount}'**
  String minimumAmount(Object amount);

  /// No description provided for @minimumTransfer100.
  ///
  /// In en, this message translates to:
  /// **'Minimum transfer: ₦100'**
  String get minimumTransfer100;

  /// No description provided for @mobileTopUp.
  ///
  /// In en, this message translates to:
  /// **'Mobile Top-Up'**
  String get mobileTopUp;

  /// No description provided for @modernFleetNationwide.
  ///
  /// In en, this message translates to:
  /// **'Modern fleet nationwide'**
  String get modernFleetNationwide;

  /// No description provided for @monFri8am8pmNsat9am.
  ///
  /// In en, this message translates to:
  /// **'Mon – Fri: 8am – 8pm\nSat: 9am – 5pm'**
  String get monFri8am8pmNsat9am;

  /// No description provided for @moneyReceived.
  ///
  /// In en, this message translates to:
  /// **'Money Received'**
  String get moneyReceived;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @monthlySubscription.
  ///
  /// In en, this message translates to:
  /// **'Monthly subscription'**
  String get monthlySubscription;

  /// No description provided for @monthlyTransactionLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly Transaction Limit'**
  String get monthlyTransactionLimit;

  /// No description provided for @months6.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get months6;

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

  /// No description provided for @multipleTransfersAtOnce.
  ///
  /// In en, this message translates to:
  /// **'Multiple transfers at once'**
  String get multipleTransfersAtOnce;

  /// No description provided for @mustBeAtLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters with upper, lower, number & special char'**
  String get mustBeAtLeast8Characters;

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

  /// No description provided for @myToDos.
  ///
  /// In en, this message translates to:
  /// **'My To-dos'**
  String get myToDos;

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

  /// No description provided for @newDeviceLoginDetectedFromLagos.
  ///
  /// In en, this message translates to:
  /// **'New device login detected from Lagos, Nigeria. If this wasn\'t you, please secure your account.'**
  String get newDeviceLoginDetectedFromLagos;

  /// No description provided for @newFeatureAvailable.
  ///
  /// In en, this message translates to:
  /// **'New Feature Available'**
  String get newFeatureAvailable;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newLabel;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

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

  /// No description provided for @nin.
  ///
  /// In en, this message translates to:
  /// **'NIN'**
  String get nin;

  /// No description provided for @ninGetninlabel.
  ///
  /// In en, this message translates to:
  /// **'NIN {_getNinLabel}'**
  String ninGetninlabel(Object _getNinLabel);

  /// No description provided for @ninSlip.
  ///
  /// In en, this message translates to:
  /// **'NIN Slip'**
  String get ninSlip;

  /// No description provided for @nisabThreshold.
  ///
  /// In en, this message translates to:
  /// **'Nisab threshold: '**
  String get nisabThreshold;

  /// No description provided for @noPlansAvailable.
  ///
  /// In en, this message translates to:
  /// **'No plans available'**
  String get noPlansAvailable;

  /// No description provided for @noPlansAvailableRetry.
  ///
  /// In en, this message translates to:
  /// **'No plans available. Tap to retry.'**
  String get noPlansAvailableRetry;

  /// No description provided for @noProvidersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No providers available right now. Tap to retry.'**
  String get noProvidersAvailable;

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

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'{number}...'**
  String number(Object number);

  /// No description provided for @numberOfPassengers.
  ///
  /// In en, this message translates to:
  /// **'Number of Passengers'**
  String get numberOfPassengers;

  /// No description provided for @numberOfTickets.
  ///
  /// In en, this message translates to:
  /// **'Number of Tickets'**
  String get numberOfTickets;

  /// No description provided for @openAnNaccount.
  ///
  /// In en, this message translates to:
  /// **'Open an\nAccount'**
  String get openAnNaccount;

  /// No description provided for @openUnderbankedAccount.
  ///
  /// In en, this message translates to:
  /// **'Open Underbanked Account?'**
  String get openUnderbankedAccount;

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

  /// No description provided for @otpSentToYourRegisteredNumber.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to your registered number'**
  String get otpSentToYourRegisteredNumber;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pageNotFound;

  /// No description provided for @partOfFidelityBankGroup.
  ///
  /// In en, this message translates to:
  /// **'Part of Fidelity Bank Group'**
  String get partOfFidelityBankGroup;

  /// No description provided for @passengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get passengers;

  /// No description provided for @passengers2.
  ///
  /// In en, this message translates to:
  /// **'{_passengers}'**
  String passengers2(Object _passengers);

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password Changed!'**
  String get passwordChanged;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password Changed Successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Min 8 chars with uppercase, lowercase & number'**
  String get passwordRequirements;

  /// No description provided for @passwordReset.
  ///
  /// In en, this message translates to:
  /// **'Password reset!'**
  String get passwordReset;

  /// No description provided for @payBills.
  ///
  /// In en, this message translates to:
  /// **'Pay Bills'**
  String get payBills;

  /// No description provided for @payBillsManageServices.
  ///
  /// In en, this message translates to:
  /// **'Pay bills & manage services'**
  String get payBillsManageServices;

  /// No description provided for @payCableTvSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Pay cable TV subscriptions'**
  String get payCableTvSubscriptions;

  /// No description provided for @payElectricityBills.
  ///
  /// In en, this message translates to:
  /// **'Pay electricity bills'**
  String get payElectricityBills;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @payWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Pay with Biometrics'**
  String get payWithBiometrics;

  /// No description provided for @payZakatZakatdue.
  ///
  /// In en, this message translates to:
  /// **'Pay Zakat ({_zakatDue})'**
  String payZakatZakatdue(Object _zakatDue);

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get paymentAmount;

  /// No description provided for @paymentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment Completed'**
  String get paymentCompleted;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccessful;

  /// No description provided for @paymentSuccessfulCelebrate.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful! 🎉'**
  String get paymentSuccessfulCelebrate;

  /// No description provided for @paymentsAreForwardedDirectlyToThe.
  ///
  /// In en, this message translates to:
  /// **'Payments are forwarded directly to the relevant government agency'**
  String get paymentsAreForwardedDirectlyToThe;

  /// No description provided for @payroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll;

  /// No description provided for @pencomRegulatedContributions.
  ///
  /// In en, this message translates to:
  /// **'PenCom regulated contributions'**
  String get pencomRegulatedContributions;

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

  /// No description provided for @pensionFundAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Pension Fund Administrator'**
  String get pensionFundAdministrator;

  /// No description provided for @pepDeclaration.
  ///
  /// In en, this message translates to:
  /// **'PEP Declaration'**
  String get pepDeclaration;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'Per Day'**
  String get perDay;

  /// No description provided for @perPerson.
  ///
  /// In en, this message translates to:
  /// **'/person'**
  String get perPerson;

  /// No description provided for @perTicket.
  ///
  /// In en, this message translates to:
  /// **'/ticket'**
  String get perTicket;

  /// No description provided for @percent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String percent(Object percent);

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

  /// No description provided for @phoneNumber2.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER'**
  String get phoneNumber2;

  /// No description provided for @phoneTransfer.
  ///
  /// In en, this message translates to:
  /// **'Phone Transfer'**
  String get phoneTransfer;

  /// No description provided for @pinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed!'**
  String get pinChanged;

  /// No description provided for @pinChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN Changed Successfully'**
  String get pinChangedSuccessfully;

  /// No description provided for @pinFourToEightDigits.
  ///
  /// In en, this message translates to:
  /// **'PIN (4-8 digits)'**
  String get pinFourToEightDigits;

  /// No description provided for @pinReset.
  ///
  /// In en, this message translates to:
  /// **'PIN reset!'**
  String get pinReset;

  /// No description provided for @placeFixedDeposit.
  ///
  /// In en, this message translates to:
  /// **'Place Fixed Deposit'**
  String get placeFixedDeposit;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @planBlurb.
  ///
  /// In en, this message translates to:
  /// **'Get {data} for {price}. Valid for {validity}'**
  String planBlurb(Object data, Object price, Object validity);

  /// No description provided for @planDuration.
  ///
  /// In en, this message translates to:
  /// **'Plan Duration'**
  String get planDuration;

  /// No description provided for @pleaseEnterAComplete10Digit.
  ///
  /// In en, this message translates to:
  /// **'Please enter a complete 10-digit phone number'**
  String get pleaseEnterAComplete10Digit;

  /// No description provided for @pleaseEnterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your address'**
  String get pleaseEnterYourAddress;

  /// No description provided for @pleaseEnterYourLga.
  ///
  /// In en, this message translates to:
  /// **'Please enter your LGA'**
  String get pleaseEnterYourLga;

  /// No description provided for @pleaseHoldStill.
  ///
  /// In en, this message translates to:
  /// **'Please hold still'**
  String get pleaseHoldStill;

  /// No description provided for @pleaseProvideYourOwnBvnNin.
  ///
  /// In en, this message translates to:
  /// **'Please provide your own BVN/NIN to verify your account opening application'**
  String get pleaseProvideYourOwnBvnNin;

  /// No description provided for @pleaseReEnterYourDetailsTo.
  ///
  /// In en, this message translates to:
  /// **'Please re-enter your details to confirm'**
  String get pleaseReEnterYourDetailsTo;

  /// No description provided for @pleaseSelectAnOption.
  ///
  /// In en, this message translates to:
  /// **'Please select an option'**
  String get pleaseSelectAnOption;

  /// No description provided for @pleaseSelectOccupationAndIncome.
  ///
  /// In en, this message translates to:
  /// **'Please select occupation and income'**
  String get pleaseSelectOccupationAndIncome;

  /// No description provided for @pleaseSelectYourState.
  ///
  /// In en, this message translates to:
  /// **'Please select your state'**
  String get pleaseSelectYourState;

  /// No description provided for @pleaseWaitWhileWeProcessYour.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we process your data purchase...'**
  String get pleaseWaitWhileWeProcessYour;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @positionYourFaceInTheOval.
  ///
  /// In en, this message translates to:
  /// **'Position your face in the oval'**
  String get positionYourFaceInTheOval;

  /// No description provided for @postpaid.
  ///
  /// In en, this message translates to:
  /// **'Postpaid'**
  String get postpaid;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @premiumInterstateTravel.
  ///
  /// In en, this message translates to:
  /// **'Premium interstate travel'**
  String get premiumInterstateTravel;

  /// No description provided for @prepaid.
  ///
  /// In en, this message translates to:
  /// **'Prepaid'**
  String get prepaid;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'₦{price}'**
  String price(Object price);

  /// No description provided for @priceperseatSeat.
  ///
  /// In en, this message translates to:
  /// **'₦{pricePerSeat}/seat'**
  String priceperseatSeat(Object pricePerSeat);

  /// No description provided for @priorityCustomerSupport.
  ///
  /// In en, this message translates to:
  /// **'Priority customer support'**
  String get priorityCustomerSupport;

  /// No description provided for @priorityPriority2.
  ///
  /// In en, this message translates to:
  /// **'{priority}{priority2}'**
  String priorityPriority2(Object priority, Object priority2);

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

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

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @processingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing Payment'**
  String get processingPayment;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profileCompleted.
  ///
  /// In en, this message translates to:
  /// **'Profile Completed!'**
  String get profileCompleted;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @proofOfAddress.
  ///
  /// In en, this message translates to:
  /// **'Proof of Address'**
  String get proofOfAddress;

  /// No description provided for @protected.
  ///
  /// In en, this message translates to:
  /// **'PROTECTED'**
  String get protected;

  /// No description provided for @provideDetailsOfYourSourceOf.
  ///
  /// In en, this message translates to:
  /// **'Provide details of your source of income'**
  String get provideDetailsOfYourSourceOf;

  /// No description provided for @provideEitherBvnOrNinOnly.
  ///
  /// In en, this message translates to:
  /// **'• Provide either BVN OR NIN (only one required)\n• Complete OTP verification'**
  String get provideEitherBvnOrNinOnly;

  /// No description provided for @provideYourBvnOrNinIf.
  ///
  /// In en, this message translates to:
  /// **'Provide your BVN or NIN if you have one. This step is optional for underbanked accounts.'**
  String get provideYourBvnOrNinIf;

  /// No description provided for @providernamePackages.
  ///
  /// In en, this message translates to:
  /// **'{providerName} Packages'**
  String providernamePackages(Object providerName);

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @qualityPensionManagement.
  ///
  /// In en, this message translates to:
  /// **'Quality pension management'**
  String get qualityPensionManagement;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'{_quantity}'**
  String quantity(Object _quantity);

  /// No description provided for @questionsContactSupportRimapayCom.
  ///
  /// In en, this message translates to:
  /// **'Questions? Contact support@rimapay.com'**
  String get questionsContactSupportRimapayCom;

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

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'{rate}%'**
  String rate(Object rate);

  /// No description provided for @ratePA.
  ///
  /// In en, this message translates to:
  /// **'{rate}% p.a.'**
  String ratePA(Object rate);

  /// No description provided for @reEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reEnterPassword;

  /// No description provided for @reEnterYour4DigitPin.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your 4-digit PIN to confirm'**
  String get reEnterYour4DigitPin;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @receiptCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Receipt copied to clipboard'**
  String get receiptCopiedToClipboard;

  /// No description provided for @receiptDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Receipt downloaded successfully'**
  String get receiptDownloaded;

  /// No description provided for @receiptGeneratedNote.
  ///
  /// In en, this message translates to:
  /// **'This receipt was generated by the RimaPay app. Keep the Transaction ID for any enquiry.'**
  String get receiptGeneratedNote;

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

  /// No description provided for @recentPurchases.
  ///
  /// In en, this message translates to:
  /// **'Recent Purchases'**
  String get recentPurchases;

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

  /// No description provided for @referenceCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Reference copied to clipboard'**
  String get referenceCopiedToClipboard;

  /// No description provided for @registerDeviceToAccount.
  ///
  /// In en, this message translates to:
  /// **'Register this device to your account'**
  String get registerDeviceToAccount;

  /// No description provided for @registeredNumberCanTBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Registered number — can\'t be changed. Others find you by this.'**
  String get registeredNumberCanTBeChanged;

  /// No description provided for @regulatedByPencomContributionsAreTax.
  ///
  /// In en, this message translates to:
  /// **'Regulated by PenCom · Contributions are tax deductible'**
  String get regulatedByPencomContributionsAreTax;

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

  /// No description provided for @replaceCard.
  ///
  /// In en, this message translates to:
  /// **'Replace card'**
  String get replaceCard;

  /// No description provided for @requestAPhysicalDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Request a physical debit card'**
  String get requestAPhysicalDebitCard;

  /// No description provided for @requestCard.
  ///
  /// In en, this message translates to:
  /// **'Request Card'**
  String get requestCard;

  /// No description provided for @requestFailedStatuscode.
  ///
  /// In en, this message translates to:
  /// **'Request failed ({statusCode}).'**
  String requestFailedStatuscode(Object statusCode);

  /// No description provided for @requestPayment.
  ///
  /// In en, this message translates to:
  /// **'Request Payment'**
  String get requestPayment;

  /// No description provided for @requestSelectedcard.
  ///
  /// In en, this message translates to:
  /// **'Request {_selectedCard}?'**
  String requestSelectedcard(Object _selectedCard);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendCode2.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode2;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds} s'**
  String resendCodeIn(Object seconds);

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resetCode.
  ///
  /// In en, this message translates to:
  /// **'Reset Code'**
  String get resetCode;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetTransactionPin.
  ///
  /// In en, this message translates to:
  /// **'Reset Transaction PIN'**
  String get resetTransactionPin;

  /// No description provided for @resetYourNpassword.
  ///
  /// In en, this message translates to:
  /// **'Reset your\npassword'**
  String get resetYourNpassword;

  /// No description provided for @residentialAddress.
  ///
  /// In en, this message translates to:
  /// **'Residential Address'**
  String get residentialAddress;

  /// No description provided for @retrieveYourPaymentDetailsUsingThe.
  ///
  /// In en, this message translates to:
  /// **'Retrieve your payment details using the Remita Retrieval Reference'**
  String get retrieveYourPaymentDetailsUsingThe;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @returnDate.
  ///
  /// In en, this message translates to:
  /// **'Return Date'**
  String get returnDate;

  /// No description provided for @returnLabel.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnLabel;

  /// No description provided for @reviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get reviewSubmit;

  /// No description provided for @reviewTheDocumentsYouUploadedBefore.
  ///
  /// In en, this message translates to:
  /// **'Review the documents you uploaded before submitting for verification.'**
  String get reviewTheDocumentsYouUploadedBefore;

  /// No description provided for @rimaMfb.
  ///
  /// In en, this message translates to:
  /// **'RIMA MFB'**
  String get rimaMfb;

  /// No description provided for @rimapayAccountOrPhone.
  ///
  /// In en, this message translates to:
  /// **'RimaPay Account / Phone'**
  String get rimapayAccountOrPhone;

  /// No description provided for @rimapayAccountcontroller.
  ///
  /// In en, this message translates to:
  /// **'RimaPay · {_accountController}'**
  String rimapayAccountcontroller(Object _accountController);

  /// No description provided for @rimapayReceiptReference.
  ///
  /// In en, this message translates to:
  /// **'RimaPay Receipt {reference}'**
  String rimapayReceiptReference(Object reference);

  /// No description provided for @rimapayV210.
  ///
  /// In en, this message translates to:
  /// **'RimaPay v2.1.0'**
  String get rimapayV210;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @rsaPin.
  ///
  /// In en, this message translates to:
  /// **'RSA PIN'**
  String get rsaPin;

  /// No description provided for @safeReliableJourneys.
  ///
  /// In en, this message translates to:
  /// **'Safe & reliable journeys'**
  String get safeReliableJourneys;

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

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

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

  /// No description provided for @scheduledMaintenanceOnSunday2am4am.
  ///
  /// In en, this message translates to:
  /// **'Scheduled maintenance on Sunday 2AM - 4AM. Some services may be temporarily unavailable.'**
  String get scheduledMaintenanceOnSunday2am4am;

  /// No description provided for @searchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search Address'**
  String get searchAddress;

  /// No description provided for @searchBanks.
  ///
  /// In en, this message translates to:
  /// **'Search banks…'**
  String get searchBanks;

  /// No description provided for @searchByNameType.
  ///
  /// In en, this message translates to:
  /// **'Search by name, type...'**
  String get searchByNameType;

  /// No description provided for @searchFlights.
  ///
  /// In en, this message translates to:
  /// **'Search Flights'**
  String get searchFlights;

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

  /// No description provided for @seatCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 seat} other{{count} seats}}'**
  String seatCount(int count);

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

  /// No description provided for @secureTransaction2.
  ///
  /// In en, this message translates to:
  /// **'Secure Transaction'**
  String get secureTransaction2;

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

  /// No description provided for @security2.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get security2;

  /// No description provided for @securityAlert.
  ///
  /// In en, this message translates to:
  /// **'Security Alert'**
  String get securityAlert;

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

  /// No description provided for @selectAllSourcesOfRevenueFor.
  ///
  /// In en, this message translates to:
  /// **'Select all sources of revenue for your business'**
  String get selectAllSourcesOfRevenueFor;

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

  /// No description provided for @selectExamBody.
  ///
  /// In en, this message translates to:
  /// **'Select Exam Body'**
  String get selectExamBody;

  /// No description provided for @selectExamType.
  ///
  /// In en, this message translates to:
  /// **'Select Exam Type'**
  String get selectExamType;

  /// No description provided for @selectIdType.
  ///
  /// In en, this message translates to:
  /// **'Select ID type'**
  String get selectIdType;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectNetwork.
  ///
  /// In en, this message translates to:
  /// **'Select Network'**
  String get selectNetwork;

  /// No description provided for @selectNetworkFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a network first'**
  String get selectNetworkFirst;

  /// No description provided for @selectPensionFundAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Select Pension Fund Administrator'**
  String get selectPensionFundAdministrator;

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

  /// No description provided for @selectProviderFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a provider first'**
  String get selectProviderFirst;

  /// No description provided for @selectService.
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get selectService;

  /// No description provided for @selectState.
  ///
  /// In en, this message translates to:
  /// **'Select State'**
  String get selectState;

  /// No description provided for @selectTransferMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a transfer method'**
  String get selectTransferMethod;

  /// No description provided for @selectWhatBestDescribesYou.
  ///
  /// In en, this message translates to:
  /// **'Select what best describes you'**
  String get selectWhatBestDescribesYou;

  /// No description provided for @selectedPassengersPriceTotalprice.
  ///
  /// In en, this message translates to:
  /// **'Selected · {_passengers} × ₦{price} = ₦{_totalPrice}'**
  String selectedPassengersPriceTotalprice(
      Object _passengers, Object price, Object _totalPrice);

  /// No description provided for @selectedbankBankaccountcontroller.
  ///
  /// In en, this message translates to:
  /// **'{_selectedBank} · {_bankAccountController}'**
  String selectedbankBankaccountcontroller(
      Object _selectedBank, Object _bankAccountController);

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

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Code'**
  String get sendResetCode;

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
  String serviceRequiresTier(Object tier);

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

  /// No description provided for @setA4DigitPinFor.
  ///
  /// In en, this message translates to:
  /// **'Set a 4-digit PIN for transactions'**
  String get setA4DigitPinFor;

  /// No description provided for @setANew4DigitPin.
  ///
  /// In en, this message translates to:
  /// **'Set a new 4-digit PIN'**
  String get setANew4DigitPin;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @setUpA4DigitTransaction.
  ///
  /// In en, this message translates to:
  /// **'Set up a 4-digit transaction PIN'**
  String get setUpA4DigitTransaction;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

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

  /// No description provided for @shareTheseDetailsToReceiveMoney.
  ///
  /// In en, this message translates to:
  /// **'Share these details to receive money'**
  String get shareTheseDetailsToReceiveMoney;

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

  /// No description provided for @signInWithFingerprintOrFace.
  ///
  /// In en, this message translates to:
  /// **'Sign in with fingerprint or face'**
  String get signInWithFingerprintOrFace;

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

  /// No description provided for @smartCardIucNumber.
  ///
  /// In en, this message translates to:
  /// **'Smart Card / IUC Number'**
  String get smartCardIucNumber;

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

  /// No description provided for @sourceOfIncome.
  ///
  /// In en, this message translates to:
  /// **'Source of Income'**
  String get sourceOfIncome;

  /// No description provided for @spectranetSmileMore.
  ///
  /// In en, this message translates to:
  /// **'Spectranet, Smile & more'**
  String get spectranetSmileMore;

  /// No description provided for @staffSalaryPayments.
  ///
  /// In en, this message translates to:
  /// **'Staff salary payments'**
  String get staffSalaryPayments;

  /// No description provided for @startSending.
  ///
  /// In en, this message translates to:
  /// **'Start Sending'**
  String get startSending;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @stationeryPurchase.
  ///
  /// In en, this message translates to:
  /// **'Stationery purchase'**
  String get stationeryPurchase;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @submitForVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitForVerification;

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

  /// No description provided for @supportACauseToday.
  ///
  /// In en, this message translates to:
  /// **'Support a cause today'**
  String get supportACauseToday;

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

  /// No description provided for @systemMaintenance.
  ///
  /// In en, this message translates to:
  /// **'System Maintenance'**
  String get systemMaintenance;

  /// No description provided for @takeAClearSelfieForIdentity.
  ///
  /// In en, this message translates to:
  /// **'Take a clear selfie for identity verification.'**
  String get takeAClearSelfieForIdentity;

  /// No description provided for @takeAClearSelfieNoGlasses.
  ///
  /// In en, this message translates to:
  /// **'Take a clear selfie — no glasses, good lighting, face centered.'**
  String get takeAClearSelfieNoGlasses;

  /// No description provided for @takeAPhotoOfYourBusiness.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your business location'**
  String get takeAPhotoOfYourBusiness;

  /// No description provided for @takeASelfieToVerifyYour.
  ///
  /// In en, this message translates to:
  /// **'Take a selfie to verify your identity'**
  String get takeASelfieToVerifyYour;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @taxesAndFees.
  ///
  /// In en, this message translates to:
  /// **'Taxes & fees'**
  String get taxesAndFees;

  /// No description provided for @taxesLeviesOfficialPayments.
  ///
  /// In en, this message translates to:
  /// **'Taxes, levies & official payments'**
  String get taxesLeviesOfficialPayments;

  /// No description provided for @tellUsAboutYourBusiness.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your business'**
  String get tellUsAboutYourBusiness;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get tellUsAboutYourself;

  /// No description provided for @thankYouForBankingWithRima.
  ///
  /// In en, this message translates to:
  /// **'Thank you for banking with Rima MFB'**
  String get thankYouForBankingWithRima;

  /// No description provided for @thankYouForUsingRimapay.
  ///
  /// In en, this message translates to:
  /// **'Thank you for using RimaPay'**
  String get thankYouForUsingRimapay;

  /// No description provided for @thePageYouAreLookingFor.
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist.'**
  String get thePageYouAreLookingFor;

  /// No description provided for @thisFeatureIsUnderDevelopmentNcheck.
  ///
  /// In en, this message translates to:
  /// **'This feature is under development.\nCheck back soon!'**
  String get thisFeatureIsUnderDevelopmentNcheck;

  /// No description provided for @thisWillPermanentlyDeleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all data. This action cannot be undone.'**
  String get thisWillPermanentlyDeleteYourAccount;

  /// No description provided for @ticketCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ticket} other{{count} tickets}}'**
  String ticketCount(int count);

  /// No description provided for @ticketsAndConcerts.
  ///
  /// In en, this message translates to:
  /// **'Tickets & concerts'**
  String get ticketsAndConcerts;

  /// No description provided for @tier1Requirements.
  ///
  /// In en, this message translates to:
  /// **'Tier 1 Requirements'**
  String get tier1Requirements;

  /// No description provided for @tier2IdentityVerification.
  ///
  /// In en, this message translates to:
  /// **'Tier 2 · Identity Verification'**
  String get tier2IdentityVerification;

  /// No description provided for @tier2Requirements.
  ///
  /// In en, this message translates to:
  /// **'Tier 2 Requirements'**
  String get tier2Requirements;

  /// No description provided for @tier3Requirements.
  ///
  /// In en, this message translates to:
  /// **'Tier 3 Requirements'**
  String get tier3Requirements;

  /// No description provided for @tierBenefits.
  ///
  /// In en, this message translates to:
  /// **'Tier Benefits'**
  String get tierBenefits;

  /// No description provided for @tierIndex.
  ///
  /// In en, this message translates to:
  /// **'Tier {index}'**
  String tierIndex(Object index);

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

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

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

  /// No description provided for @todaySIncome.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Income'**
  String get todaySIncome;

  /// No description provided for @todaySSpending.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Spending'**
  String get todaySSpending;

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

  /// No description provided for @totalLimit.
  ///
  /// In en, this message translates to:
  /// **'Total Limit'**
  String get totalLimit;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'₦{total} spent'**
  String totalSpent(Object total);

  /// No description provided for @totalWealth.
  ///
  /// In en, this message translates to:
  /// **'Total Wealth'**
  String get totalWealth;

  /// No description provided for @totalprice.
  ///
  /// In en, this message translates to:
  /// **'₦{_totalPrice}'**
  String totalprice(Object _totalPrice);

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

  /// No description provided for @transactionLimits.
  ///
  /// In en, this message translates to:
  /// **'Transaction Limits'**
  String get transactionLimits;

  /// No description provided for @transactionPin.
  ///
  /// In en, this message translates to:
  /// **'Transaction PIN'**
  String get transactionPin;

  /// No description provided for @transactionProcessedOk.
  ///
  /// In en, this message translates to:
  /// **'Your {type} has been processed successfully'**
  String transactionProcessedOk(Object type);

  /// No description provided for @transactionReceipt.
  ///
  /// In en, this message translates to:
  /// **'Transaction Receipt'**
  String get transactionReceipt;

  /// No description provided for @transactionReference.
  ///
  /// In en, this message translates to:
  /// **'Transaction Reference'**
  String get transactionReference;

  /// No description provided for @transactionStatusBody.
  ///
  /// In en, this message translates to:
  /// **'Your {type} transaction has been {status}'**
  String transactionStatusBody(Object type, Object status);

  /// No description provided for @transactionStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction {status}'**
  String transactionStatusTitle(Object status);

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

  /// No description provided for @transferToBanksWallets.
  ///
  /// In en, this message translates to:
  /// **'Transfer to banks & wallets'**
  String get transferToBanksWallets;

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

  /// No description provided for @transfersAreAvailable247Including.
  ///
  /// In en, this message translates to:
  /// **'Transfers are available 24/7 including weekends'**
  String get transfersAreAvailable247Including;

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

  /// No description provided for @transportOperator.
  ///
  /// In en, this message translates to:
  /// **'Transport Operator'**
  String get transportOperator;

  /// No description provided for @travelDate.
  ///
  /// In en, this message translates to:
  /// **'Travel Date'**
  String get travelDate;

  /// No description provided for @trustedPensionManagerSince2004.
  ///
  /// In en, this message translates to:
  /// **'Trusted pension manager since 2004'**
  String get trustedPensionManagerSince2004;

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

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @underbanked.
  ///
  /// In en, this message translates to:
  /// **'Underbanked'**
  String get underbanked;

  /// No description provided for @underbankedAccount.
  ///
  /// In en, this message translates to:
  /// **'Underbanked Account'**
  String get underbankedAccount;

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

  /// No description provided for @unreadcountUnread.
  ///
  /// In en, this message translates to:
  /// **'{unreadCount} unread'**
  String unreadcountUnread(Object unreadCount);

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

  /// No description provided for @updatePin.
  ///
  /// In en, this message translates to:
  /// **'Update PIN'**
  String get updatePin;

  /// No description provided for @updateTransactionPin.
  ///
  /// In en, this message translates to:
  /// **'Update your transaction PIN'**
  String get updateTransactionPin;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

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

  /// No description provided for @upgradeSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Successful!'**
  String get upgradeSuccessful;

  /// No description provided for @upgradeTier.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Tier'**
  String get upgradeTier;

  /// No description provided for @upgradeToInfo.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {info}'**
  String upgradeToInfo(Object info);

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @upgradeToStandard.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Standard'**
  String get upgradeToStandard;

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

  /// No description provided for @upgradeToUnlockHigherLimits.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock higher limits'**
  String get upgradeToUnlockHigherLimits;

  /// No description provided for @upgradeToUnlockService.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock {service}'**
  String upgradeToUnlockService(Object service);

  /// No description provided for @upgradeYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Your Account'**
  String get upgradeYourAccount;

  /// No description provided for @uploadAClearPhotoOfYour.
  ///
  /// In en, this message translates to:
  /// **'• Upload a clear photo of your government-issued ID\n• Provide address verification document'**
  String get uploadAClearPhotoOfYour;

  /// No description provided for @uploadAClearPhotoOrScan.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo or scan of your government-issued ID.'**
  String get uploadAClearPhotoOrScan;

  /// No description provided for @uploadADocumentShowingYourCurrent.
  ///
  /// In en, this message translates to:
  /// **'Upload a document showing your current address, dated within the last 3 months.'**
  String get uploadADocumentShowingYourCurrent;

  /// No description provided for @uploadAddressProof.
  ///
  /// In en, this message translates to:
  /// **'Upload address proof'**
  String get uploadAddressProof;

  /// No description provided for @uploadCacCertificate.
  ///
  /// In en, this message translates to:
  /// **'Upload CAC Certificate'**
  String get uploadCacCertificate;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @uploadGovernmentIdPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload government ID photo'**
  String get uploadGovernmentIdPhoto;

  /// No description provided for @uploadRecentUtilityBillForAddress.
  ///
  /// In en, this message translates to:
  /// **'Upload recent utility bill for address verification'**
  String get uploadRecentUtilityBillForAddress;

  /// No description provided for @uploadValidIdCardsForAll.
  ///
  /// In en, this message translates to:
  /// **'Upload valid ID cards for all directors'**
  String get uploadValidIdCardsForAll;

  /// No description provided for @uploadYourCertificateOfIncorporation.
  ///
  /// In en, this message translates to:
  /// **'Upload your Certificate of Incorporation'**
  String get uploadYourCertificateOfIncorporation;

  /// No description provided for @useAccountNumberToLink.
  ///
  /// In en, this message translates to:
  /// **'Use your account number to link your existing RimaPay account.'**
  String get useAccountNumberToLink;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

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

  /// No description provided for @useYourRegisteredNameWhenTransferring.
  ///
  /// In en, this message translates to:
  /// **'Use your registered name when transferring'**
  String get useYourRegisteredNameWhenTransferring;

  /// No description provided for @userExampleCom.
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get userExampleCom;

  /// No description provided for @ussd.
  ///
  /// In en, this message translates to:
  /// **'USSD'**
  String get ussd;

  /// No description provided for @utilitiesServices.
  ///
  /// In en, this message translates to:
  /// **'Utilities & services'**
  String get utilitiesServices;

  /// No description provided for @utilityBill.
  ///
  /// In en, this message translates to:
  /// **'Utility Bill'**
  String get utilityBill;

  /// No description provided for @utilityBillBankStatementEtc.
  ///
  /// In en, this message translates to:
  /// **'Utility bill, bank statement, etc.'**
  String get utilityBillBankStatementEtc;

  /// No description provided for @validForPeriod.
  ///
  /// In en, this message translates to:
  /// **'Valid for {period}'**
  String validForPeriod(Object period);

  /// No description provided for @validForValidity.
  ///
  /// In en, this message translates to:
  /// **'Valid for {validity}'**
  String validForValidity(Object validity);

  /// No description provided for @validateAccountFirst.
  ///
  /// In en, this message translates to:
  /// **'Please validate account number first'**
  String get validateAccountFirst;

  /// No description provided for @verificationTypicallyTakes12Business.
  ///
  /// In en, this message translates to:
  /// **'Verification typically takes 1–2 business days. You will be notified once complete.'**
  String get verificationTypicallyTakes12Business;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @verifyArrow.
  ///
  /// In en, this message translates to:
  /// **'Verify →'**
  String get verifyArrow;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

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

  /// No description provided for @verifyYourIdentityWithYourNin.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity with your NIN or BVN'**
  String get verifyYourIdentityWithYourNin;

  /// No description provided for @verifyYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Phone'**
  String get verifyYourPhone;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

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

  /// No description provided for @viewAll2.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll2;

  /// No description provided for @viewAllRecentPurchases.
  ///
  /// In en, this message translates to:
  /// **'View All Recent Purchases'**
  String get viewAllRecentPurchases;

  /// No description provided for @viewBusinessInsights.
  ///
  /// In en, this message translates to:
  /// **'View business insights'**
  String get viewBusinessInsights;

  /// No description provided for @viewTransactionLimits.
  ///
  /// In en, this message translates to:
  /// **'View your transaction limits'**
  String get viewTransactionLimits;

  /// No description provided for @voluntaryPension.
  ///
  /// In en, this message translates to:
  /// **'Voluntary Pension'**
  String get voluntaryPension;

  /// No description provided for @voterSCard.
  ///
  /// In en, this message translates to:
  /// **'Voter\'s Card'**
  String get voterSCard;

  /// No description provided for @waecJambNecoMore.
  ///
  /// In en, this message translates to:
  /// **'WAEC, JAMB, NECO & more'**
  String get waecJambNecoMore;

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

  /// No description provided for @weLlNotifyYouWhenFunds.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when funds arrive'**
  String get weLlNotifyYouWhenFunds;

  /// No description provided for @weLlSendAOneTime.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a one-time code to confirm this change.'**
  String get weLlSendAOneTime;

  /// No description provided for @weLlSendAOneTime2.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a one-time code to your registered number to confirm the reset.'**
  String get weLlSendAOneTime2;

  /// No description provided for @weSentA6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to verify your {needsNin}. Check your registered phone number.'**
  String weSentA6DigitCode(Object needsNin);

  /// No description provided for @weSentACodeTo234.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to +234 {_phoneDigits}'**
  String weSentACodeTo234(Object _phoneDigits);

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

  /// No description provided for @welcomeNback.
  ///
  /// In en, this message translates to:
  /// **'Welcome\nBack 👋'**
  String get welcomeNback;

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

  /// No description provided for @welcomeValidatedfirstname.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {validatedFirstName}!'**
  String welcomeValidatedfirstname(Object validatedFirstName);

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

  /// No description provided for @whatCopied.
  ///
  /// In en, this message translates to:
  /// **'{what} copied'**
  String whatCopied(Object what);

  /// No description provided for @whatIsYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'What is your phone number?'**
  String get whatIsYourPhoneNumber;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @whereDoYouLive.
  ///
  /// In en, this message translates to:
  /// **'Where do you live?'**
  String get whereDoYouLive;

  /// No description provided for @whereIsYourBusinessLocated.
  ///
  /// In en, this message translates to:
  /// **'Where is your business located?'**
  String get whereIsYourBusinessLocated;

  /// No description provided for @whereToSendMoney.
  ///
  /// In en, this message translates to:
  /// **'Where would you like to send money?'**
  String get whereToSendMoney;

  /// No description provided for @withoutBvnOrNinYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Without BVN or NIN, your account will have limited features:\n• ₦10,000 daily transaction limit\n• No international transfers\n• You can upgrade anytime by adding your BVN/NIN later'**
  String get withoutBvnOrNinYourAccount;

  /// No description provided for @year1.
  ///
  /// In en, this message translates to:
  /// **'1 Year'**
  String get year1;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @yesContinue.
  ///
  /// In en, this message translates to:
  /// **'Yes, Continue'**
  String get yesContinue;

  /// No description provided for @youAreNowOnTheStandard.
  ///
  /// In en, this message translates to:
  /// **'You are now on the Standard Tier.\nYour new limits are active immediately.'**
  String get youAreNowOnTheStandard;

  /// No description provided for @youCanReceiveTransfersUsingYour.
  ///
  /// In en, this message translates to:
  /// **'You can receive transfers using your phone number or this account number'**
  String get youCanReceiveTransfersUsingYour;

  /// No description provided for @youEarned50CashbackFromYour.
  ///
  /// In en, this message translates to:
  /// **'You earned ₦50 cashback from your electricity bill payment. Total cashback this month: ₦350'**
  String get youEarned50CashbackFromYour;

  /// No description provided for @youHaveBeenVerified.
  ///
  /// In en, this message translates to:
  /// **'You Have Been Verified!'**
  String get youHaveBeenVerified;

  /// No description provided for @youReAboutToOpenA.
  ///
  /// In en, this message translates to:
  /// **'You\'re about to open a financial inclusion (underbanked) account. This account is designed for those without formal ID documents.'**
  String get youReAboutToOpenA;

  /// No description provided for @youReceived25000FromAdebayo.
  ///
  /// In en, this message translates to:
  /// **'You received ₦25,000 from Adebayo Okafor with reference: Split dinner bill'**
  String get youReceived25000FromAdebayo;

  /// No description provided for @yourAccountHasBeenCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created successfully.'**
  String get yourAccountHasBeenCreatedSuccessfully;

  /// No description provided for @yourAccountHasBeenSetUp.
  ///
  /// In en, this message translates to:
  /// **'Your account has been set up successfully'**
  String get yourAccountHasBeenSetUp;

  /// No description provided for @yourAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Your Account Number'**
  String get yourAccountNumber;

  /// No description provided for @yourAccountPasswordHasBeenUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your account password has been updated'**
  String get yourAccountPasswordHasBeenUpdated;

  /// No description provided for @yourAddressHasBeenSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your address has been saved successfully.'**
  String get yourAddressHasBeenSavedSuccessfully;

  /// No description provided for @yourAirtimePurchaseOf1000.
  ///
  /// In en, this message translates to:
  /// **'Your airtime purchase of ₦1,000 to 08012345678 was successful'**
  String get yourAirtimePurchaseOf1000;

  /// No description provided for @yourBusinessAccountHasBeenCreated.
  ///
  /// In en, this message translates to:
  /// **'Your business account has been created successfully.'**
  String get yourBusinessAccountHasBeenCreated;

  /// No description provided for @yourBusinessAccountIsNowActive.
  ///
  /// In en, this message translates to:
  /// **'Your business account is now active'**
  String get yourBusinessAccountIsNowActive;

  /// No description provided for @yourCurrentTierBasic.
  ///
  /// In en, this message translates to:
  /// **'Your Current Tier: Basic'**
  String get yourCurrentTierBasic;

  /// No description provided for @yourDeclarationHasBeenSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your declaration has been saved successfully.'**
  String get yourDeclarationHasBeenSavedSuccessfully;

  /// No description provided for @yourDedicatedAccount.
  ///
  /// In en, this message translates to:
  /// **'Your Dedicated Account'**
  String get yourDedicatedAccount;

  /// No description provided for @yourDepositsAre.
  ///
  /// In en, this message translates to:
  /// **'YOUR DEPOSITS ARE '**
  String get yourDepositsAre;

  /// No description provided for @yourDocumentsAreUnderReviewNwe.
  ///
  /// In en, this message translates to:
  /// **'Your documents are under review.\nWe\'ll notify you within 1–2 business days.'**
  String get yourDocumentsAreUnderReviewNwe;

  /// No description provided for @yourEmailHasBeenConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your email has been confirmed.'**
  String get yourEmailHasBeenConfirmed;

  /// No description provided for @yourFundsAreInsuredByNdic.
  ///
  /// In en, this message translates to:
  /// **'Your funds are insured by NDIC. Earn up to 13% per annum.'**
  String get yourFundsAreInsuredByNdic;

  /// No description provided for @yourIdentityHasBeenConfirmedNwelcome.
  ///
  /// In en, this message translates to:
  /// **'Your identity has been confirmed.\nWelcome to RimaPay!'**
  String get yourIdentityHasBeenConfirmedNwelcome;

  /// No description provided for @yourIncomeDetailsHaveBeenSaved.
  ///
  /// In en, this message translates to:
  /// **'Your income details have been saved successfully.'**
  String get yourIncomeDetailsHaveBeenSaved;

  /// No description provided for @yourNeedsninIsUsedSolelyFor.
  ///
  /// In en, this message translates to:
  /// **'Your {needsNin} is used solely for identity verification and is encrypted.'**
  String yourNeedsninIsUsedSolelyFor(Object needsNin);

  /// No description provided for @yourPasswordHasBeenUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated'**
  String get yourPasswordHasBeenUpdated;

  /// No description provided for @yourPasswordHasBeenUpdatedNsign.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated.\nSign in with your new password.'**
  String get yourPasswordHasBeenUpdatedNsign;

  /// No description provided for @yourPinIsEncryptedAndNever.
  ///
  /// In en, this message translates to:
  /// **'Your PIN is encrypted and never stored for security.'**
  String get yourPinIsEncryptedAndNever;

  /// No description provided for @yourProfileIsNowCompleteNwelcome.
  ///
  /// In en, this message translates to:
  /// **'Your profile is now complete.\nWelcome to RimaPay!'**
  String get yourProfileIsNowCompleteNwelcome;

  /// No description provided for @yourProfileIsNowFullyComplete.
  ///
  /// In en, this message translates to:
  /// **'Your profile is now fully complete.'**
  String get yourProfileIsNowFullyComplete;

  /// No description provided for @yourRimapayAccountIsNowLinked.
  ///
  /// In en, this message translates to:
  /// **'Your RimaPay account is now linked\nto this device.'**
  String get yourRimapayAccountIsNowLinked;

  /// No description provided for @yourTransactionPinHasBeenReset.
  ///
  /// In en, this message translates to:
  /// **'Your transaction PIN has been reset.'**
  String get yourTransactionPinHasBeenReset;

  /// No description provided for @yourTransactionPinHasBeenUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your transaction PIN has been updated.'**
  String get yourTransactionPinHasBeenUpdated;

  /// No description provided for @yourTransactionPinHasBeenUpdated2.
  ///
  /// In en, this message translates to:
  /// **'Your transaction PIN has been updated'**
  String get yourTransactionPinHasBeenUpdated2;

  /// No description provided for @yourTransactiontypeHasBeenProcessedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your {transactionType} has been processed successfully'**
  String yourTransactiontypeHasBeenProcessedSuccessfully(
      Object transactionType);

  /// No description provided for @yourWealthIsBelowTheNisab.
  ///
  /// In en, this message translates to:
  /// **'Your wealth is below the Nisab threshold — Zakat is not yet due.'**
  String get yourWealthIsBelowTheNisab;

  /// No description provided for @zakat.
  ///
  /// In en, this message translates to:
  /// **'Zakat'**
  String get zakat;

  /// No description provided for @zakatDue25.
  ///
  /// In en, this message translates to:
  /// **'Zakat Due (2.5%)'**
  String get zakatDue25;

  /// No description provided for @zakatReligious.
  ///
  /// In en, this message translates to:
  /// **'Zakat / Religious'**
  String get zakatReligious;
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
