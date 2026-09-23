// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for Hausa (`ha`).
class AppL10nHa extends AppL10n {
  AppL10nHa([String locale = 'ha']) : super(locale);

  @override
  String aFeeOfFeeWillBe(Object fee) {
    return 'Za a cire kuɗin sabis na $fee daga asusun.';
  }

  @override
  String get aPepPoliticallyExposedPersonIs =>
      'PEP (Mutum Mai Fice a Siyasa) shi ne wanda yake riƙe ko ya taɓa riƙe muhimmin muƙami na gwamnati, wanda hakan ke ba shi tasiri a kan kuɗaɗen jama\'a ko yanke shawara. Wannan ya haɗa da \'yan uwa da abokan kusa na irin waɗannan mutane.';

  @override
  String get aPepPoliticallyExposedPersonIs2 =>
      'PEP (Mutum Mai Fice a Siyasa) shi ne wanda yake riƙe ko ya taɓa riƙe muhimmin muƙami na gwamnati, wanda hakan ke ba shi tasiri a kan kuɗaɗen jama\'a ko yanke shawara.';

  @override
  String get aboutApp => 'Game da App';

  @override
  String get aboutRemitaPayments => 'Game da Biyan Remita';

  @override
  String get account => 'Asusun';

  @override
  String accountAccountnumber(Object accountNumber) {
    return 'Asusu: $accountNumber';
  }

  @override
  String get accountCreated => 'An Ƙirƙiri Asusu!';

  @override
  String get accountCreatedAndVerified =>
      'An ƙirƙiri asusunka kuma an tabbatar da shi cikin nasara';

  @override
  String get accountDetails => 'Bayanan Asusu';

  @override
  String get accountDetailsCopied => 'An kwafi bayanan asusu';

  @override
  String get accountLimits => 'Iyakokin Asusu';

  @override
  String get accountLinked => 'An Haɗa Asusu!';

  @override
  String get accountName => 'Sunan Asusu';

  @override
  String accountNoPrefix(Object number) {
    return 'Lambar Asusu $number';
  }

  @override
  String get accountNumber => 'Lambar Asusun';

  @override
  String get accountNumberCopied => 'An kwafi lambar asusu';

  @override
  String get accountNumberRequired => 'Ana buƙatar lambar asusun';

  @override
  String get accountTiers => 'Matakan Asusun';

  @override
  String get accountUnderReview => 'Ana Duba Asusu';

  @override
  String accountnumberBank(Object accountNumber, Object bank) {
    return '$accountNumber • $bank';
  }

  @override
  String get active => 'Yana Aiki';

  @override
  String get addMoney => 'Kara Kudi';

  @override
  String get addMoneyDesc => 'Cika jakar kudi';

  @override
  String get addMoneyToWallet => 'Kara Kuɗi ga Jaka';

  @override
  String get address => 'Adireshi';

  @override
  String get affordableIntercityTrips =>
      'Tafiye-tafiye masu araha tsakanin birane';

  @override
  String agencyDescription(Object agency, Object description) {
    return '$agency · $description';
  }

  @override
  String get agreeToTerms =>
      'Ta hanyar ci gaba, ka amince da Sharuɗɗan Sabis da Manufar Sirri';

  @override
  String get aidAndDonations => 'Tallafi da gudummawa';

  @override
  String get airtime => 'Airtime';

  @override
  String get airtimeAndDataBundles => 'Katin waya da bandunan data';

  @override
  String get airtimeDesc => 'Cika wayar';

  @override
  String get airtimePurchase => 'Sayen Katin Waya';

  @override
  String get airtimeToCash => 'Airtime zuwa Kuɗi';

  @override
  String get airtimeToCashDesc => 'Canza airtime';

  @override
  String get allDone => 'An Gama Komai!';

  @override
  String get allNetworks => 'Duk hanyoyin sadarwa';

  @override
  String get allRequirementsCompleted => 'An cika dukkan buƙatu';

  @override
  String get alreadyBankWithRima => 'Kana da asusu a Rima?';

  @override
  String get alreadyHaveAccount => 'Kana da asusun?';

  @override
  String get amount => 'Adadin';

  @override
  String amount2(Object amount) {
    return '₦$amount';
  }

  @override
  String get amountRequired => 'Ana buƙatar adadin';

  @override
  String amountcontrollerAirtime(Object _amountController) {
    return 'katin waya na ₦$_amountController';
  }

  @override
  String get anOtpWillBeSentTo =>
      'Za a aika OTP zuwa lambar wayar da aka yi rajista da ita don sake saita PIN na ma\'amala.';

  @override
  String get applyForLoan => 'Nemi Bashi';

  @override
  String get applyNow => 'Nemi Yanzu';

  @override
  String get approvePaymentsWithoutTypingYourPin =>
      'Amince da biyan kuɗi ba tare da buga PIN ba';

  @override
  String get approxValueOf85gOfGold =>
      ' (kusan darajar zinare gram 85). Adadin zakka: 2.5%.';

  @override
  String get areYouAPoliticallyExposedPerson =>
      'Shin kai/ke Mutum Mai Fice a Siyasa ne?';

  @override
  String get areYouAPoliticallyExposedPerson2 =>
      'Shin kai/ke Mutum Mai Fice a Siyasa ne ko ɗan uwa/abokin kusa na PEP?';

  @override
  String get areYouSureYouWantTo => 'Tabbatar da fita daga asusun RimaPay?';

  @override
  String get areYouSureYouWantTo2 => 'Tabbatar da fita daga asusun RimaPay?';

  @override
  String get authenticating => 'Ana tantancewa...';

  @override
  String get authorizedAndNregulatedBy =>
      'AN BA DA IZINI KUMA\nANA KULAWA DA SHI TA';

  @override
  String get autoRollover => 'Sabuntawa Kai Tsaye';

  @override
  String get automaticallyRenewAtMaturity =>
      'Sabunta kai tsaye idan lokaci ya cika';

  @override
  String get available => 'Akwai';

  @override
  String get availableBalance => 'Kudade da ake da su';

  @override
  String get availableEvents => 'Bukukuwan da Ake Da Su';

  @override
  String get axaGroupSubsidiaryInNigeria => 'Reshen AXA Group a Najeriya';

  @override
  String get back => 'Koma';

  @override
  String get backToHome => 'Koma Gida';

  @override
  String get backToSignIn => 'Koma Shiga';

  @override
  String get balance20000Per50000 =>
      'Ma\'ajiya ₦50,000 • ₦20,000 kowace ma\'amala';

  @override
  String get balanceCap => 'Iyakar Ma\'ajiya';

  @override
  String get balanceCap300000 => 'Iyakar ma\'ajiya: ₦300,000';

  @override
  String get balanceCap5000000After =>
      'Iyakar ma\'ajiya: ₦5,000,000 (bayan amincewa)';

  @override
  String get bank => 'Banki';

  @override
  String get bankAccount => 'Asusun Banki';

  @override
  String get bankDeposit => 'Ajiyar Banki';

  @override
  String get bankDepositLabel => 'Ajiyar banki';

  @override
  String get bankName => 'Sunan Banki';

  @override
  String get bankTransfer => 'Canja Banki';

  @override
  String get beneficiarySaved => 'An ajiye wanda ake aika wa cikin nasara';

  @override
  String get betting => 'Caca';

  @override
  String get bettingDesc => 'Wasannin motsa jiki da caca';

  @override
  String get billPaidSuccessfully => 'An biya bill cikin nasara';

  @override
  String get biometricAuth => 'Tabbatar da Biometric';

  @override
  String get biometricForTransactions => 'Biometric don Ma\'amaloli';

  @override
  String get biometricLogin => 'Shiga da Biometric';

  @override
  String get biometrics => 'Tantancewar Biometric';

  @override
  String get blockRequestNew => 'Toshe & Nemi Sabo';

  @override
  String get bookFlights => 'Yin rijistar jirgi';

  @override
  String get bookFlights2 => 'Yi Rijistar Jirgi';

  @override
  String get bookInterCityTravel => 'Yi rijistar tafiya tsakanin birane';

  @override
  String get builtWithInNigeria => 'An gina shi da ❤️ a Najeriya';

  @override
  String get bulkTransfer => 'Canja Wuri da Yawa';

  @override
  String get busTickets => 'Tikitin bas';

  @override
  String get busTickets2 => 'Tikitin Bas';

  @override
  String get businessAccount => 'Asusun Kasuwanci';

  @override
  String get businessAnalytics => 'Nazarin Kasuwanci';

  @override
  String get businessBalance => 'Ma\'ajiyar Kasuwanci';

  @override
  String get businessPremisesPhoto => 'Hoton Wurin Kasuwanci';

  @override
  String get businessServices => 'Ayyukan Kasuwanci';

  @override
  String get buyAirtimeAndDataBundles => 'Sayi katin waya da bandunan data';

  @override
  String get buyNow => 'Saya Yanzu';

  @override
  String get bvn => 'BVN';

  @override
  String bvnGetbvnlabel(Object _getBvnLabel) {
    return 'BVN $_getBvnLabel';
  }

  @override
  String get bvnVerification => 'Tabbatar da BVN';

  @override
  String get ca => 'CA';

  @override
  String get cableProviders => 'DSTV, GOtv, da sauransu';

  @override
  String get cableTV => 'Talabijin';

  @override
  String get cableTVDesc => 'Biyan kuɗin watanni';

  @override
  String get calculateAndPayYourZakat => 'Lissafa kuma biya zakka';

  @override
  String get callOrChatWithUs => 'Kira mu ko yi hira da mu';

  @override
  String get callUs => 'Kira Mu';

  @override
  String get cameraPreviewWillAppearHere => 'Hoton kyamara zai bayyana a nan';

  @override
  String get canNowUseDevice =>
      'Yanzu za ka iya amfani da wannan na\'ura don shiga asusunka.';

  @override
  String get cancel => 'Soke';

  @override
  String get candidateRegistrationNumber => 'Lambar Ɗan Takara / Rajista';

  @override
  String get captureSelfie => 'Ɗauki Hoton Kai';

  @override
  String cardFeeOfFeeWillBe(Object fee, Object deliveryDays) {
    return 'Za a cire kuɗin kati na $fee daga asusun. Za a kawo shi cikin kwanakin aiki $deliveryDays.';
  }

  @override
  String get cardPayment => 'Biyan kuɗi da kati';

  @override
  String get cardRequestSubmittedSuccessfully =>
      'An gabatar da neman kati cikin nasara!';

  @override
  String get cardSchemes => 'Visa, Mastercard, Verve';

  @override
  String get cards => 'Katuna';

  @override
  String get cardsComingSoon => 'Katuna suna zuwa nan ba da jimawa ba';

  @override
  String get cashbackEarned => 'Cashback da Aka Samu';

  @override
  String get cbnLicensed => 'CBN ta ba da lasisi kuma tana lura';

  @override
  String get cbnLicensedPensionFundAdministrator =>
      'Mai kula da asusun fensho mai lasisin CBN';

  @override
  String get cbnRegulatedTransactionLimits =>
      'Iyakokin ma\'amala bisa ƙa\'idar CBN';

  @override
  String get changeBiometric => 'Canja Biometric';

  @override
  String get changeLanguage => 'Canja Harshe';

  @override
  String get changeLanguageOneTap => 'Canja harshen app da dannawa ɗaya';

  @override
  String get changeLoginPin => 'Canja PIN na Shiga';

  @override
  String get changePassword => 'Canja Kalmar Sirri';

  @override
  String get changePhoto => 'Canja Hoto';

  @override
  String get changePin => 'Canja PIN';

  @override
  String get changeTransactionPin => 'Canja PIN na Ma\'amala';

  @override
  String get chooseANew4DigitPin => 'Zaɓi sabon PIN mai lamba 4';

  @override
  String get chooseAccountType => 'Zaɓi nau\'in asusun da ya dace da buƙatunka';

  @override
  String get chooseDataPlan => 'Zaɓi Tsarin Data';

  @override
  String get chooseNetwork => 'Zaɓi Hanyar Sadarwa';

  @override
  String get choosePaymentMethod => 'Zaɓi Hanyar Biya';

  @override
  String get chooseProvider => 'Zaɓi Mai Bayar da Sabis';

  @override
  String get chooseTransportOperator => 'Zaɓi Kamfanin Sufuri';

  @override
  String get city => 'Birni';

  @override
  String get close => 'Rufe';

  @override
  String get codeSentToYourRegisteredPhone =>
      'An aika lamba zuwa lambar wayar da aka yi rajista da ita';

  @override
  String get comfortClassOnWheels => 'Jin daɗi da ɗaukaka a kan hanya';

  @override
  String get comingSoon => 'Yana Zuwa';

  @override
  String get comingSoon2 => 'Yana zuwa';

  @override
  String comingSoonFeature(Object label) {
    return '$label yana zuwa nan ba da jimawa ba!';
  }

  @override
  String get completeLowerTiersFirst => 'Fara kammala ƙananan matakai';

  @override
  String get completeProfile => 'Kammala Bayanan Kai';

  @override
  String get completeRequiredDocumentsToActivateYour =>
      'Kammala takardun da ake buƙata don kunna asusun';

  @override
  String get completeYourProfile => 'Kammala Bayanan Kai';

  @override
  String get concertsShowsExperiences => 'Kaɗe-kaɗe, wasanni da nishaɗi';

  @override
  String get confirm => 'Tabbatar';

  @override
  String confirmAndPay(Object amount) {
    return 'Tabbatar & Biya $amount';
  }

  @override
  String get confirmPassword => 'Tabbatar da Kalmar Sirri';

  @override
  String get confirmPin => 'Tabbatar da PIN';

  @override
  String get confirmRequest => 'Tabbatar da Buƙata';

  @override
  String get confirmTransaction => 'Tabbatar da Ma\'amala';

  @override
  String get confirmYourEmail => 'Tabbatar da imel';

  @override
  String get confirmYourIdentity => 'Tabbatar da Shaidar Kai';

  @override
  String get confirmYourPin => 'Tabbatar da PIN';

  @override
  String get congratulations => 'Taya murna!';

  @override
  String get contacts => 'Lambobin';

  @override
  String get continueArrow => 'Ci gaba →';

  @override
  String get continueLabel => 'Ci gaba';

  @override
  String get continueToAccount => 'Ci gaba zuwa Asusu';

  @override
  String get contributionType => 'Nau\'in Gudummawa';

  @override
  String get conversionRate500Airtime40080 =>
      'Adadin musanya 80% · katin waya ₦500 = kuɗi ₦400';

  @override
  String get convertAirtimeToWalletBalance =>
      'Canja katin waya zuwa ma\'ajiyar kuɗi';

  @override
  String convertedamount(Object _convertedAmount) {
    return '₦$_convertedAmount';
  }

  @override
  String get convertsTo => 'ya koma';

  @override
  String get cooperativeName => 'Ƙungiyar Haɗin Kan Najeriya';

  @override
  String get copyAll => 'Kwafi Duka';

  @override
  String get copyAllDetails => 'Kwafi Dukkan Bayanai';

  @override
  String get corporateAccount => 'Asusun Kamfani';

  @override
  String get corporateAccountDesc => 'Ga kasuwanci da ƙungiyoyi';

  @override
  String get couldnTCreateTheReceiptPlease =>
      'An kasa ƙirƙirar rasit. A sake gwadawa.';

  @override
  String get couldnTLoadTransactions => 'An kasa loda ma\'amaloli';

  @override
  String get createAPin => 'Ƙirƙiri PIN';

  @override
  String get createAccount => 'Ƙirƙiri Asusun';

  @override
  String get createInvoice => 'Ƙirƙiri Takardar Biya';

  @override
  String get createPassword => 'Ƙirƙiri Kalmar Sirri';

  @override
  String get createPasswordToSecure =>
      'Ƙirƙiri kalmar sirri don tsare asusunka';

  @override
  String get createPin => 'Ƙirƙiri PIN';

  @override
  String get createTransactionPin => 'Ƙirƙiri PIN na Ma\'amala';

  @override
  String get createYourAccount => 'Ƙirƙiri Asusunka';

  @override
  String get currentAccount => 'Asusun Yanzu';

  @override
  String get currentPlan => 'Tsarin Yanzu';

  @override
  String get currentTier => 'Matsayin Yanzu';

  @override
  String get currentTier2 => 'MATAKIN YANZU';

  @override
  String currentidxLength(Object currentIdx, Object length) {
    return '$currentIdx/$length';
  }

  @override
  String currentidxTotalsteps(Object currentIdx, Object _totalSteps) {
    return '$currentIdx/$_totalSteps';
  }

  @override
  String get customerCare => 'Kula da Abokin Ciniki';

  @override
  String get customerNumber => 'Lambar Abokin ciniki';

  @override
  String get daily => 'Kullum';

  @override
  String dailyLimit(Object amount) {
    return 'Iyakar yau da kullun: $amount';
  }

  @override
  String get dailyLimitUsage => 'Yadda Ake Amfani da Iyakar Yau';

  @override
  String get dailyTransactionLimit => 'Iyakar Ma\'amala ta Yau da kullun';

  @override
  String get dailyTransfers100000 => 'Canja wuri na yau da kullun: ₦100,000';

  @override
  String get dailyTransfers1000000 => 'Canja wuri na yau da kullun: ₦1,000,000';

  @override
  String get darkMode => 'Yanayin Duhu';

  @override
  String get data => 'Data';

  @override
  String get dataBundle => 'Bandin Data';

  @override
  String get dataBundles => 'Bandunan data';

  @override
  String get dataDesc => 'Sayi tsare-tsare';

  @override
  String get dataPurchase => 'Sayen Data';

  @override
  String get date => 'Kwanan wata';

  @override
  String get dateAndTime => 'Kwanan Wata da Lokaci';

  @override
  String get dateOfBirth => 'Ranar Haihuwa';

  @override
  String get dateOfBirth2 => 'RANAR HAIHUWA';

  @override
  String dayMonthYear(Object day, Object month, Object year) {
    return '$day/$month/$year';
  }

  @override
  String get days30 => 'Kwana 30';

  @override
  String get days60 => 'Kwana 60';

  @override
  String get days90 => 'Kwana 90';

  @override
  String get debitCard => 'Katin Debit';

  @override
  String get debitCreditCard => 'Katin Debit / Credit';

  @override
  String get dedicatedAccountManager => 'Manajan asusu na musamman';

  @override
  String get delete => 'Share';

  @override
  String get deleteAccount => 'Share Asusun';

  @override
  String get deleteAccount2 => 'Share Asusu?';

  @override
  String deliveryDeliverydaysDays(Object deliveryDays) {
    return 'Kawowa: kwana $deliveryDays';
  }

  @override
  String get departure => 'Wurin tashi';

  @override
  String get depositCashAtBranch => 'Ajiye kuɗi a kowane reshen banki';

  @override
  String get description => 'Bayanin';

  @override
  String get destination => 'Wurin zuwa';

  @override
  String get deviceLinkedPleaseLogIn =>
      'An haɗa na\'ura cikin nasara. Ka shiga.';

  @override
  String get deviceLinkedSuccessfully => 'An Haɗa Na\'ura Cikin Nasara';

  @override
  String get dialCodeFromPhone => 'Buga lamba daga wayarka';

  @override
  String get didnTReceiveCode => 'Ba a karɓi lamba ba? ';

  @override
  String get didnTReceiveIt => 'Ba a karɓa ba? ';

  @override
  String get directorsIdCards => 'Katunan Shaida na Daraktoci';

  @override
  String get discoPayments => 'Biyan DISCO';

  @override
  String displaynameDisplayacct(Object displayName, Object displayAcct) {
    return '$displayName · $displayAcct';
  }

  @override
  String get dispute => 'Ƙorafi';

  @override
  String get disputeSubmitted =>
      'An gabatar da ƙorafi. Ƙungiyarmu za ta duba shi nan ba da jimawa ba.';

  @override
  String get documentType => 'Nau\'in Takarda';

  @override
  String get documentsSubmitted => 'An Gabatar da Takardu!';

  @override
  String get domesticFlightsAtBestPrices =>
      'Jiragen cikin gida a farashi mafi kyau';

  @override
  String get donateApply => 'Ba da Gudummawa / Nema';

  @override
  String get done => 'An gama';

  @override
  String get dontHaveAccount => 'Ba ka da asusun?';

  @override
  String get downloadPdfReceipt => 'Sauke Rasit na PDF';

  @override
  String get downloadReceipt => 'Sauke Rasit';

  @override
  String get driverSLicense => 'Lasisin Tuƙi';

  @override
  String get earnUpTo13PerAnnum => 'Samu har 13% a kowace shekara';

  @override
  String get edit => 'Gyara';

  @override
  String get editProfile => 'Gyara Bayanan Kai';

  @override
  String get education => 'Ilimi';

  @override
  String get educationDesc => 'Kuɗin makaranta da sauransu';

  @override
  String get electricity => 'Wutar Lantarki';

  @override
  String get electricityDesc => 'Biya kudade';

  @override
  String get email => 'Imel';

  @override
  String get emailAddress => 'ADIRESHIN IMEL';

  @override
  String get emailNotifications => 'Sanarwar Imel';

  @override
  String get emailOrPhone => 'Imel ko Waya';

  @override
  String get emailVerified => 'An tabbatar da imel!';

  @override
  String get ensureGoodLighting => 'Tabbatar da akwai haske sosai';

  @override
  String get enterAmount => 'Shigar da Adadin';

  @override
  String get enterDescription => 'Shigar da bayanin (ba lallai ba)';

  @override
  String get enterEmail => 'Shigar da Imel';

  @override
  String get enterLinkedPhone =>
      'Shigar da lambar wayar da ke haɗe da asusunka na RimaPay.';

  @override
  String get enterNickname => 'Shigar da laƙabi';

  @override
  String get enterOtp => 'Shigar da OTP';

  @override
  String get enterOtpCode => 'Shigar da lambar OTP';

  @override
  String get enterOtpSentToYourPhone => 'Shigar da OTP da aka aika zuwa wayar';

  @override
  String get enterPassword => 'Shigar da Kalmar Sirri';

  @override
  String get enterPin => 'Shigar da PIN';

  @override
  String get enterResetNcode => 'Shigar da lambar\nsake saitawa';

  @override
  String get enterRrn => 'Shigar da RRN';

  @override
  String get enterTheCodeSentToYour =>
      'Shigar da lambar da aka aika zuwa lambar wayar da aka yi rajista da ita.';

  @override
  String get enterTheEmailOrPhoneNumber =>
      'Shigar da imel ko lambar wayar da ke kan asusun, za mu aika lambar sake saitawa.';

  @override
  String get enterTheOtp => 'Shigar da OTP';

  @override
  String get enterTheVerificationTokenSentTo =>
      'Shigar da lambar tabbatarwa da aka aika zuwa adireshin imel don kunna asusun.';

  @override
  String get enterTransactionPin => 'Shigar da PIN na Ma\'amala';

  @override
  String get enterValidTenDigitPhone =>
      'Shigar da lambar waya mai lamba 10 daidai';

  @override
  String get enterVerificationCode => 'Shigar da lambar tabbatarwa';

  @override
  String get enterVerificationCode2 => 'Shigar da Lambar Tabbatarwa';

  @override
  String get enterYour4DigitPin => 'Shigar da PIN mai lamba 4';

  @override
  String get enterYour4DigitPinTo =>
      'Shigar da PIN mai lamba 4 don amincewa da wannan ma\'amala';

  @override
  String get enterYourBusinessEmailAddress =>
      'Shigar da adireshin imel na kasuwancin';

  @override
  String get enterYourDetailsToGetStarted => 'Shigar da bayanai don farawa';

  @override
  String enterYourRrnForS(Object s) {
    return 'Shigar da RRN don $s';
  }

  @override
  String get errorOccurred => 'Kuskure ya faru';

  @override
  String errorPickingFileE(Object e) {
    return 'Kuskure wajen zaɓar fayil: $e';
  }

  @override
  String errorPickingImageE(Object e) {
    return 'Kuskure wajen zaɓar hoto: $e';
  }

  @override
  String get eventTickets => 'Tikitin Taron';

  @override
  String get eventTicketsDesc => 'Fim da wasan kwaikwayo';

  @override
  String get events => 'Bukukuwa';

  @override
  String get examBodies => 'WAEC, JAMB, NECO';

  @override
  String get examBody => 'Hukumar Jarabawa';

  @override
  String get examType => 'Nau\'in Jarabawa';

  @override
  String expiresAtOtpexpiresat(Object otpExpiresAt) {
    return 'Zai ƙare a $otpExpiresAt';
  }

  @override
  String get faceVerification => 'Tantance Fuska';

  @override
  String get faceVerifiedSuccessfully => 'An tabbatar da fuska cikin nasara!';

  @override
  String get failed => 'Ya kasa';

  @override
  String get faqsAndSupport => 'Tambayoyi da tallafin abokin ciniki';

  @override
  String get fee => 'Kuɗin sabis';

  @override
  String get feeApplies => 'Akwai kuɗin sabis';

  @override
  String feeFee(Object fee) {
    return 'Kuɗin sabis: $fee';
  }

  @override
  String get filterTransactions => 'Tace Ma\'amaloli';

  @override
  String get finish => 'Gama';

  @override
  String get firstBankCustodian => 'First Bank Custodian';

  @override
  String get firstName => 'Sunan Farko';

  @override
  String get fixedDeposit => 'Ajiya Tsayayya';

  @override
  String get fixedFee => 'Kuɗin Sabis Tsayayye';

  @override
  String fixedamount(Object fixedAmount) {
    return '₦$fixedAmount';
  }

  @override
  String fixedamount2(Object _fixedAmount) {
    return '₦$_fixedAmount';
  }

  @override
  String get flights => 'Jirage';

  @override
  String forgotIdtype(Object _idType) {
    return 'An manta $_idType?';
  }

  @override
  String get forgotPassword => 'Ka manta da kalmar sirri?';

  @override
  String get forgotPinResetHere => 'Ka manta PIN? Sake saita shi anan';

  @override
  String get freeInstant => 'Kyauta · Nan take';

  @override
  String get freeNoInternet => 'Kyauta · Ba sai intanet ba';

  @override
  String get freeOneToThreeHours => 'Kyauta · Awa 1–3';

  @override
  String get frequentBeneficiaries => 'Waɗanda Ake Aika Wa Akai-akai';

  @override
  String get from => 'Daga';

  @override
  String get fullAddress => 'Cikakken Adireshi';

  @override
  String get fullName => 'Cikakken Suna';

  @override
  String get fundWallet => 'Cika Jaka';

  @override
  String get fundYourAccount => 'Cika asusun';

  @override
  String get fundYourWallet => 'Cika ma\'ajiyarka ta RimaPay';

  @override
  String get fundsReflectInstantlyAfterTransfer =>
      'Kuɗi na shiga nan take bayan canja wuri';

  @override
  String get gender => 'Jinsi';

  @override
  String get gender2 => 'JINSI';

  @override
  String get generatePaymentLinks => 'Ƙirƙiri hanyoyin biyan kuɗi';

  @override
  String get generateProfessionalInvoices =>
      'Ƙirƙiri takardun biya na ƙwararru';

  @override
  String get getAlertsForTransactions => 'Karɓi sanarwa kan ma\'amaloli';

  @override
  String get getLoansToday => 'Sami Bashi Yau';

  @override
  String get getStarted => 'Fara';

  @override
  String get go => 'Je';

  @override
  String get goHome => 'Koma Gida';

  @override
  String get goToDashboard => 'Je Dashboard';

  @override
  String get goToHome => 'Je Gida';

  @override
  String get goodAfternoon => 'Barka da yamma ✨';

  @override
  String get goodEvening => 'Barka da maraice ✨';

  @override
  String get goodMorning => 'Barka da safiya ✨';

  @override
  String get goodMorning2 => 'Barka da safiya';

  @override
  String get gotIt => 'Na gane';

  @override
  String get govPayments => 'Biyan Gwamnati';

  @override
  String get government => 'Gwamnati';

  @override
  String get governmentDesc => 'Haraji da izini';

  @override
  String get governmentId => 'Shaidar Gwamnati';

  @override
  String get governmentIdDocument => 'Takardar Shaidar Gwamnati';

  @override
  String get governmentInstitutionalPayments => 'Biyan gwamnati da cibiyoyi';

  @override
  String get governmentIssuedId => 'Shaida da Gwamnati Ta Bayar';

  @override
  String get governmentService => 'Sabis na Gwamnati';

  @override
  String get governmentServices => 'Ayyukan Gwamnati';

  @override
  String get govtPayments => 'Biyan gwamnati';

  @override
  String get grants => 'Tallafi';

  @override
  String get grantsDonations => 'Tallafi & Gudummawa';

  @override
  String get great => 'Madalla!';

  @override
  String get greetingAfternoon => 'Barka da rana';

  @override
  String get greetingEvening => 'Barka da maraice';

  @override
  String get greetingMorning => 'Barka da safiya';

  @override
  String get helpSupport => 'Taimako & Tallafi';

  @override
  String get hideLabel => 'Ɓoye';

  @override
  String get holdOnAMoment => 'Ka jira ɗan lokaci ...';

  @override
  String get holdOnAMomentThisCan =>
      'A jira ɗan lokaci — wannan na iya ɗaukar ɗan daƙiƙa.\nKada a rufe ko a sabunta shafin.';

  @override
  String get holdOnAMomentU2014This =>
      'A jira ɗan lokaci — wannan na iya ɗaukar ɗan daƙiƙa.\nKada a rufe ko a sabunta shafin.';

  @override
  String get home => 'Gida';

  @override
  String get iVeSentTheMoney => 'Na Aika Kuɗin';

  @override
  String get idVerification => 'Tabbatar da ID';

  @override
  String get instantTransfersToAnyBank => 'Canja kuɗi nan take';

  @override
  String get institution => 'Cibiya';

  @override
  String insufficientBalanceIs(Object balance) {
    return 'Kuɗi bai isa ba. Ma\'ajiyarka ita ce $balance.';
  }

  @override
  String get insufficientFunds => 'Kuɗi ba su isa ba';

  @override
  String get insuredByNdic => 'NDIC ya yi masa inshora';

  @override
  String get internationalPassport => 'Fasfo na Ƙasa da Ƙasa';

  @override
  String get internet => 'Intanet';

  @override
  String get internetProviders => 'Spectranet, Smile';

  @override
  String get internetServices => 'Ayyukan Intanet';

  @override
  String get invalidAccountNumber => 'Lambar asusun mara inganci';

  @override
  String get invalidAmount => 'Adadin mara inganci';

  @override
  String get invalidPhoneNumber => 'Lambar waya mara inganci';

  @override
  String get invalidPin => 'PIN mara inganci. Ka sake gwadawa.';

  @override
  String get invoiceInv2024001 => 'Takardar Biya #INV-2024-001';

  @override
  String itemfeeFee(Object itemFee) {
    return '+₦$itemFee kuɗin sabis';
  }

  @override
  String get kycVerification => 'Tabbatar da KYC';

  @override
  String labelCopied(Object label) {
    return 'An kwafi $label';
  }

  @override
  String get language => 'Harshe';

  @override
  String get languageChanged => 'An sabunta harshe';

  @override
  String get largestPfaInNigeriaByAum => 'Babban PFA a Najeriya bisa AUM';

  @override
  String get lastName => 'Sunan Ƙarshe';

  @override
  String get lastUsed => 'An yi amfani da shi karshe';

  @override
  String get leadwayGroupPensionArm => 'Reshen fensho na Leadway Group';

  @override
  String length(Object length) {
    return '$length';
  }

  @override
  String lengthFlightsFoundCodeCode2(Object length, Object code, Object code2) {
    return 'An samu jirage $length · $code → $code2';
  }

  @override
  String lengthLength2(Object length, Object length2) {
    return '$length/$length2';
  }

  @override
  String get lga => 'Ƙaramar Hukuma';

  @override
  String get licensedByCbn => 'CBN ya ba da lasisi';

  @override
  String get licensedByPencom => 'PenCom ya ba da lasisi';

  @override
  String get licensedByTheCbn => 'CBN ya ba da lasisi';

  @override
  String get limitsAreSetInAccordanceWith =>
      'An saita iyakoki bisa ƙa\'idojin CBN na bankunan microfinance. Haɓaka matakin asusun don ƙara iyakoki.';

  @override
  String get linkAccount => 'Haɗa Asusu';

  @override
  String get linkExistingAccount => 'Haɗa asusun da ake da shi';

  @override
  String get linkExistingAccountTitle => 'Haɗa Asusun da Ake da Shi';

  @override
  String get linkThisDevice => 'Haɗa wannan na\'ura';

  @override
  String get linkYourDevice => 'Haɗa Na\'urarka';

  @override
  String get linkedToCooperative => 'Haɗe da: Ƙungiyar Haɗin Kan Najeriya';

  @override
  String get loadingPaymentDetails => 'Ana loda bayanan biyan kuɗi…';

  @override
  String get loadingPlans => 'Ana loda tsare-tsare…';

  @override
  String get loadingProviders => 'Ana loda masu bayar da sabis…';

  @override
  String get loanComingSoon => 'Neman rance yana zuwa nan ba da jimawa ba!';

  @override
  String loanPitch(Object amount) {
    return 'Samu har $amount da ƙarancin riba. Amincewa cikin sauri.';
  }

  @override
  String get loanServicesAreNowAvailableIn =>
      'Ayyukan rance yanzu suna nan a cikin app ɗin RimaPay. Nemi rance nan take har ₦500,000';

  @override
  String get loans => 'Rancen Kudi';

  @override
  String get loansDesc => 'Saurin amincewa';

  @override
  String get logOut => 'Fita';

  @override
  String get logOut2 => 'Fita?';

  @override
  String get logout => 'Fita';

  @override
  String get logoutConfirmation => 'Tabbatar da Fita';

  @override
  String get markAllRead => 'Yi wa duka alamar karantawa';

  @override
  String get markAsFavorite => 'Yi Alama a Matsayin Fifiko';

  @override
  String get markRead => 'Yi alamar karantawa';

  @override
  String get max10TicketsPerOrder => 'Mafi yawa tikiti 10 kowane oda';

  @override
  String get max4PerBooking => 'Mafi yawa 4 kowace rijista';

  @override
  String get meterNumber => 'Lambar Mita';

  @override
  String methodComingSoon(Object method) {
    return '$method yana zuwa nan ba da jimawa ba';
  }

  @override
  String get min50Max50000 => 'Mafi ƙaranci: ₦50, Mafi yawa: ₦50,000';

  @override
  String get minEightCharacters => 'Mafi ƙaranci haruffa 8';

  @override
  String minMaxAmount(Object min, Object max) {
    return 'Mafi ƙaranci: $min, Mafi yawa: $max';
  }

  @override
  String get minimum10000 => 'Mafi ƙaranci: ₦10,000';

  @override
  String minimumAmount(Object amount) {
    return 'Mafi ƙarancin adadin shine $amount';
  }

  @override
  String get minimumTransfer100 => 'Mafi ƙarancin canja wuri: ₦100';

  @override
  String get mobileTopUp => 'Cika Wayar Hannu';

  @override
  String get modernFleetNationwide => 'Motoci na zamani a faɗin ƙasar';

  @override
  String get monFri8am8pmNsat9am =>
      'Litinin – Jumma\'a: 8 na safe – 8 na dare\nAsabar: 9 na safe – 5 na yamma';

  @override
  String get moneyReceived => 'An Karɓi Kuɗi';

  @override
  String get monthly => 'Kowane wata';

  @override
  String get monthlySubscription => 'Biyan kuɗi na wata-wata';

  @override
  String get monthlyTransactionLimit => 'Iyakar Ma\'amala ta Wata';

  @override
  String get months6 => 'Wata 6';

  @override
  String get more => 'Ƙari';

  @override
  String get moreInfo => 'Ƙarin Bayani';

  @override
  String get moreServices => 'Wasu Hidimomi';

  @override
  String get moreServicesDesc => 'Duk sabis na biyan kuɗi';

  @override
  String get multipleTransfersAtOnce => 'Canja wuri da yawa lokaci ɗaya';

  @override
  String get mustBeAtLeast8Characters =>
      'Dole ya kasance aƙalla haruffa 8 tare da babban baƙi, ƙaramin baƙi, lamba da alama ta musamman';

  @override
  String get myCard => 'Katina';

  @override
  String get myNumber => 'Lambata';

  @override
  String get myToDos => 'Ayyukana';

  @override
  String get needALoan => 'Kana Buƙatar Rance?';

  @override
  String get needTransactionPinToSend =>
      'Kana buƙatar ƙirƙiri PIN na ma\'amala kafin ka iya aika kuɗi.';

  @override
  String get network => 'Hanyar sadarwa';

  @override
  String get networkError => 'Kuskuren hanyar sadarwa. Ka sake gwadawa.';

  @override
  String get newDeviceLoginDetectedFromLagos =>
      'An gano shiga daga sabuwar na\'ura a Legas, Najeriya. Idan ba kai/ke ba ne, a tsare asusun.';

  @override
  String get newFeatureAvailable => 'Akwai Sabon Fasali';

  @override
  String get newLabel => 'SABO';

  @override
  String get newPassword => 'Sabuwar Kalmar Sirri';

  @override
  String get newPhone => 'Sabon waya?';

  @override
  String get newToRimaPay => 'Sabo ne a RimaPay?';

  @override
  String get next => 'Na gaba';

  @override
  String get nicknameOptional => 'Laƙabi (Na Zaɓi)';

  @override
  String get nin => 'NIN';

  @override
  String ninGetninlabel(Object _getNinLabel) {
    return 'NIN $_getNinLabel';
  }

  @override
  String get ninSlip => 'Takardar NIN';

  @override
  String get nisabThreshold => 'Ma\'aunin nisab: ';

  @override
  String get noPlansAvailable => 'Babu tsare-tsaren da ake da su';

  @override
  String get noPlansAvailableRetry =>
      'Babu tsare-tsare. A danna don sake gwadawa.';

  @override
  String get noProvidersAvailable =>
      'Babu masu bayar da sabis yanzu. A danna don sake gwadawa.';

  @override
  String get noTransactionsYet => 'Babu ma\'amaloli tukuna';

  @override
  String get noteOptional => 'Bayani (na zaɓi)';

  @override
  String get notifications => 'Sanarwa';

  @override
  String number(Object number) {
    return '$number...';
  }

  @override
  String get numberOfPassengers => 'Adadin Fasinjoji';

  @override
  String get numberOfTickets => 'Adadin Tikiti';

  @override
  String get openAnNaccount => 'Buɗe\nAsusu';

  @override
  String get openUnderbankedAccount =>
      'Buɗe Asusun Marasa Cikakken Sabis na Banki?';

  @override
  String get optional => 'Ba lallai ba';

  @override
  String get or => 'ko';

  @override
  String get otpSentToYourRegisteredNumber =>
      'An aika OTP zuwa lambar da aka yi rajista da ita';

  @override
  String get pageNotFound => 'Ba a Samu Shafin Ba';

  @override
  String get partOfFidelityBankGroup => 'Wani ɓangare na Fidelity Bank Group';

  @override
  String get passengers => 'Fasinjoji';

  @override
  String passengers2(Object _passengers) {
    return '$_passengers';
  }

  @override
  String get password => 'Kalmar Sirri';

  @override
  String get passwordChanged => 'An Canja Kalmar Sirri!';

  @override
  String get passwordChangedSuccessfully =>
      'An Canja Kalmar Sirri Cikin Nasara';

  @override
  String get passwordRequirements =>
      'Haruffa 8 tare da babban baƙi, ƙaramin baƙi da lamba';

  @override
  String get passwordReset => 'An sake saita kalmar sirri!';

  @override
  String get payBills => 'Biya Kuɗaɗe';

  @override
  String get payBillsManageServices => 'Biya kuɗi da sarrafa ayyuka';

  @override
  String get payCableTvSubscriptions => 'Biya kuɗin talabijin na kebul';

  @override
  String get payElectricityBills => 'Biya kuɗin wutar lantarki';

  @override
  String get payNow => 'Biya Yanzu';

  @override
  String get payWithBiometrics => 'Biya da Biometric';

  @override
  String payZakatZakatdue(Object _zakatDue) {
    return 'Biya Zakka ($_zakatDue)';
  }

  @override
  String get paymentAmount => 'Adadin Biyan Kuɗi';

  @override
  String get paymentCompleted => 'An kammala biyan kuɗi';

  @override
  String get paymentSuccessful => 'An Biya Cikin Nasara';

  @override
  String get paymentSuccessfulCelebrate => 'An Biya Cikin Nasara! 🎉';

  @override
  String get paymentsAreForwardedDirectlyToThe =>
      'Ana tura biyan kuɗi kai tsaye zuwa hukumar gwamnati da abin ya shafa';

  @override
  String get payroll => 'Albashi';

  @override
  String get pencomRegulatedContributions => 'Gudummawa bisa ƙa\'idar PenCom';

  @override
  String get pending => 'Ana jira';

  @override
  String get pension => 'Pension';

  @override
  String get pensionDesc => 'Gudummawar son rai';

  @override
  String get pensionFundAdministrator => 'Mai Kula da Asusun Fensho';

  @override
  String get pepDeclaration => 'Sanarwar PEP';

  @override
  String get perDay => 'Kowace Rana';

  @override
  String get perPerson => '/mutum';

  @override
  String get perTicket => '/tikiti';

  @override
  String percent(Object percent) {
    return '$percent%';
  }

  @override
  String get personalAccount => 'Asusun Kai';

  @override
  String get personalAccountDesc =>
      'Ga daidaikun mutane — aika, karɓa da biyan kuɗi';

  @override
  String get phone => 'Waya';

  @override
  String get phoneNumber => 'Lambar Waya';

  @override
  String get phoneNumber2 => 'LAMBAR WAYA';

  @override
  String get phoneTransfer => 'Canja ta Waya';

  @override
  String get pinChanged => 'An canja PIN!';

  @override
  String get pinChangedSuccessfully => 'An Canja PIN Cikin Nasara';

  @override
  String get pinFourToEightDigits => 'PIN (lamba 4-8)';

  @override
  String get pinReset => 'An sake saita PIN!';

  @override
  String get placeFixedDeposit => 'Yi Ajiya Tsayayya';

  @override
  String get plan => 'Tsari';

  @override
  String planBlurb(Object data, Object price, Object validity) {
    return 'Samu $data kan $price. Yana aiki na $validity';
  }

  @override
  String get planDuration => 'Tsawon Tsari';

  @override
  String get pleaseEnterAComplete10Digit =>
      'A shigar da cikakkiyar lambar waya mai lamba 10';

  @override
  String get pleaseEnterYourAddress => 'A shigar da adireshi';

  @override
  String get pleaseEnterYourLga => 'A shigar da ƙaramar hukuma';

  @override
  String get pleaseHoldStill => 'Ka tsaya cak';

  @override
  String get pleaseProvideYourOwnBvnNin =>
      'A bayar da BVN/NIN na kai don tabbatar da buƙatar buɗe asusu';

  @override
  String get pleaseReEnterYourDetailsTo =>
      'A sake shigar da bayanai don tabbatarwa';

  @override
  String get pleaseSelectAnOption => 'A zaɓi wani abu';

  @override
  String get pleaseSelectOccupationAndIncome => 'A zaɓi sana\'a da samun kuɗi';

  @override
  String get pleaseSelectYourState => 'A zaɓi jiha';

  @override
  String get pleaseWaitWhileWeProcessYour =>
      'A jira yayin da muke gudanar da sayen data...';

  @override
  String get popular => 'Sananne';

  @override
  String get positionYourFaceInTheOval => 'A ajiye fuska a cikin da\'irar';

  @override
  String get postpaid => 'Biya Daga Baya';

  @override
  String get preferences => 'Zaɓuɓɓuka';

  @override
  String get premiumInterstateTravel => 'Tafiya tsakanin jihohi ta ɗaukaka';

  @override
  String get prepaid => 'Biya Gaba';

  @override
  String price(Object price) {
    return '₦$price';
  }

  @override
  String priceperseatSeat(Object pricePerSeat) {
    return '₦$pricePerSeat/wuri';
  }

  @override
  String get priorityCustomerSupport => 'Tallafin abokin ciniki na fifiko';

  @override
  String priorityPriority2(Object priority, Object priority2) {
    return '$priority$priority2';
  }

  @override
  String get privacy => 'Sirri';

  @override
  String get proceed => 'Ci gaba';

  @override
  String get proceedArrow => 'Ci gaba →';

  @override
  String get processedSecurelyBy =>
      'RimaPay ya gudanar da ma\'amala cikin aminci';

  @override
  String get processing => 'Ana aiki...';

  @override
  String get processingPayment => 'Ana Gudanar da Biyan Kuɗi';

  @override
  String get profile => 'Bayani';

  @override
  String get profileCompleted => 'An Kammala Bayanan Kai!';

  @override
  String get profileUpdated => 'An sabunta bayanan kai';

  @override
  String get proofOfAddress => 'Shaidar Adireshi';

  @override
  String get protected => 'AN TSARE';

  @override
  String get provideDetailsOfYourSourceOf =>
      'A bayar da bayanan hanyar samun kuɗi';

  @override
  String get provideEitherBvnOrNinOnly =>
      '• A bayar da BVN KO NIN (ɗaya kawai ake buƙata)\n• A kammala tabbatarwar OTP';

  @override
  String get provideYourBvnOrNinIf =>
      'A bayar da BVN ko NIN idan akwai. Wannan matakin na zaɓi ne ga asusun marasa cikakken sabis na banki.';

  @override
  String providernamePackages(Object providerName) {
    return 'Tsare-tsaren $providerName';
  }

  @override
  String get pushNotifications => 'Sanarwar Turawa';

  @override
  String get qualityPensionManagement => 'Ingantaccen kula da fensho';

  @override
  String quantity(Object _quantity) {
    return '$_quantity';
  }

  @override
  String get questionsContactSupportRimapayCom =>
      'Tambayoyi? A tuntuɓi support@rimapay.com';

  @override
  String get quickAccessFutureTransfers => 'Samun sauƙi don canja wurin gaba';

  @override
  String get quickActions => 'Saurin Ayyuka';

  @override
  String get quickApprovalProcess => 'Saurin amincewa';

  @override
  String get quickSelectAmount => 'Zaɓi Adadi Da Sauri';

  @override
  String get quickServices => 'Ayyuka Masu Sauri';

  @override
  String rate(Object rate) {
    return '$rate%';
  }

  @override
  String ratePA(Object rate) {
    return '$rate% kowace shekara';
  }

  @override
  String get reEnterPassword => 'Sake shigar da kalmar sirrinka';

  @override
  String get reEnterYour4DigitPin =>
      'A sake shigar da PIN mai lamba 4 don tabbatarwa';

  @override
  String get receipt => 'Rasit';

  @override
  String get receiptCopiedToClipboard => 'An kwafi rasit';

  @override
  String get receiptDownloaded => 'An sauke rasitin cikin nasara';

  @override
  String get receiptGeneratedNote =>
      'App ɗin RimaPay ne ya ƙirƙiri wannan rasit. A ajiye Lambar Ma\'amala domin kowace tambaya.';

  @override
  String get receiptShared => 'An raba rasitin cikin nasara';

  @override
  String get recent => 'Kwanakin baya';

  @override
  String get recentActivity => 'Ayyukan Kwanakin Baya';

  @override
  String get recentPurchases => 'Sayayyar Kwanan Nan';

  @override
  String get recentRecipients => 'Masu karɓa na kwanakin baya';

  @override
  String get recentTransactions => 'Ma\'amaloli na Kwanan Nan';

  @override
  String get recipient => 'Mai karɓa';

  @override
  String get reference => 'Tunani';

  @override
  String get referenceCopiedToClipboard => 'An kwafi lambar shaida';

  @override
  String get registerDeviceToAccount => 'Yi rajistar wannan na\'ura a asusunka';

  @override
  String get registeredNumberCanTBeChanged =>
      'Lambar da aka yi rajista — ba za a iya canja ta ba. Mutane na samun ku ta wannan.';

  @override
  String get regulatedByPencomContributionsAreTax =>
      'PenCom ke kula da shi · Ana cire gudummawa daga haraji';

  @override
  String get religiousPayment => 'Biyan addini';

  @override
  String get remita => 'Remita';

  @override
  String get repeat => 'Maimaita';

  @override
  String get repeatTransaction => 'Maimaita Ma\'amala';

  @override
  String get replaceCard => 'Maye gurbin kati';

  @override
  String get requestAPhysicalDebitCard => 'Nemi katin debit na zahiri';

  @override
  String get requestCard => 'Nemi Kati';

  @override
  String requestFailedStatuscode(Object statusCode) {
    return 'Buƙata ta gaza ($statusCode).';
  }

  @override
  String get requestPayment => 'Nemi Biyan Kuɗi';

  @override
  String requestSelectedcard(Object _selectedCard) {
    return 'Nemi $_selectedCard?';
  }

  @override
  String get resendCode => 'Sake Aika Lamba';

  @override
  String get resendCode2 => 'Sake aika lamba';

  @override
  String resendCodeIn(Object seconds) {
    return 'Sake aika lamba cikin daƙiƙa $seconds';
  }

  @override
  String get resendOtp => 'Sake Aika OTP';

  @override
  String get resetCode => 'Lambar Sake Saitawa';

  @override
  String get resetPassword => 'Sake Saita Kalmar Sirri';

  @override
  String get resetTransactionPin => 'Sake Saita PIN na Ma\'amala';

  @override
  String get resetYourNpassword => 'Sake saita\nkalmar sirri';

  @override
  String get residentialAddress => 'Adireshin Zama';

  @override
  String get retrieveYourPaymentDetailsUsingThe =>
      'A dawo da bayanan biyan kuɗi ta hanyar Lambar Dawo da Remita';

  @override
  String get retry => 'Sake gwadawa';

  @override
  String get returnDate => 'Ranar komawa';

  @override
  String get returnLabel => 'Komawa';

  @override
  String get reviewSubmit => 'Duba & Gabatar';

  @override
  String get reviewTheDocumentsYouUploadedBefore =>
      'A duba takardun da aka ɗora kafin a gabatar don tabbatarwa.';

  @override
  String get rimaMfb => 'RIMA MFB';

  @override
  String get rimapayAccountOrPhone => 'Asusun RimaPay / Waya';

  @override
  String rimapayAccountcontroller(Object _accountController) {
    return 'RimaPay · $_accountController';
  }

  @override
  String rimapayReceiptReference(Object reference) {
    return 'Rasit na RimaPay $reference';
  }

  @override
  String get rimapayV210 => 'RimaPay v2.1.0';

  @override
  String get route => 'Hanya';

  @override
  String get rsaPin => 'PIN na RSA';

  @override
  String get safeReliableJourneys => 'Tafiye-tafiye masu aminci da dogaro';

  @override
  String get save => 'Ajiye';

  @override
  String get saveBeneficiary => 'Ajiye Mai karɓa';

  @override
  String get saveChanges => 'Ajiye Canje-canje';

  @override
  String get savedBeneficiaries => 'Masu karɓa da aka ajiye';

  @override
  String get scanQRCode => 'Duba Lambar QR';

  @override
  String get scanToTransfer => 'Duba lambar QR don canja wurin';

  @override
  String get scheduledMaintenanceOnSunday2am4am =>
      'An shirya gyara a ranar Lahadi 2AM - 4AM. Wasu ayyuka na iya tsayawa na ɗan lokaci.';

  @override
  String get searchAddress => 'Nemo Adireshi';

  @override
  String get searchBanks => 'Nemo bankuna…';

  @override
  String get searchByNameType => 'Nemo da suna, nau\'i...';

  @override
  String get searchFlights => 'Nemo Jirage';

  @override
  String get searchPlans => 'Nemo tsare-tsare...';

  @override
  String get searchServices => 'Nemo ayyuka...';

  @override
  String seatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'wurin zama $count',
    );
    return '$_temp0';
  }

  @override
  String get seatNumber => 'Lambar Kujera';

  @override
  String get secureTransaction => 'Ma\'amala mai tsaro da ɓoyewa';

  @override
  String get secureTransaction2 => 'Ma\'amala Mai Aminci';

  @override
  String get secureWithFourDigitPin => 'Tsare asusunka da PIN mai lamba 4';

  @override
  String get security => 'Tsaro';

  @override
  String get security2 => 'TSARO';

  @override
  String get securityAlert => 'Faɗakarwar Tsaro';

  @override
  String get securitySettings => 'Saitunan Tsaro';

  @override
  String get seeAll => 'Duba Duka';

  @override
  String get selectAccount => 'Zaɓi Asusu';

  @override
  String get selectAllSourcesOfRevenueFor =>
      'A zaɓi dukkan hanyoyin samun kuɗi na kasuwancin';

  @override
  String get selectBank => 'Zaɓi Banki';

  @override
  String get selectBankFirst => 'Da fatan za a zaɓi banki da farko';

  @override
  String get selectExamBody => 'Zaɓi Hukumar Jarabawa';

  @override
  String get selectExamType => 'Zaɓi Nau\'in Jarabawa';

  @override
  String get selectIdType => 'Zaɓi nau\'in shaida';

  @override
  String get selectLanguage => 'Zaɓi Harshe';

  @override
  String get selectNetwork => 'Zaɓi Hanyar Sadarwa';

  @override
  String get selectNetworkFirst => 'Fara zaɓi hanyar sadarwa';

  @override
  String get selectPensionFundAdministrator => 'Zaɓi Mai Kula da Asusun Fensho';

  @override
  String get selectPlan => 'Zaɓi Tsari';

  @override
  String get selectProvider => 'Zaɓi Mai bayarwa';

  @override
  String get selectProviderFirst => 'Fara zaɓi mai bayar da sabis';

  @override
  String get selectService => 'Zaɓi Sabis';

  @override
  String get selectState => 'Zaɓi Jiha';

  @override
  String get selectTransferMethod => 'Da fatan za a zaɓi hanyar canja wurin';

  @override
  String get selectWhatBestDescribesYou => 'A zaɓi abin da ya fi dacewa da ku';

  @override
  String selectedPassengersPriceTotalprice(
      Object _passengers, Object price, Object _totalPrice) {
    return 'An zaɓa · $_passengers × ₦$price = ₦$_totalPrice';
  }

  @override
  String selectedbankBankaccountcontroller(
      Object _selectedBank, Object _bankAccountController) {
    return '$_selectedBank · $_bankAccountController';
  }

  @override
  String get sendMoney => 'Aika Kudi';

  @override
  String get sendMoneyDesc => 'Ga abokanka da iyalanka';

  @override
  String get sendMoneyFaster => 'Aika Kudi Sauri';

  @override
  String get sendOtp => 'Aika OTP';

  @override
  String get sendResetCode => 'Aika Lambar Sake Saitawa';

  @override
  String get sendVerificationCode => 'Aika Lambar Tabbatarwa';

  @override
  String get sentCodeToPhone => 'Mun aika da lamba zuwa wayarka';

  @override
  String get service => 'Sabis';

  @override
  String serviceRequiresTier(Object tier) {
    return 'Wannan sabis yana buƙatar matakin $tier ko sama da haka.';
  }

  @override
  String get serviceUnavailable => 'Sabis ba ya samuwa a yanzu';

  @override
  String get services => 'Ayyuka';

  @override
  String get setA4DigitPinFor => 'Saita PIN mai lamba 4 don ma\'amaloli';

  @override
  String get setANew4DigitPin => 'Saita sabon PIN mai lamba 4';

  @override
  String get setPin => 'Saita PIN';

  @override
  String get setUpA4DigitTransaction => 'Saita PIN na ma\'amala mai lamba 4';

  @override
  String get settings => 'Saitunan';

  @override
  String get share => 'Raba';

  @override
  String get shareCode => 'Raba Lamba';

  @override
  String get shareReceipt => 'Raba Rasit';

  @override
  String get shareTheseDetailsToReceiveMoney =>
      'A raba waɗannan bayanai don karɓar kuɗi';

  @override
  String get signIn => 'Shiga';

  @override
  String get signInToYourAccount => 'Shiga asusunka na RimaPay';

  @override
  String get signInWithFingerprintOrFace => 'Shiga da hoton yatsa ko fuska';

  @override
  String get signOutOfAccount => 'Fita daga asusunka';

  @override
  String get signUp => 'Yi Rijista';

  @override
  String get slide1Description =>
      'Muka gina shi da Najeriyawa, domin Najeriyawa. Ku ji \'yancin kuɗi wanda ya dogara ga al\'adunmu.';

  @override
  String get slide1Subtitle => 'Al\'adun Najeriya';

  @override
  String get slide1Title => 'Mu \'yan ƙasa ne,\nBuɗe mana';

  @override
  String get slide2Description =>
      'Daga ma\'aikatan kamfanoni zuwa \'yan kasuwa - \'yancin kuɗi ga dukan Najeriyawa.';

  @override
  String get slide2Subtitle => 'Kowane Banajeriyanci';

  @override
  String get slide2Title => 'RimaPay na\nKowa da Kowa';

  @override
  String get slide3Description =>
      'Danna, biya, gama. Ku ji makomar biyan kuɗi da sauri, aminci, da sauƙi.';

  @override
  String get slide3Subtitle => 'Gogayya ba tare da wahala';

  @override
  String get slide3Title => 'Biyan Kuɗi\nCikin Sauƙi';

  @override
  String get smartCardIucNumber => 'Lambar Smart Card / IUC';

  @override
  String get smartCardNumber => 'Lambar Katin Wayo';

  @override
  String get smsNotifications => 'Sanarwar SMS';

  @override
  String get sourceOfIncome => 'Hanyar Samun Kuɗi';

  @override
  String get spectranetSmileMore => 'Spectranet, Smile da sauransu';

  @override
  String get staffSalaryPayments => 'Biyan albashin ma\'aikata';

  @override
  String get startSending => 'Fara Aikawa';

  @override
  String get state => 'Jiha';

  @override
  String get stationeryPurchase => 'Sayen kayan rubutu';

  @override
  String get status => 'Matsayi';

  @override
  String get submitForVerification => 'Gabatar don Tabbatarwa';

  @override
  String get success => 'Nasara';

  @override
  String get successful => 'An Yi Nasara';

  @override
  String get support => 'Tallafi';

  @override
  String get supportACauseToday => 'Taimaka wa wani dalili yau';

  @override
  String get supportHours =>
      'Litinin – Jumma\'a: 8 na safe – 8 na dare\nAsabar: 9 na safe – 5 na yamma';

  @override
  String get switchLanguage => 'Canza zuwa Turanci';

  @override
  String get switchLanguageAction => 'Canza zuwa EN';

  @override
  String get switchToDarkTheme => 'Canja zuwa yanayin duhu';

  @override
  String get systemMaintenance => 'Gyaran Tsarin';

  @override
  String get takeAClearSelfieForIdentity =>
      'A ɗauki hoton kai bayyananne don tabbatar da shaida.';

  @override
  String get takeAClearSelfieNoGlasses =>
      'A ɗauki hoton kai bayyananne — babu tabarau, haske sosai, fuska a tsakiya.';

  @override
  String get takeAPhotoOfYourBusiness => 'A ɗauki hoton wurin kasuwancin';

  @override
  String get takeASelfieToVerifyYour =>
      'A ɗauki hoton kai don tabbatar da shaida';

  @override
  String get takePhoto => 'Ɗauki Hoto';

  @override
  String get taxesAndFees => 'Haraji da kuɗaɗe';

  @override
  String get taxesLeviesOfficialPayments => 'Haraji, kuɗaɗe da biyan hukuma';

  @override
  String get tellUsAboutYourBusiness => 'A ba mu labarin kasuwancin';

  @override
  String get tellUsAboutYourself => 'A ba mu labarin kanku';

  @override
  String get thankYouForBankingWithRima =>
      'Na gode da yin ma\'amala da Rima MFB';

  @override
  String get thankYouForUsingRimapay => 'Na gode da amfani da RimaPay';

  @override
  String get thePageYouAreLookingFor => 'Shafin da ake nema babu shi.';

  @override
  String get thisFeatureIsUnderDevelopmentNcheck =>
      'Ana kan gina wannan fasali.\nA sake dubawa nan ba da jimawa ba!';

  @override
  String get thisWillPermanentlyDeleteYourAccount =>
      'Wannan zai share asusun da dukkan bayanai har abada. Ba za a iya juya wannan mataki ba.';

  @override
  String ticketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tikiti $count',
    );
    return '$_temp0';
  }

  @override
  String get ticketsAndConcerts => 'Tikiti da bukukuwa';

  @override
  String get tier1Requirements => 'Buƙatun Mataki na 1';

  @override
  String get tier2IdentityVerification => 'Mataki na 2 · Tabbatar da Shaida';

  @override
  String get tier2Requirements => 'Buƙatun Mataki na 2';

  @override
  String get tier3Requirements => 'Buƙatun Mataki na 3';

  @override
  String get tierBenefits => 'Fa\'idodin Matsayi';

  @override
  String tierIndex(Object index) {
    return 'Mataki na $index';
  }

  @override
  String get tierUpgrade => 'Haɓaka Matsayi';

  @override
  String get time => 'Lokaci';

  @override
  String get to => 'Zuwa';

  @override
  String get toOtherBanks => 'Zuwa Wasu Bankuna';

  @override
  String get toOtherBanksDesc => 'Aika zuwa kowane asusun banki na Najeriya';

  @override
  String get toRimaPay => 'Zuwa RimaPay';

  @override
  String get toRimaPayDesc => 'Aika zuwa kowane asusun RimaPay nan take';

  @override
  String get today => 'Yau';

  @override
  String get todaySIncome => 'Kuɗin Shiga na Yau';

  @override
  String get todaySSpending => 'Kashe Kuɗi na Yau';

  @override
  String get topupSuccessful => 'Cika ya yi nasara';

  @override
  String get total => 'Jimillar';

  @override
  String get totalLimit => 'Jimlar Iyaka';

  @override
  String totalSpent(Object total) {
    return 'An kashe ₦$total';
  }

  @override
  String get totalWealth => 'Jimlar Dukiya';

  @override
  String totalprice(Object _totalPrice) {
    return '₦$_totalPrice';
  }

  @override
  String get transaction => 'Ma\'amala';

  @override
  String get transactionAmount => 'Adadin Ma\'amala';

  @override
  String get transactionDetails => 'Cikakkun Bayanai na Ma\'amala';

  @override
  String get transactionFailed => 'Ma\'amalar ta kasa';

  @override
  String get transactionHistory => 'Tarihin Ma\'amala';

  @override
  String get transactionId => 'Lambar Ma\'amala';

  @override
  String get transactionLimits => 'Iyakokin Ma\'amala';

  @override
  String get transactionPin => 'PIN na Ma\'amala';

  @override
  String transactionProcessedOk(Object type) {
    return 'An gudanar da $type naka cikin nasara';
  }

  @override
  String get transactionReceipt => 'Rasit na Ma\'amala';

  @override
  String get transactionReference => 'Lambar Shaidar Ma\'amala';

  @override
  String transactionStatusBody(Object type, Object status) {
    return 'An $status ma\'amalar $type ɗin ku';
  }

  @override
  String transactionStatusTitle(Object status) {
    return 'Ma\'amala $status';
  }

  @override
  String get transactionSuccessful => 'Ma\'amalar ta yi nasara';

  @override
  String get transactions => 'Tarihi';

  @override
  String get transfer => 'Canja wurin';

  @override
  String get transferFee => 'Kuɗin Canja wurin';

  @override
  String get transferFromAnyBank => 'Canja daga kowane asusun banki';

  @override
  String get transferMoney => 'Canja Kuɗi';

  @override
  String get transferSuccessful => 'Canja wurin ya yi nasara';

  @override
  String get transferSuccessfulCelebrate => 'An Canja Wuri Cikin Nasara! 🎉';

  @override
  String get transferToBanksWallets => 'Canja wuri zuwa bankuna da wallet';

  @override
  String get transferToContacts => 'Canja zuwa lambobin ku';

  @override
  String get transferToFundWallet => 'Canja don cika ma\'ajiyarka';

  @override
  String get transferUsingPhone => 'Canja ta amfani da lambar waya';

  @override
  String get transfersAreAvailable247Including =>
      'Ana iya canja wuri sa\'o\'i 24 a kullum har da karshen mako';

  @override
  String get transport => 'Sufuri';

  @override
  String get transportDesc => 'Tikitin bus da jirgin sama';

  @override
  String get transportOperator => 'Kamfanin Sufuri';

  @override
  String get travelDate => 'Ranar Tafiya';

  @override
  String get trustedPensionManagerSince2004 =>
      'Amintaccen mai kula da fensho tun 2004';

  @override
  String get twoFactorAuth => 'Tabbatar da Kashi Biyu';

  @override
  String get type => 'Nau\'i';

  @override
  String get underReview => 'Ana Duba';

  @override
  String get underbanked => 'Marasa Cikakken Sabis na Banki';

  @override
  String get underbankedAccount => 'Asusun Marasa Cikakken Sabis na Banki';

  @override
  String get underbankedDesc =>
      'Haɗa kai a fannin kuɗi — ƙananan rance da ƙungiyoyin tanadi';

  @override
  String get underbankingAccount => 'Asusun Underbanking';

  @override
  String get unlockHigherLimitsLong =>
      'Buɗe manyan iyakoki, ƙarancin kuɗin sabis da ƙarin fasaloli masu ban sha\'awa.';

  @override
  String get unlockHigherLimitsShort => 'Buɗe manyan iyakoki da fasaloli';

  @override
  String get unlockMoreFeatures => 'Buɗe ƙarin abubuwa';

  @override
  String unreadcountUnread(Object unreadCount) {
    return '$unreadCount ba a karanta ba';
  }

  @override
  String get updateAccountPassword => 'Sabunta kalmar sirri ta asusunka';

  @override
  String get updateLoginPin => 'Sabunta PIN na shiga';

  @override
  String get updatePin => 'Sabunta PIN';

  @override
  String get updateTransactionPin => 'Sabunta PIN na ma\'amala';

  @override
  String get upgrade => 'Haɓaka';

  @override
  String get upgradeAccount => 'Haɓaka Asusu';

  @override
  String get upgradeAccountNow => 'Haɓaka Yanzu';

  @override
  String get upgradeSuccessful => 'An Haɓaka Cikin Nasara!';

  @override
  String get upgradeTier => 'Haɓaka Matsayi';

  @override
  String upgradeToInfo(Object info) {
    return 'Haɓaka zuwa $info';
  }

  @override
  String get upgradeToPremium => 'Haɓaka zuwa Premium';

  @override
  String get upgradeToStandard => 'Haɓaka zuwa Standard';

  @override
  String get upgradeToTier2 => 'Haɓaka zuwa Mataki na 2';

  @override
  String get upgradeToUnlock => 'Haɓaka don Buɗewa';

  @override
  String get upgradeToUnlockHigherLimits => 'Haɓaka don buɗe manyan iyakoki';

  @override
  String upgradeToUnlockService(Object service) {
    return 'Haɓaka don buɗe $service';
  }

  @override
  String get upgradeYourAccount => 'Haɓaka Asusunka';

  @override
  String get uploadAClearPhotoOfYour =>
      '• A ɗora hoto bayyananne na shaidar gwamnati\n• A bayar da takardar tabbatar da adireshi';

  @override
  String get uploadAClearPhotoOrScan =>
      'A ɗora hoto ko scan bayyananne na shaidar gwamnati.';

  @override
  String get uploadADocumentShowingYourCurrent =>
      'A ɗora takardar da ke nuna adireshin yanzu, mai kwanan wata cikin watanni 3 da suka gabata.';

  @override
  String get uploadAddressProof => 'Ɗora shaidar adireshi';

  @override
  String get uploadCacCertificate => 'Ɗora Takardar CAC';

  @override
  String get uploadDocument => 'Ɗora Takarda';

  @override
  String get uploadGovernmentIdPhoto => 'Ɗora hoton shaidar gwamnati';

  @override
  String get uploadRecentUtilityBillForAddress =>
      'A ɗora sabuwar takardar kuɗin sabis don tabbatar da adireshi';

  @override
  String get uploadValidIdCardsForAll =>
      'A ɗora ingantattun katunan shaida na dukkan daraktoci';

  @override
  String get uploadYourCertificateOfIncorporation =>
      'A ɗora Takardar Shaidar Rajistar Kamfani';

  @override
  String get useAccountNumberToLink =>
      'Yi amfani da lambar asusunka don haɗa asusunka na RimaPay.';

  @override
  String get useCurrentLocation => 'Yi amfani da wurin da ake yanzu';

  @override
  String get useFaceId => 'Yi amfani da Face ID';

  @override
  String get useFingerprint => 'Yi amfani da Hoton Yatsa';

  @override
  String get useFingerprintOrFaceId => 'Yi amfani da hoton yatsa ko Face ID';

  @override
  String get useYourRegisteredNameWhenTransferring =>
      'A yi amfani da sunan da aka yi rajista da shi wajen canja wuri';

  @override
  String get userExampleCom => 'user@example.com';

  @override
  String get ussd => 'USSD';

  @override
  String get utilitiesServices => 'Kayan masarufi da ayyuka';

  @override
  String get utilityBill => 'Takardar Kuɗin Sabis';

  @override
  String get utilityBillBankStatementEtc =>
      'Takardar kuɗin sabis, bayanin banki, da sauransu.';

  @override
  String validForPeriod(Object period) {
    return 'Yana aiki na $period';
  }

  @override
  String validForValidity(Object validity) {
    return 'Yana aiki na $validity';
  }

  @override
  String get validateAccountFirst =>
      'Da fatan za a tabbatar da lambar asusun da farko';

  @override
  String get verificationTypicallyTakes12Business =>
      'Tabbatarwa kan ɗauki kwanakin aiki 1–2. Za a sanar da ku idan an gama.';

  @override
  String get verified => 'An Tabbatar';

  @override
  String get verify => 'Tabbatar';

  @override
  String get verifyArrow => 'Tabbatar →';

  @override
  String get verifyEmail => 'Tabbatar da Imel';

  @override
  String get verifyExistingAccount => 'Tabbatar da asusunka don ci gaba';

  @override
  String get verifyTransaction => 'Tabbatar da Ma\'amala';

  @override
  String get verifyYourIdentityWithYourNin =>
      'A tabbatar da shaida da NIN ko BVN';

  @override
  String get verifyYourPhone => 'Tabbatar da Wayar';

  @override
  String get verifying => 'Ana tabbatarwa...';

  @override
  String get verifyingYourFace => 'Ana tantance fuskarka…';

  @override
  String get verifyingYourFacePlain => 'Ana tantance fuskarka';

  @override
  String get viewAll => 'Duba duka →';

  @override
  String get viewAll2 => 'Duba Duka';

  @override
  String get viewAllRecentPurchases => 'Duba Dukkan Sayayyar Kwanan Nan';

  @override
  String get viewBusinessInsights => 'Duba bayanan kasuwanci';

  @override
  String get viewTransactionLimits => 'Duba iyakokin ma\'amalarka';

  @override
  String get voluntaryPension => 'Fensho na Sa Kai';

  @override
  String get voterSCard => 'Katin Zabe';

  @override
  String get waecJambNecoMore => 'WAEC, JAMB, NECO da sauransu';

  @override
  String get walletBalance => 'Ma\'ajiyar Kuɗi';

  @override
  String get walletTransfer => 'Canja Jaka';

  @override
  String get weLlNotifyYouWhenFunds => 'Za mu sanar da ku idan kuɗi ya shigo';

  @override
  String get weLlSendAOneTime =>
      'Za mu aika lamba ta sau ɗaya don tabbatar da wannan canji.';

  @override
  String get weLlSendAOneTime2 =>
      'Za mu aika lamba ta sau ɗaya zuwa lambar da aka yi rajista da ita don tabbatar da sake saitawa.';

  @override
  String weSentA6DigitCode(Object needsNin) {
    return 'Mun aika lamba mai lamba 6 don tabbatar da $needsNin. A duba lambar wayar da aka yi rajista da ita.';
  }

  @override
  String weSentACodeTo234(Object _phoneDigits) {
    return 'Mun aika lamba zuwa +234 $_phoneDigits';
  }

  @override
  String get weekly => 'Kowane mako';

  @override
  String get welcomeBack => 'Maraba da komowa';

  @override
  String get welcomeCreateAccount => 'Ƙirƙiri asusun ku';

  @override
  String get welcomeHeadline => 'Anyi Mana,\nMuka Yi';

  @override
  String get welcomeLogIn => 'Shiga';

  @override
  String get welcomeNback => 'Barka da\nKomowa 👋';

  @override
  String get welcomeSignUp => 'Yi Rajista';

  @override
  String get welcomeSubtitle =>
      'Sabis na kudi mai aminci, da sauri kuma abin dogaro don ku.';

  @override
  String get welcomeToRimaPay => 'Maraba zuwa RimaPay';

  @override
  String get welcomeToRimaPayCelebrate => 'Maraba da zuwa RimaPay! 🎉';

  @override
  String welcomeValidatedfirstname(Object validatedFirstName) {
    return 'Barka da zuwa, $validatedFirstName!';
  }

  @override
  String get welcomeWelcomeBack => 'Barka da komowa';

  @override
  String get wereHereToHelp => 'Muna nan don taimaka muku';

  @override
  String whatCopied(Object what) {
    return 'An kwafi $what';
  }

  @override
  String get whatIsYourPhoneNumber => 'Menene lambar wayar ku?';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get whereDoYouLive => 'Ina kuke zama?';

  @override
  String get whereIsYourBusinessLocated => 'Ina kasuwancin ku yake?';

  @override
  String get whereToSendMoney => 'Ina kake son aika kuɗi?';

  @override
  String get withoutBvnOrNinYourAccount =>
      'Idan babu BVN ko NIN, asusun zai sami ƙarancin fasaloli:\n• Iyakar ma\'amala ₦10,000 kowace rana\n• Babu canja wuri zuwa ƙasashen waje\n• Za a iya haɓakawa kowane lokaci ta ƙara BVN/NIN daga baya';

  @override
  String get year1 => 'Shekara 1';

  @override
  String get yearly => 'Kowace shekara';

  @override
  String get yesContinue => 'Eh, Ci gaba';

  @override
  String get youAreNowOnTheStandard =>
      'Yanzu kuna kan Matakin Standard.\nSabbin iyakokin ku sun fara aiki nan take.';

  @override
  String get youCanReceiveTransfersUsingYour =>
      'Za a iya karɓar kuɗi ta lambar waya ko wannan lambar asusu';

  @override
  String get youEarned50CashbackFromYour =>
      'An samu cashback ₦50 daga biyan kuɗin wutar lantarki. Jimlar cashback wannan wata: ₦350';

  @override
  String get youHaveBeenVerified => 'An Tabbatar da Ku!';

  @override
  String get youReAboutToOpenA =>
      'Za a buɗe asusun haɗa kai a fannin kuɗi (marasa cikakken sabis na banki). An tsara wannan asusu ga waɗanda ba su da takardun shaida na hukuma.';

  @override
  String get youReceived25000FromAdebayo =>
      'An karɓi ₦25,000 daga Adebayo Okafor tare da bayani: Raba kuɗin abincin dare';

  @override
  String get yourAccountHasBeenCreatedSuccessfully =>
      'An ƙirƙiri asusun cikin nasara.';

  @override
  String get yourAccountHasBeenSetUp => 'An saita asusun cikin nasara';

  @override
  String get yourAccountNumber => 'Lambar Asusun Ku';

  @override
  String get yourAccountPasswordHasBeenUpdated =>
      'An sabunta kalmar sirrin asusun';

  @override
  String get yourAddressHasBeenSavedSuccessfully =>
      'An ajiye adireshin cikin nasara.';

  @override
  String get yourAirtimePurchaseOf1000 =>
      'Sayen katin waya na ₦1,000 zuwa 08012345678 ya yi nasara';

  @override
  String get yourBusinessAccountHasBeenCreated =>
      'An ƙirƙiri asusun kasuwancin cikin nasara.';

  @override
  String get yourBusinessAccountIsNowActive =>
      'Asusun kasuwancin yanzu yana aiki';

  @override
  String get yourCurrentTierBasic => 'Matakin Ku na Yanzu: Basic';

  @override
  String get yourDeclarationHasBeenSavedSuccessfully =>
      'An ajiye sanarwar cikin nasara.';

  @override
  String get yourDedicatedAccount => 'Asusunka na Musamman';

  @override
  String get yourDepositsAre => 'AJIYAR KU TANA ';

  @override
  String get yourDocumentsAreUnderReviewNwe =>
      'Ana duba takardun ku.\nZa mu sanar da ku cikin kwanakin aiki 1–2.';

  @override
  String get yourEmailHasBeenConfirmed => 'An tabbatar da imel ɗin ku.';

  @override
  String get yourFundsAreInsuredByNdic =>
      'NDIC ya yi wa kuɗin ku inshora. Samu har 13% a kowace shekara.';

  @override
  String get yourIdentityHasBeenConfirmedNwelcome =>
      'An tabbatar da shaidar ku.\nBarka da zuwa RimaPay!';

  @override
  String get yourIncomeDetailsHaveBeenSaved =>
      'An ajiye bayanan kuɗin shigar ku cikin nasara.';

  @override
  String yourNeedsninIsUsedSolelyFor(Object needsNin) {
    return 'Ana amfani da $needsNin ɗin ku kawai don tabbatar da shaida kuma an ɓoye shi.';
  }

  @override
  String get yourPasswordHasBeenUpdated => 'An sabunta kalmar sirrin ku';

  @override
  String get yourPasswordHasBeenUpdatedNsign =>
      'An sabunta kalmar sirrin ku.\nA shiga da sabuwar kalmar sirri.';

  @override
  String get yourPinIsEncryptedAndNever =>
      'An ɓoye PIN ɗin ku kuma ba a taɓa ajiye shi ba don tsaro.';

  @override
  String get yourProfileIsNowCompleteNwelcome =>
      'Bayanan ku sun cika yanzu.\nBarka da zuwa RimaPay!';

  @override
  String get yourProfileIsNowFullyComplete =>
      'Bayanan ku sun cika sarai yanzu.';

  @override
  String get yourRimapayAccountIsNowLinked =>
      'Asusun ku na RimaPay yanzu yana haɗe\nda wannan na\'ura.';

  @override
  String get yourTransactionPinHasBeenReset =>
      'An sake saita PIN ɗin ma\'amalar ku.';

  @override
  String get yourTransactionPinHasBeenUpdated =>
      'An sabunta PIN ɗin ma\'amalar ku.';

  @override
  String get yourTransactionPinHasBeenUpdated2 =>
      'An sabunta PIN ɗin ma\'amalar ku';

  @override
  String yourTransactiontypeHasBeenProcessedSuccessfully(
      Object transactionType) {
    return 'An gudanar da $transactionType ɗin ku cikin nasara';
  }

  @override
  String get yourWealthIsBelowTheNisab =>
      'Dukiyar ku bai kai ma\'aunin Nisab ba — ba a wajabta zakka ba tukuna.';

  @override
  String get zakat => 'Zakka';

  @override
  String get zakatDue25 => 'Zakkar da Ya Wajaba (2.5%)';

  @override
  String get zakatReligious => 'Zakka / Addini';
}
