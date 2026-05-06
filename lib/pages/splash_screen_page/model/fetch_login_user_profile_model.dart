// ===================================================================
// MODELOS DE PERFIL - VersiÃ³n Completa y Validada
// ===================================================================

class FetchProfileModel {
  bool? status;
  String? message;
  UserProfileData? userProfileData;

  FetchProfileModel({this.status, this.message, this.userProfileData});

  factory FetchProfileModel.fromJson(Map<String, dynamic> json) {
    return FetchProfileModel(
      status: json['status'],
      message: json['message'],
      userProfileData: json['userProfileData'] != null
          ? UserProfileData.fromJson(json['userProfileData'])
          : null,
    );
  }
}

class UserProfileData {
  UserData? user;
  int? totalFollowers;
  int? totalFollowing;
  int? totalLikesOfVideoPost;

  UserProfileData({this.user, this.totalFollowers, this.totalFollowing, this.totalLikesOfVideoPost});

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      totalFollowers: json['totalFollowers'],
      totalFollowing: json['totalFollowing'],
      totalLikesOfVideoPost: json['totalLikesOfVideoPost'],
    );
  }
}

class UserData {
  String? id;
  String? username;
  String? name;
  String? image;
  String? email;
  String? phone;
  String? country;
  String? zone;
  String? gender;
  int? level;
  bool? profileCompleted;
  
  // âœ… Campos adicionales para compatibilidad:
  String? userName;
  String? bio;
  bool? isVerified;
  bool? isFake;
  String? countryFlagImage;
  int? loQuieroReceived;
  int? availableBoost;
  DateTime? lastDailyBoostClaim;

  UserData({
    this.id, this.username, this.name, this.image, this.email,
    this.phone, this.country, this.zone, this.gender,
    this.level, this.profileCompleted,
    this.userName, this.bio, this.isVerified, this.isFake, this.countryFlagImage,
    this.loQuieroReceived, this.availableBoost, this.lastDailyBoostClaim,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      username: json['username'],
      name: json['name'] ?? json['username'],
      image: json['photo_url'] ?? json['avatar'] ?? json['image'],
      email: json['email'],
      phone: json['phone'],
      country: json['country'],
      zone: json['zone'],
      gender: json['gender'],
      level: json['level'],
      profileCompleted: json['profile_completed'],
      userName: json['username'] ?? json['userName'],
      bio: json['bio'],
      isVerified: json['email_verificado'] ?? json['isVerified'] ?? false,
      isFake: json['isFake'] ?? false,
      countryFlagImage: json['country_flag_image'] ?? json['countryFlagImage'],
      loQuieroReceived: json['lo_quiero_received'],
      availableBoost: json['available_boost'],
      lastDailyBoostClaim: json['last_daily_boost_claim'] != null 
          ? DateTime.tryParse(json['last_daily_boost_claim']) 
          : null,
    );
  }
}

// ===================================================================
// ProfileVideoData - TODOS LOS CAMPOS (SINTAXIS VALIDADA)
// ===================================================================
class ProfileVideoData {
  String? id;
  String? caption;
  String? videoUrl;
  String? videoImage;
  String? name;
  String? userId;
  String? userName;
  String? userImage;
  List<String>? hashTag;
  bool? isLike;
  int? totalLikes;
  int? totalComments;
  bool? isBanned;
  String? songId;
  String? songTitle;
  String? songImage;
  String? songLink;
  String? singerName;
  int? totalViews;
  String? createdAt;
  int? likes;
  int? comments;

  ProfileVideoData({
    this.id, this.caption, this.videoUrl, this.videoImage,
    this.name, this.userId, this.userName, this.userImage,
    this.hashTag, this.isLike, this.totalLikes, this.totalComments,
    this.isBanned, this.songId, this.songTitle, this.songImage,
    this.songLink, this.singerName, this.totalViews, this.createdAt,
    this.likes, this.comments,
  });

  factory ProfileVideoData.fromJson(Map<String, dynamic> json) {
    return ProfileVideoData(
      id: json['_id'] ?? json['id'],
      caption: json['caption'],
      videoUrl: json['videoUrl'],
      videoImage: json['videoImage'],
      name: json['name'],
      userId: json['userId'],
      userName: json['userName'],
      userImage: json['userImage'],
      hashTag: json['hashTag'] != null ? List<String>.from(json['hashTag']) : null,
      isLike: json['isLike'],
      totalLikes: json['totalLikes'],
      totalComments: json['totalComments'],
      isBanned: json['isBanned'],
      songId: json['songId'],
      songTitle: json['songTitle'],
      songImage: json['songImage'],
      songLink: json['songLink'],
      singerName: json['singerName'],
      totalViews: json['totalViews'],
      createdAt: json['createdAt'],
      likes: json['likes'] ?? json['totalLikes'],
      comments: json['comments'] ?? json['totalComments'],
    ); // âœ… Cierre correcto del return
  } // âœ… Cierre correcto del factory
} // âœ… Cierre correcto de la clase

// ===================================================================
// ProfilePostData - CON postImage
// ===================================================================
class ProfilePostData {
  String? id;
  String? caption;
  String? mainPostImage;
  List<String>? postImage;
  String? image;

  ProfilePostData({this.id, this.caption, this.mainPostImage, this.postImage, this.image});

  factory ProfilePostData.fromJson(Map<String, dynamic> json) {
    return ProfilePostData(
      id: json['_id'] ?? json['id'],
      caption: json['caption'],
      mainPostImage: json['mainPostImage'] ?? json['image_url'],
      postImage: json['postImage'] != null ? List<String>.from(json['postImage']) : null,
      image: json['image'] ?? json['image_url'],
    );
  }
}

// ===================================================================
// ProfileCollectionData - TODOS LOS CAMPOS DE GIFTS
// ===================================================================
class ProfileCollectionData {
  int? total;
  int? giftCoin;
  String? giftImage;
  int? giftType;
  String? id;
  String? name;
  double? price;
  String? image;

  ProfileCollectionData({
    this.total, this.giftCoin, this.giftImage, this.giftType,
    this.id, this.name, this.price, this.image,
  });

  factory ProfileCollectionData.fromJson(Map<String, dynamic> json) {
    return ProfileCollectionData(
      total: json['total'],
      giftCoin: json['giftCoin'],
      giftImage: json['giftImage'] ?? json['image'],
      giftType: json['giftType'],
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num?)?.toDouble(),
      image: json['image'] ?? json['giftImage'],
    );
  }
}

// ===================================================================
// FetchProfileVideoModel / FetchProfilePostModel / FetchProfileCollectionModel
// ===================================================================
class FetchProfileVideoModel {
  bool? status;
  String? message;
  List<ProfileVideoData>? data;
  
  FetchProfileVideoModel({this.status, this.message, this.data});
  
  factory FetchProfileVideoModel.fromJson(Map<String, dynamic> json) {
    return FetchProfileVideoModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? List<ProfileVideoData>.from(json['data'].map((x) => ProfileVideoData.fromJson(x)))
          : [],
    );
  }
}

class FetchProfilePostModel {
  bool? status;
  String? message;
  List<ProfilePostData>? data;
  
  FetchProfilePostModel({this.status, this.message, this.data});
  
  factory FetchProfilePostModel.fromJson(Map<String, dynamic> json) {
    return FetchProfilePostModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? List<ProfilePostData>.from(json['data'].map((x) => ProfilePostData.fromJson(x)))
          : [],
    );
  }
}

class FetchProfileCollectionModel {
  bool? status;
  String? message;
  List<ProfileCollectionData>? data;
  
  FetchProfileCollectionModel({this.status, this.message, this.data});
  
  factory FetchProfileCollectionModel.fromJson(Map<String, dynamic> json) {
    return FetchProfileCollectionModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? List<ProfileCollectionData>.from(json['data'].map((x) => ProfileCollectionData.fromJson(x)))
          : [],
    );
  }
}
