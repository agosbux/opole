// lib/pages/profile_page/profile_model.dart
class ProfileModel {
  final String id;
  final String username;
  final String? photoUrl;
  final String? fullName;
  final String? email;
  final String? telefono;
  final int level;
  final int reputation;
  final int puntos;
  final int xp;
  final String? province;
  final String? locality;
  final String? country;
  final String? genero;
  final bool verificadoMail;
  final bool verificadoWhatsapp;
  final bool verificadoFacebook;
  final bool verificadoExterno;
  final bool showPhone;
  final bool showEmail;
  final bool showFullName;
  final bool showLocation;
  final bool datosSensiblesOn;
  final bool profileCompleted;
  final int reelsSemana;
  final int reelsMes;
  final int reelsActivos;
  final int loQuieroHoy;
  final int loQuieroReceived;
  final int matchesCompletados;
  final String? indicadorRespuesta;
  final Map<String, dynamic>? progresoSiguienteNivel;
  final Map<String, dynamic>? limites;
  final bool isOwner;

  ProfileModel({
    required this.id,
    required this.username,
    this.photoUrl,
    this.fullName,
    this.email,
    this.telefono,
    required this.level,
    required this.reputation,
    required this.puntos,
    required this.xp,
    this.province,
    this.locality,
    this.country,
    this.genero,
    required this.verificadoMail,
    required this.verificadoWhatsapp,
    required this.verificadoFacebook,
    required this.verificadoExterno,
    required this.showPhone,
    required this.showEmail,
    required this.showFullName,
    required this.showLocation,
    required this.datosSensiblesOn,
    required this.profileCompleted,
    required this.reelsSemana,
    required this.reelsMes,
    required this.reelsActivos,
    required this.loQuieroHoy,
    required this.loQuieroReceived,
    required this.matchesCompletados,
    this.indicadorRespuesta,
    this.progresoSiguienteNivel,
    this.limites,
    required this.isOwner,
  });

  // ===================================================================
  // ✅ NUEVO: copyWith para actualizaciones inmutables (patrón Flutter estándar)
  // ===================================================================
  ProfileModel copyWith({
    String? id,
    String? username,
    String? photoUrl,
    String? fullName,
    String? email,
    String? telefono,
    int? level,
    int? reputation,
    int? puntos,
    int? xp,
    String? province,
    String? locality,
    String? country,
    String? genero,
    bool? verificadoMail,
    bool? verificadoWhatsapp,
    bool? verificadoFacebook,
    bool? verificadoExterno,
    bool? showPhone,
    bool? showEmail,
    bool? showFullName,
    bool? showLocation,
    bool? datosSensiblesOn,
    bool? profileCompleted,
    int? reelsSemana,
    int? reelsMes,
    int? reelsActivos,
    int? loQuieroHoy,
    int? loQuieroReceived,
    int? matchesCompletados,
    String? indicadorRespuesta,
    Map<String, dynamic>? progresoSiguienteNivel,
    Map<String, dynamic>? limites,
    bool? isOwner,
    DateTime? updatedAt, // ✅ Parámetro extra para metadata de actualización (se ignora si no se usa)
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      level: level ?? this.level,
      reputation: reputation ?? this.reputation,
      puntos: puntos ?? this.puntos,
      xp: xp ?? this.xp,
      province: province ?? this.province,
      locality: locality ?? this.locality,
      country: country ?? this.country,
      genero: genero ?? this.genero,
      verificadoMail: verificadoMail ?? this.verificadoMail,
      verificadoWhatsapp: verificadoWhatsapp ?? this.verificadoWhatsapp,
      verificadoFacebook: verificadoFacebook ?? this.verificadoFacebook,
      verificadoExterno: verificadoExterno ?? this.verificadoExterno,
      showPhone: showPhone ?? this.showPhone,
      showEmail: showEmail ?? this.showEmail,
      showFullName: showFullName ?? this.showFullName,
      showLocation: showLocation ?? this.showLocation,
      datosSensiblesOn: datosSensiblesOn ?? this.datosSensiblesOn,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      reelsSemana: reelsSemana ?? this.reelsSemana,
      reelsMes: reelsMes ?? this.reelsMes,
      reelsActivos: reelsActivos ?? this.reelsActivos,
      loQuieroHoy: loQuieroHoy ?? this.loQuieroHoy,
      loQuieroReceived: loQuieroReceived ?? this.loQuieroReceived,
      matchesCompletados: matchesCompletados ?? this.matchesCompletados,
      indicadorRespuesta: indicadorRespuesta ?? this.indicadorRespuesta,
      progresoSiguienteNivel: progresoSiguienteNivel ?? this.progresoSiguienteNivel,
      limites: limites ?? this.limites,
      isOwner: isOwner ?? this.isOwner,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json, {String? viewerId}) {
    final isOwner = (viewerId != null && viewerId == json['id']);
    
    return ProfileModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      photoUrl: json['photo_url'],
      fullName: json['full_name'],
      email: json['email'],
      telefono: json['telefono'],
      level: json['level'] ?? 1,
      reputation: json['reputation'] ?? 0,
      puntos: json['puntos'] ?? 0,
      xp: json['xp'] ?? 0,
      province: json['province'],
      locality: json['locality'],
      country: json['country'],
      genero: json['genero'],
      verificadoMail: json['verificado_mail'] ?? false,
      verificadoWhatsapp: json['verificado_whatsapp'] ?? false,
      verificadoFacebook: json['verificado_facebook'] ?? false,
      verificadoExterno: json['verificado_externo'] ?? false,
      showPhone: json['show_phone'] ?? true,
      showEmail: json['show_email'] ?? true,
      showFullName: json['show_full_name'] ?? true,
      showLocation: json['show_location'] ?? true,
      datosSensiblesOn: json['datos_sensibles_on'] ?? true,
      profileCompleted: json['profile_completed'] ?? false,
      reelsSemana: json['reels_semana'] ?? 0,
      reelsMes: json['reels_mes'] ?? 0,
      reelsActivos: json['reels_activos'] ?? 0,
      loQuieroHoy: json['lo_quiero_hoy'] ?? 0,
      loQuieroReceived: json['lo_quiero_received'] ?? 0,
      matchesCompletados: json['matches_completados'] ?? 0,
      indicadorRespuesta: json['indicador_respuesta'],
      progresoSiguienteNivel: json['progreso_siguiente_nivel'] != null
          ? Map<String, dynamic>.from(json['progreso_siguiente_nivel'])
          : null,
      limites: json['limites'] != null
          ? Map<String, dynamic>.from(json['limites'])
          : null,
      isOwner: isOwner,
    );
  }

  // ✅ Helper opcional: toJson para serialización (útil para debugging o sync)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'photo_url': photoUrl,
      'full_name': fullName,
      'email': email,
      'telefono': telefono,
      'level': level,
      'reputation': reputation,
      'puntos': puntos,
      'xp': xp,
      'province': province,
      'locality': locality,
      'country': country,
      'genero': genero,
      'verificado_mail': verificadoMail,
      'verificado_whatsapp': verificadoWhatsapp,
      'verificado_facebook': verificadoFacebook,
      'verificado_externo': verificadoExterno,
      'show_phone': showPhone,
      'show_email': showEmail,
      'show_full_name': showFullName,
      'show_location': showLocation,
      'datos_sensibles_on': datosSensiblesOn,
      'profile_completed': profileCompleted,
      'reels_semana': reelsSemana,
      'reels_mes': reelsMes,
      'reels_activos': reelsActivos,
      'lo_quiero_hoy': loQuieroHoy,
      'lo_quiero_received': loQuieroReceived,
      'matches_completados': matchesCompletados,
      'indicador_respuesta': indicadorRespuesta,
      'progreso_siguiente_nivel': progresoSiguienteNivel,
      'limites': limites,
      'is_owner': isOwner,
    };
  }

  double get completionPercentage {
    int filled = 0;
    int total = 0;
    if (username.isNotEmpty) filled++;
    total++;
    if (genero != null) filled++;
    total++;
    if (province != null && locality != null) filled++;
    total++;
    if (verificadoWhatsapp) filled++;
    total++;
    if (verificadoFacebook) filled++;
    total++;
    return filled / total;
  }
}