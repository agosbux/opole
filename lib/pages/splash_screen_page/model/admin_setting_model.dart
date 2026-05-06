import 'package:opole/utils/utils.dart';
class AdminSettingModel {
  bool? status;
  String? message;
  Data? data;

  AdminSettingModel({this.status, this.message, this.data});

  AdminSettingModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  Currency? currency;
  Android? android;
  Android? ios;
  bool? isWatermarkOn;
  String? watermarkIcon;
  String? sId;
  bool? stripeSwitch;
  String? stripePublishableKey;
  String? stripeSecretKey;
  bool? razorPaySwitch;
  String? razorPayId;
  String? razorSecretKey;
  String? privacyPolicyLink;
  String? termsOfUsePolicyLink;
  String? zegoAppId;
  String? zegoAppSignIn;
  List<String>? paymentGateway;
  bool? isFakeData;
  int? durationOfShorts;
  int? minCoinForCashOut;
  int? minWithdrawalRequestedCoin;
  String? createdAt;
  String? updatedAt;
  int? watermarkType;
  PrivateKey? privateKey;
  List<String>? videoBanned;
  bool? googlePlaySwitch;
  String? androidLicenseKey;
  String? iosLicenseKey;
  String? sightengineSecret;
  String? sightengineUser;
  int? loginBonus;
  int? adDisplayIndex;
  String? flutterWaveId;
  bool? flutterWaveSwitch;
  bool? isChatAdEnabled;
  bool? isChatBackButtonAdEnabled;
  bool? isFeedAdEnabled;
  bool? isGoogle;
  bool? isLiveStreamBackButtonAdEnabled;
  bool? isVideoAdEnabled;
  bool? isEffectActive;

  Data(
      {this.currency,
      this.android,
      this.ios,
      this.isWatermarkOn,
      this.watermarkIcon,
      this.sId,
      this.stripeSwitch,
      this.stripePublishableKey,
      this.stripeSecretKey,
      this.razorPaySwitch,
      this.razorPayId,
      this.razorSecretKey,
      this.privacyPolicyLink,
      this.termsOfUsePolicyLink,
      this.zegoAppId,
      this.zegoAppSignIn,
      this.paymentGateway,
      this.isFakeData,
      this.durationOfShorts,
      this.minCoinForCashOut,
      this.minWithdrawalRequestedCoin,
      this.createdAt,
      this.updatedAt,
      this.watermarkType,
      this.privateKey,
      this.videoBanned,
      this.googlePlaySwitch,
      this.androidLicenseKey,
      this.iosLicenseKey,
      this.sightengineSecret,
      this.sightengineUser,
      this.loginBonus,
      this.adDisplayIndex,
      this.flutterWaveId,
      this.flutterWaveSwitch,
      this.isChatAdEnabled,
      this.isChatBackButtonAdEnabled,
      this.isFeedAdEnabled,
      this.isGoogle,
      this.isLiveStreamBackButtonAdEnabled,
      this.isVideoAdEnabled,
      this.isEffectActive});

  Data.fromJson(Map<String, dynamic> json) {
    currency = json['currency'] != null ? Currency.fromJson(json['currency']) : null;
    android = json['android'] != null ? Android.fromJson(json['android']) : null;
    ios = json['ios'] != null ? Android.fromJson(json['ios']) : null;
    isWatermarkOn = json['isWatermarkOn'];
    watermarkIcon = json['watermarkIcon'];
    sId = json['_id'];
    stripeSwitch = json['stripeSwitch'];
    stripePublishableKey = json['stripePublishableKey'];
    stripeSecretKey = json['stripeSecretKey'];
    razorPaySwitch = json['razorPaySwitch'];
    razorPayId = json['razorPayId'];
    razorSecretKey = json['razorSecretKey'];
    privacyPolicyLink = json['privacyPolicyLink'];
    termsOfUsePolicyLink = json['termsOfUsePolicyLink'];
    zegoAppId = json['zegoAppId'];
    zegoAppSignIn = json['zegoAppSignIn'];
    paymentGateway = json['paymentGateway'].cast<String>();
    isFakeData = json['isFakeData'];
    durationOfShorts = json['durationOfShorts'];
    minCoinForCashOut = json['minCoinForCashOut'];
    minWithdrawalRequestedCoin = json['minWithdrawalRequestedCoin'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    watermarkType = json['watermarkType'];
    privateKey = json['privateKey'] != null ? PrivateKey.fromJson(json['privateKey']) : null;
    videoBanned = json['videoBanned'].cast<String>();
    googlePlaySwitch = json['googlePlaySwitch'];
    androidLicenseKey = json['androidLicenseKey'];
    iosLicenseKey = json['iosLicenseKey'];
    sightengineSecret = json['sightengineSecret'];
    sightengineUser = json['sightengineUser'];
    loginBonus = json['loginBonus'];
    adDisplayIndex = json['adDisplayIndex'];
    flutterWaveId = json['flutterWaveId'];
    flutterWaveSwitch = json['flutterWaveSwitch'];
    isChatAdEnabled = json['isChatAdEnabled'];
    isChatBackButtonAdEnabled = json['isChatBackButtonAdEnabled'];
    isFeedAdEnabled = json['isFeedAdEnabled'];
    isGoogle = json['isGoogle'];
    isLiveStreamBackButtonAdEnabled = json['isLiveStreamBackButtonAdEnabled'];
    isVideoAdEnabled = json['isVideoAdEnabled'];
    isEffectActive = json['isEffectActive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (currency != null) {
      data['currency'] = currency!.toJson();
    }
    if (android != null) {
      data['android'] = android!.toJson();
    }
    if (ios != null) {
      data['ios'] = ios!.toJson();
    }
    data['isWatermarkOn'] = isWatermarkOn;
    data['watermarkIcon'] = watermarkIcon;
    data['_id'] = sId;
    data['stripeSwitch'] = stripeSwitch;
    data['stripePublishableKey'] = stripePublishableKey;
    data['stripeSecretKey'] = stripeSecretKey;
    data['razorPaySwitch'] = razorPaySwitch;
    data['razorPayId'] = razorPayId;
    data['razorSecretKey'] = razorSecretKey;
    data['privacyPolicyLink'] = privacyPolicyLink;
    data['termsOfUsePolicyLink'] = termsOfUsePolicyLink;
    data['zegoAppId'] = zegoAppId;
    data['zegoAppSignIn'] = zegoAppSignIn;
    data['paymentGateway'] = paymentGateway;
    data['isFakeData'] = isFakeData;
    data['durationOfShorts'] = durationOfShorts;
    data['minCoinForCashOut'] = minCoinForCashOut;
    data['minWithdrawalRequestedCoin'] = minWithdrawalRequestedCoin;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['watermarkType'] = watermarkType;
    if (privateKey != null) {
      data['privateKey'] = privateKey!.toJson();
    }
    data['videoBanned'] = videoBanned;
    data['googlePlaySwitch'] = googlePlaySwitch;
    data['androidLicenseKey'] = androidLicenseKey;
    data['iosLicenseKey'] = iosLicenseKey;
    data['sightengineSecret'] = sightengineSecret;
    data['sightengineUser'] = sightengineUser;
    data['loginBonus'] = loginBonus;
    data['adDisplayIndex'] = adDisplayIndex;
    data['flutterWaveId'] = flutterWaveId;
    data['flutterWaveSwitch'] = flutterWaveSwitch;
    data['isChatAdEnabled'] = isChatAdEnabled;
    data['isChatBackButtonAdEnabled'] = isChatBackButtonAdEnabled;
    data['isFeedAdEnabled'] = isFeedAdEnabled;
    data['isGoogle'] = isGoogle;
    data['isLiveStreamBackButtonAdEnabled'] = isLiveStreamBackButtonAdEnabled;
    data['isVideoAdEnabled'] = isVideoAdEnabled;
    data['isEffectActive'] = isEffectActive;
    return data;
  }
}

class Currency {
  String? name;
  String? symbol;
  String? countryCode;
  String? currencyCode;
  bool? isDefault;

  Currency({this.name, this.symbol, this.countryCode, this.currencyCode, this.isDefault});

  Currency.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    symbol = json['symbol'];
    countryCode = json['countryCode'];
    currencyCode = json['currencyCode'];
    isDefault = json['isDefault'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['symbol'] = symbol;
    data['countryCode'] = countryCode;
    data['currencyCode'] = currencyCode;
    data['isDefault'] = isDefault;
    return data;
  }
}

class Android {
  Google? google;

  Android({this.google});

  Android.fromJson(Map<String, dynamic> json) {
    google = json['google'] != null ? Google.fromJson(json['google']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (google != null) {
      data['google'] = google!.toJson();
    }
    return data;
  }
}

class Google {
  String? interstitial;
  String? native;

  Google({this.interstitial, this.native});

  Google.fromJson(Map<String, dynamic> json) {
    interstitial = json['interstitial'];
    native = json['native'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['interstitial'] = interstitial;
    data['native'] = native;
    return data;
  }
}

class PrivateKey {
  String? type;
  String? projectId;
  String? privateKeyId;
  String? privateKey;
  String? clientEmail;
  String? clientId;
  String? authUri;
  String? tokenUri;
  String? authProviderX509CertUrl;
  String? clientX509CertUrl;
  String? universeDomain;

  PrivateKey(
      {this.type,
      this.projectId,
      this.privateKeyId,
      this.privateKey,
      this.clientEmail,
      this.clientId,
      this.authUri,
      this.tokenUri,
      this.authProviderX509CertUrl,
      this.clientX509CertUrl,
      this.universeDomain});

  PrivateKey.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    projectId = json['project_id'];
    privateKeyId = json['private_key_id'];
    privateKey = json['private_key'];
    clientEmail = json['client_email'];
    clientId = json['client_id'];
    authUri = json['auth_uri'];
    tokenUri = json['token_uri'];
    authProviderX509CertUrl = json['auth_provider_x509_cert_url'];
    clientX509CertUrl = json['client_x509_cert_url'];
    universeDomain = json['universe_domain'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['project_id'] = projectId;
    data['private_key_id'] = privateKeyId;
    data['private_key'] = privateKey;
    data['client_email'] = clientEmail;
    data['client_id'] = clientId;
    data['auth_uri'] = authUri;
    data['token_uri'] = tokenUri;
    data['auth_provider_x509_cert_url'] = authProviderX509CertUrl;
    data['client_x509_cert_url'] = clientX509CertUrl;
    data['universe_domain'] = universeDomain;
    return data;
  }
}

