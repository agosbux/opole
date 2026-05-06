// To parse this JSON data, do
//
//     final editUploadPostModel = editUploadPostModelFromJson(jsonString);

import 'dart:convert';
import 'package:opole/utils/utils.dart';

EditPostModel editUploadPostModelFromJson(String str) => EditPostModel.fromJson(json.decode(str));

String editUploadPostModelToJson(EditPostModel data) => json.encode(data.toJson());

class EditPostModel {
  bool? status;
  String? message;
  Data? data;

  EditPostModel({
    this.status,
    this.message,
    this.data,
  });

  factory EditPostModel.fromJson(Map<String, dynamic> json) => EditPostModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data?.toJson(),
      };
}

class Data {
  String? id;
  String? uniquePostId;
  String? caption;
  String? mainPostImage;
  List<String>? postImage;
  String? location;
  List<dynamic>? hashTagId;
  String? userId;
  int? shareCount;
  bool? isFake;
  DateTime? createdAt;
  DateTime? updatedAt;

  Data({
    this.id,
    this.uniquePostId,
    this.caption,
    this.mainPostImage,
    this.postImage,
    this.location,
    this.hashTagId,
    this.userId,
    this.shareCount,
    this.isFake,
    this.createdAt,
    this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["_id"],
        uniquePostId: json["uniquePostId"],
        caption: json["caption"],
        mainPostImage: json["mainPostImage"],
        postImage: json["postImage"] == null ? [] : List<String>.from(json["postImage"]!.map((x) => x)),
        location: json["location"],
        hashTagId: json["hashTagId"] == null ? [] : List<dynamic>.from(json["hashTagId"]!.map((x) => x)),
        userId: json["userId"],
        shareCount: json["shareCount"],
        isFake: json["isFake"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "uniquePostId": uniquePostId,
        "caption": caption,
        "mainPostImage": mainPostImage,
        "postImage": postImage == null ? [] : List<dynamic>.from(postImage!.map((x) => x)),
        "location": location,
        "hashTagId": hashTagId == null ? [] : List<dynamic>.from(hashTagId!.map((x) => x)),
        "userId": userId,
        "shareCount": shareCount,
        "isFake": isFake,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}

