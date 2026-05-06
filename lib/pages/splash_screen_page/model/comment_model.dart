import 'dart:convert';
import 'package:opole/utils/utils.dart';

CommentModel commentModelFromJson(String str) => CommentModel.fromJson(json.decode(str));
String commentModelToJson(CommentModel data) => json.encode(data.toJson());

class CommentModel {
  CommentModel({
    bool? status,
    String? message,
    List<PostOrVideoComment>? postOrVideoComment,
  }) {
    _status = status;
    _message = message;
    _postOrVideoComment = postOrVideoComment;
  }

  CommentModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    if (json['postOrVideoComment'] != null) {
      _postOrVideoComment = [];
      json['postOrVideoComment'].forEach((v) {
        _postOrVideoComment?.add(PostOrVideoComment.fromJson(v));
      });
    }
  }
  bool? _status;
  String? _message;
  List<PostOrVideoComment>? _postOrVideoComment;
  CommentModel copyWith({
    bool? status,
    String? message,
    List<PostOrVideoComment>? postOrVideoComment,
  }) =>
      CommentModel(
        status: status ?? _status,
        message: message ?? _message,
        postOrVideoComment: postOrVideoComment ?? _postOrVideoComment,
      );
  bool? get status => _status;
  String? get message => _message;
  List<PostOrVideoComment>? get postOrVideoComment => _postOrVideoComment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_postOrVideoComment != null) {
      map['postOrVideoComment'] = _postOrVideoComment?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

PostOrVideoComment postOrVideoCommentFromJson(String str) => PostOrVideoComment.fromJson(json.decode(str));
String postOrVideoCommentToJson(PostOrVideoComment data) => json.encode(data.toJson());

class PostOrVideoComment {
  PostOrVideoComment({
    String? id,
    String? commentText,
    String? createdAt,
    String? userId,
    String? name,
    String? userName,
    String? userImage,
    int? totalLikes,
    bool? isLike,
    String? time,
  }) {
    _id = id;
    _commentText = commentText;
    _createdAt = createdAt;
    _userId = userId;
    _name = name;
    _userName = userName;
    _userImage = userImage;
    _totalLikes = totalLikes;
    _isLike = isLike;
    _time = time;
  }

  PostOrVideoComment.fromJson(dynamic json) {
    _id = json['_id'];
    _commentText = json['commentText'];
    _createdAt = json['createdAt'];
    _userId = json['userId'];
    _name = json['name'];
    _userName = json['userName'];
    _userImage = json['userImage'];
    _totalLikes = json['totalLikes'];
    _isLike = json['isLike'];
    _time = json['time'];
  }
  String? _id;
  String? _commentText;
  String? _createdAt;
  String? _userId;
  String? _name;
  String? _userName;
  String? _userImage;
  int? _totalLikes;
  bool? _isLike;
  String? _time;
  PostOrVideoComment copyWith({
    String? id,
    String? commentText,
    String? createdAt,
    String? userId,
    String? name,
    String? userName,
    String? userImage,
    int? totalLikes,
    bool? isLike,
    String? time,
  }) =>
      PostOrVideoComment(
        id: id ?? _id,
        commentText: commentText ?? _commentText,
        createdAt: createdAt ?? _createdAt,
        userId: userId ?? _userId,
        name: name ?? _name,
        userName: userName ?? _userName,
        userImage: userImage ?? _userImage,
        totalLikes: totalLikes ?? _totalLikes,
        isLike: isLike ?? _isLike,
        time: time ?? _time,
      );
  String? get id => _id;
  String? get commentText => _commentText;
  String? get createdAt => _createdAt;
  String? get userId => _userId;
  String? get name => _name;
  String? get userName => _userName;
  String? get userImage => _userImage;
  int? get totalLikes => _totalLikes;
  bool? get isLike => _isLike;
  String? get time => _time;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = _id;
    map['commentText'] = _commentText;
    map['createdAt'] = _createdAt;
    map['userId'] = _userId;
    map['name'] = _name;
    map['userName'] = _userName;
    map['userImage'] = _userImage;
    map['totalLikes'] = _totalLikes;
    map['isLike'] = _isLike;
    map['time'] = _time;
    return map;
  }
}

