class HashTagData {
  final String? id;
  final String? hashTag;
  final int? totalHashTagUsedCount;

  HashTagData({this.id, this.hashTag, this.totalHashTagUsedCount});

  factory HashTagData.fromJson(Map<String, dynamic> json) {
    return HashTagData(
      id: json['id'] as String?,
      hashTag: json['name'] as String? ?? json['hashTag'] as String?,
      totalHashTagUsedCount: json['usage_count'] as int? ?? json['totalHashTagUsedCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': hashTag,
    'usage_count': totalHashTagUsedCount,
  };
}
