// ===================================================================
// MODELO OpoleUser - VersiÃ³n Supabase (sin dependencia de Firebase)
// ===================================================================
// Reemplaza DateTime de Firebase por DateTime.parse() para ISO 8601
// ===================================================================

class OpoleUser {
  final String id;
  final String name;
  final String username;
  final String photoUrl;
  final String country;
  final String zone;
  final String? gender;
  final bool showPhone;
  final bool showEmail;
  final bool showFullName;
  final bool showLocation;
  final int level;
  final int loQuieroReceived;
  final int availableBoost;
  final DateTime? lastDailyBoostClaim;
  final String? email;
  final String? phone;

  OpoleUser({
    required this.id,
    required this.name,
    required this.username,
    required this.photoUrl,
    required this.country,
    required this.zone,
    this.gender,
    required this.showPhone,
    required this.showEmail,
    required this.showFullName,
    required this.showLocation,
    required this.level,
    required this.loQuieroReceived,
    required this.availableBoost,
    this.lastDailyBoostClaim,
    this.email,
    this.phone,
  });

  // ðŸ”¹ fromJson adaptado para Supabase (ISO 8601 strings en lugar de DateTime)
  factory OpoleUser.fromJson(Map<String, dynamic> json, String id) {
    return OpoleUser(
      id: id,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      photoUrl: json['photo_url'] ?? json['photoUrl'] ?? '',
      country: json['country'] ?? '',
      zone: json['zone'] ?? '',
      gender: json['gender'],
      showPhone: json['show_phone'] ?? json['showPhone'] ?? true,
      showEmail: json['show_email'] ?? json['showEmail'] ?? true,
      showFullName: json['show_full_name'] ?? json['showFullName'] ?? true,
      showLocation: json['show_location'] ?? json['showLocation'] ?? true,
      level: json['level'] ?? 1,
      loQuieroReceived: json['lo_quiero_received'] ?? json['loQuieroReceived'] ?? 0,
      availableBoost: json['available_boost'] ?? json['availableBoost'] ?? 0,
      // ðŸ”¹ Parsear ISO 8601 string a DateTime (Supabase) en lugar de DateTime (Firebase)
      lastDailyBoostClaim: _parseIsoDate(json['last_daily_boost_claim']),
      email: json['email'],
      phone: json['phone'],
    );
  }

  // ðŸ”¹ Helper para parsear fechas de Supabase
  static DateTime? _parseIsoDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ðŸ”¹ toJson para enviar datos a Supabase (ISO 8601 strings)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'photo_url': photoUrl,
      'country': country,
      'zone': zone,
      'gender': gender,
      'show_phone': showPhone,
      'show_email': showEmail,
      'show_full_name': showFullName,
      'show_location': showLocation,
      'level': level,
      'lo_quiero_received': loQuieroReceived,
      'available_boost': availableBoost,
      'last_daily_boost_claim': lastDailyBoostClaim?.toIso8601String(),
      'email': email,
      'phone': phone,
    };
  }
}
