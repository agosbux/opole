import 'dart:convert';


SearchUserModel searchUserModelFromJson(String str) => SearchUserModel.fromJson(json.decode(str));
String searchUserModelToJson(SearchUserModel data) => json.encode(data.toJson());

class SearchUserModel {
  SearchUserModel({
    bool? status,
    String? message,
    List<SearchUserData>? searchData,
  }) {
    _status = status;
    _message = message;
    _searchData = searchData;
  }

  SearchUserModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    if (json['searchData'] != null) {
      _searchData = [];
      json['searchData'].forEach((v) {
        _searchData?.add(SearchUserData.fromJson(v));
      });
    }
  }
  bool? _status;
  String? _message;
  List<SearchUserData>? _searchData;
  SearchUserModel copyWith({
    bool? status,
    String? message,
    List<SearchUserData>? searchData,
  }) =>
      SearchUserModel(
        status: status ?? _status,
        message: message ?? _message,
        searchData: searchData ?? _searchData,
      );
  bool? get status => _status;
  String? get message => _message;
  List<SearchUserData>? get searchData => _searchData;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_searchData != null) {
      map['searchData'] = _searchData?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

SearchUserData searchDataFromJson(String str) => SearchUserData.fromJson(json.decode(str));
String searchDataToJson(SearchUserData data) => json.encode(data.toJson());

class SearchUserData {
  SearchUserData({
    String? id,
    String? name,
    String? userName,
    String? image,
    bool? isVerified,
  }) {
    _id = id;
    _name = name;
    _userName = userName;
    _image = image;
    _isVerified = isVerified;
  }

  SearchUserData.fromJson(dynamic json) {
    _id = json['_id'];
    _name = json['name'];
    _userName = json['userName'];
    _image = json['image'];
    _isVerified = json['isVerified'];
  }
  String? _id;
  String? _name;
  String? _userName;
  String? _image;
  bool? _isVerified;
  SearchUserData copyWith({
    String? id,
    String? name,
    String? userName,
    String? image,
    bool? isVerified,
  }) =>
      SearchUserData(
        id: id ?? _id,
        name: name ?? _name,
        userName: userName ?? _userName,
        image: image ?? _image,
        isVerified: isVerified ?? _isVerified,
      );
  String? get id => _id;
  String? get name => _name;
  String? get userName => _userName;
  String? get image => _image;
  bool? get isVerified => _isVerified;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = _id;
    map['name'] = _name;
    map['userName'] = _userName;
    map['image'] = _image;
    map['isVerified'] = _isVerified;
    return map;
  }
}

