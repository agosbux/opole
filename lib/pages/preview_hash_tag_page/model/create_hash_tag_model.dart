import 'hash_tag_data.dart';

class CreateHashTagModel {
  final HashTagData? data;

  CreateHashTagModel({this.data});

  factory CreateHashTagModel.fromJson(Map<String, dynamic> json) {
    return CreateHashTagModel(
      data: json['data'] != null ? HashTagData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {'data': data?.toJson()};
}
