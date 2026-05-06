import 'hash_tag_data.dart';
import 'package:opole/pages/preview_hash_tag_page/model/hash_tag_data.dart';

class FetchHashTagModel {
  final List<HashTagData>? data;

  FetchHashTagModel({this.data});

  factory FetchHashTagModel.fromJson(Map<String, dynamic> json) {
    return FetchHashTagModel(
      data: (json['data'] as List?)?.map((e) => HashTagData.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {'data': data?.map((e) => e.toJson()).toList()};
}
