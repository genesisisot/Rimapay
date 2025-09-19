import 'dart:convert';

class UserData {
  UserData({
    required this.id,
    required this.accountName,
    required this.accountNumber,
    required this.accountTier,
    required this.accountTransferLimit,
    required this.customerTitle,
    required this.accountType,
    required this.customerType,
    required this.customerPhoto,
    required this.gender,
    required this.dateOfBirth,
    required this.nationality,
    required this.occupation,
    required this.employeeNumber,
    required this.residentAddress,
    required this.residentCountry,
    required this.residentState,
    required this.residentLga,
    required this.residentCity,
    required this.phone,
    required this.authToken,
    required this.email,
    required this.latitude,
    required this.longitude,
    required this.maritalstatus,
    required this.nextkinlastname,
    required this.nextkinfirstname,
    required this.nextofkinstatus,
    required this.nextkinphone,
    required this.maidenname,
    required this.political,
    required this.accountofficer,
    required this.accountBranch,
    required this.bvnstatus,
    required this.loaneligibility,
    required this.riskPermission,
    required this.docUploadstatus,
    required this.accountStatus,
    this.password,
    this.pin,
    required this.accountPackage,
    required this.customerInternetBankingId,
    required this.datecreated,
  });

  final String? id;
  final String? accountName;
  final String? accountNumber;
  final String? accountTier;
  final String? accountTransferLimit;
  final String? customerTitle;
  final String? accountType;
  final String? customerType;
  final String? customerPhoto;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? occupation;
  final String? employeeNumber;
  final String? residentAddress;
  final int? residentCountry;
  final String? residentState;
  final String? residentLga;
  final String? residentCity;
  final String? phone;
  final String? authToken;
  final String? email;
  final String? latitude;
  final String? longitude;
  final String? maritalstatus;
  final String? nextkinlastname;
  final String? nextkinfirstname;
  final String? nextofkinstatus;
  final String? nextkinphone;
  final String? maidenname;
  final String? political;
  final String? accountofficer;
  final String? accountBranch;
  final String? bvnstatus;
  final String? loaneligibility;
  final String? riskPermission;
  final String? docUploadstatus;
  final String? accountStatus;
  final String? password;
  final String? pin;
  final String? accountPackage;
  final String? customerInternetBankingId;
  final DateTime? datecreated;

  UserData copyWith({
    String? id,
    String? accountName,
    String? accountNumber,
    String? accountTier,
    String? accountTransferLimit,
    String? customerTitle,
    String? accountType,
    String? customerType,
    String? customerPhoto,
    String? gender,
    DateTime? dateOfBirth,
    String? nationality,
    String? occupation,
    String? employeeNumber,
    String? residentAddress,
    int? residentCountry,
    String? residentState,
    String? residentLga,
    String? residentCity,
    String? phone,
    String? authToken,
    String? email,
    String? latitude,
    String? longitude,
    String? maritalstatus,
    String? nextkinlastname,
    String? nextkinfirstname,
    String? nextofkinstatus,
    String? nextkinphone,
    String? maidenname,
    String? political,
    String? accountofficer,
    String? accountBranch,
    String? bvnstatus,
    String? loaneligibility,
    String? riskPermission,
    String? docUploadstatus,
    String? accountStatus,
    String? password,
    String? pin,
    String? accountPackage,
    String? customerInternetBankingId,
    DateTime? datecreated,
  }) {
    return UserData(
      id: id ?? this.id,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountTier: accountTier ?? this.accountTier,
      accountTransferLimit: accountTransferLimit ?? this.accountTransferLimit,
      customerTitle: customerTitle ?? this.customerTitle,
      accountType: accountType ?? this.accountType,
      customerType: customerType ?? this.customerType,
      customerPhoto: customerPhoto ?? this.customerPhoto,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      occupation: occupation ?? this.occupation,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      residentAddress: residentAddress ?? this.residentAddress,
      residentCountry: residentCountry ?? this.residentCountry,
      residentState: residentState ?? this.residentState,
      residentLga: residentLga ?? this.residentLga,
      residentCity: residentCity ?? this.residentCity,
      phone: phone ?? this.phone,
      authToken: authToken ?? this.authToken,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maritalstatus: maritalstatus ?? this.maritalstatus,
      nextkinlastname: nextkinlastname ?? this.nextkinlastname,
      nextkinfirstname: nextkinfirstname ?? this.nextkinfirstname,
      nextofkinstatus: nextofkinstatus ?? this.nextofkinstatus,
      nextkinphone: nextkinphone ?? this.nextkinphone,
      maidenname: maidenname ?? this.maidenname,
      political: political ?? this.political,
      accountofficer: accountofficer ?? this.accountofficer,
      accountBranch: accountBranch ?? this.accountBranch,
      bvnstatus: bvnstatus ?? this.bvnstatus,
      loaneligibility: loaneligibility ?? this.loaneligibility,
      riskPermission: riskPermission ?? this.riskPermission,
      docUploadstatus: docUploadstatus ?? this.docUploadstatus,
      accountStatus: accountStatus ?? this.accountStatus,
      password: password ?? this.password,
      pin: pin ?? this.pin,
      accountPackage: accountPackage ?? this.accountPackage,
      customerInternetBankingId: customerInternetBankingId ?? this.customerInternetBankingId,
      datecreated: datecreated ?? this.datecreated,
    );
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json["id"],
      accountName: json["accountName"],
      accountNumber: json["accountNumber"],
      accountTier: json["accountTier"],
      accountTransferLimit: json["accountTransferLimit"],
      customerTitle: json["customerTitle"],
      accountType: json["accountType"],
      customerType: json["customerType"],
      customerPhoto: json["customerPhoto"],
      gender: json["gender"],
      dateOfBirth: DateTime.tryParse(json["dateOfBirth"] ?? ""),
      nationality: json["nationality"],
      occupation: json["occupation"],
      employeeNumber: json["employeeNumber"],
      residentAddress: json["residentAddress"],
      residentCountry: json["residentCountry"],
      residentState: json["residentState"],
      residentLga: json["residentLga"],
      residentCity: json["residentCity"],
      phone: json["phone"],
      authToken: json["authToken"],
      email: json["email"],
      latitude: json["latitude"],
      longitude: json["longitude"],
      maritalstatus: json["maritalstatus"],
      nextkinlastname: json["nextkinlastname"],
      nextkinfirstname: json["nextkinfirstname"],
      nextofkinstatus: json["nextofkinstatus"],
      nextkinphone: json["nextkinphone"],
      maidenname: json["maidenname"],
      political: json["political"],
      accountofficer: json["accountofficer"],
      accountBranch: json["accountBranch"],
      bvnstatus: json["bvnstatus"],
      loaneligibility: json["loaneligibility"],
      riskPermission: json["riskPermission"],
      docUploadstatus: json["docUploadstatus"],
      accountStatus: json["accountStatus"],
      accountPackage: json["accountPackage"],
      password: json["password"],
      pin: json["pin"],
      customerInternetBankingId: json["customerInternetBankingId"],
      datecreated: DateTime.tryParse(json["datecreated"] ?? ""),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "accountName": accountName,
        "accountNumber": accountNumber,
        "accountTier": accountTier,
        "accountTransferLimit": accountTransferLimit,
        "customerTitle": customerTitle,
        "accountType": accountType,
        "customerType": customerType,
        "customerPhoto": customerPhoto,
        "gender": gender,
        "dateOfBirth": dateOfBirth,
        "nationality": nationality,
        "occupation": occupation,
        "employeeNumber": employeeNumber,
        "residentAddress": residentAddress,
        "residentCountry": residentCountry,
        "residentState": residentState,
        "residentLga": residentLga,
        "residentCity": residentCity,
        "phone": phone,
        "authToken": authToken,
        "email": email,
        "password": password,
        "pin": pin,
        "latitude": latitude,
        "longitude": longitude,
        "maritalstatus": maritalstatus,
        "nextkinlastname": nextkinlastname,
        "nextkinfirstname": nextkinfirstname,
        "nextofkinstatus": nextofkinstatus,
        "nextkinphone": nextkinphone,
        "maidenname": maidenname,
        "political": political,
        "accountofficer": accountofficer,
        "accountBranch": accountBranch,
        "bvnstatus": bvnstatus,
        "loaneligibility": loaneligibility,
        "riskPermission": riskPermission,
        "docUploadstatus": docUploadstatus,
        "accountStatus": accountStatus,
        "accountPackage": accountPackage,
        "customerInternetBankingId": customerInternetBankingId,
        "datecreated": datecreated?.toIso8601String(),
      };

  @override
  String toString() {
    return 'UserData(id: $id, accountName: $accountName, accountNumber: $accountNumber, accountTier: $accountTier, accountTransferLimit: $accountTransferLimit, customerTitle: $customerTitle, accountType: $accountType, customerType: $customerType, customerPhoto: $customerPhoto, gender: $gender, dateOfBirth: $dateOfBirth, nationality: $nationality, occupation: $occupation, employeeNumber: $employeeNumber, residentAddress: $residentAddress, residentCountry: $residentCountry, residentState: $residentState, residentLga: $residentLga, residentCity: $residentCity, phone: $phone, authToken: $authToken, email: $email, latitude: $latitude, longitude: $longitude, maritalstatus: $maritalstatus, nextkinlastname: $nextkinlastname, nextkinfirstname: $nextkinfirstname, nextofkinstatus: $nextofkinstatus, nextkinphone: $nextkinphone, maidenname: $maidenname, political: $political, accountofficer: $accountofficer, accountBranch: $accountBranch, bvnstatus: $bvnstatus, loaneligibility: $loaneligibility, riskPermission: $riskPermission, docUploadstatus: $docUploadstatus, accountStatus: $accountStatus, password: $password, pin: $pin, accountPackage: $accountPackage, customerInternetBankingId: $customerInternetBankingId, datecreated: $datecreated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserData &&
        other.id == id &&
        other.accountName == accountName &&
        other.accountNumber == accountNumber &&
        other.accountTier == accountTier &&
        other.accountTransferLimit == accountTransferLimit &&
        other.customerTitle == customerTitle &&
        other.accountType == accountType &&
        other.customerType == customerType &&
        other.customerPhoto == customerPhoto &&
        other.gender == gender &&
        other.dateOfBirth == dateOfBirth &&
        other.nationality == nationality &&
        other.occupation == occupation &&
        other.employeeNumber == employeeNumber &&
        other.residentAddress == residentAddress &&
        other.residentCountry == residentCountry &&
        other.residentState == residentState &&
        other.residentLga == residentLga &&
        other.residentCity == residentCity &&
        other.phone == phone &&
        other.authToken == authToken &&
        other.email == email &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.maritalstatus == maritalstatus &&
        other.nextkinlastname == nextkinlastname &&
        other.nextkinfirstname == nextkinfirstname &&
        other.nextofkinstatus == nextofkinstatus &&
        other.nextkinphone == nextkinphone &&
        other.maidenname == maidenname &&
        other.political == political &&
        other.accountofficer == accountofficer &&
        other.accountBranch == accountBranch &&
        other.bvnstatus == bvnstatus &&
        other.loaneligibility == loaneligibility &&
        other.riskPermission == riskPermission &&
        other.docUploadstatus == docUploadstatus &&
        other.accountStatus == accountStatus &&
        other.password == password &&
        other.pin == pin &&
        other.accountPackage == accountPackage &&
        other.customerInternetBankingId == customerInternetBankingId &&
        other.datecreated == datecreated;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        accountName.hashCode ^
        accountNumber.hashCode ^
        accountTier.hashCode ^
        accountTransferLimit.hashCode ^
        customerTitle.hashCode ^
        accountType.hashCode ^
        customerType.hashCode ^
        customerPhoto.hashCode ^
        gender.hashCode ^
        dateOfBirth.hashCode ^
        nationality.hashCode ^
        occupation.hashCode ^
        employeeNumber.hashCode ^
        residentAddress.hashCode ^
        residentCountry.hashCode ^
        residentState.hashCode ^
        residentLga.hashCode ^
        residentCity.hashCode ^
        phone.hashCode ^
        authToken.hashCode ^
        email.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        maritalstatus.hashCode ^
        nextkinlastname.hashCode ^
        nextkinfirstname.hashCode ^
        nextofkinstatus.hashCode ^
        nextkinphone.hashCode ^
        maidenname.hashCode ^
        political.hashCode ^
        accountofficer.hashCode ^
        accountBranch.hashCode ^
        bvnstatus.hashCode ^
        loaneligibility.hashCode ^
        riskPermission.hashCode ^
        docUploadstatus.hashCode ^
        accountStatus.hashCode ^
        password.hashCode ^
        pin.hashCode ^
        accountPackage.hashCode ^
        customerInternetBankingId.hashCode ^
        datecreated.hashCode;
  }
}
