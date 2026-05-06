// lib/controllers/session_controller.dart
// ===================================================================
// SESSION CONTROLLER v5.0-DELUXE - REACTIVO, ANTI-RACE & COORDINADO
// ===================================================================
// ✅ Retry SSL/Red cancelable (no bloquea feed, sin leaks)
// ✅ isReady robusto: exige perfil != null
// ✅ _dailyLoginProcessed solo en éxito (permite reintento)
// ✅ logout() pausa VideoControllerPool antes de signOut
// ✅ ProfileModel asignación optimizada (evita rebuilds innecesarios)
// ✅ Timer de retry cancelado en onClose/onLogout
// ✅ Coordinación completa con Feed/Video/Profile capas
// ===================================================================

import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:opole/core/supabase/supabase_api.dart';
import 'package:opole/core/services/supabase_client.dart' as local;
import 'package:opole/pages/profile_page/model/profile_models.dart';
import 'package:opole/pages/profile_page/profile_model.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:opole/core/feed/opole_feed_engine.dart';
// 🆕 DELUXE: Import para coordinación de recursos de video
import 'package:opole/core/video/video_controller_pool.dart';

class SessionController extends GetxController {
  static SessionController get to => Get.find();

  final supabaseAuth = local.SupabaseClient.auth;
  final supabaseApi = SupabaseApi.instance;

  static const int referralLevel4Reward = 3;

  final user = Rx<OpoleUser?>(null);
  final Rx<ProfileModel?> profile = Rx<ProfileModel?>(null);

  final _isLoading = false.obs;
  final _lastError = Rxn<String>();
  final isDataLoaded = false.obs;
  final availableBoost = 0.obs;

  bool _isLoadingData = false;
  bool _dailyLoginProcessed = false;

  StreamSubscription? _authStateSubscription;
  // 🆕 DELUXE: Timer cancelable para retry de red/SSL
  Timer? _retryTimer;

  // ==================== STATE VARIABLES ====================
  String uid = "";
  String username = "";
  String name = "";
  String photoUrl = "";
  String country = "";
  String zone = "";
  String? gender = "";
  bool profileCompleted = false;
  int level = 1;
  int engagementScore = 0;

  DateTime? lastLoginDate;
  int loginStreak = 0;
  DateTime? boostExpiration;
  DateTime? lastDailyBoostClaim;
  int dailyLoQuieroUsed = 0;
  int dailyLoQuieroLimit = 5;
  int loQuieroReceived = 0;
  DateTime? lastLoQuieroReset;

  DateTime? cooldownUntil;
  int loQuieroPenaltyLevel = 0;
  int missedSelectionsCount = 0;

  int totalPoints = 0;
  int loginPoints = 0;
  int reelPoints = 0;
  int intentionPoints = 0;
  int verificationPoints = 0;

  bool emailVerified = false;
  bool whatsappVerified = false;
  bool externalVerified = false;

  int reelsPublished = 0;
  int intencionesConcretadas = 0;
  int loginCount = 0;
  int successfulInvites = 0;

  bool showPhone = true;
  bool showEmail = true;
  bool showFullName = true;
  bool showLocation = true;

  String? referredBy;
  bool referralRewardGiven = false;

  // ==================== GETTERS ====================
  bool get isLoading => _isLoading.value;
  String? get lastError => _lastError.value;
  // 🆕 DELUXE: Exige perfil cargado para evitar inicio prematuro del feed
  bool get isReady => uid.isNotEmpty && isDataLoaded.value && profile.value != null;

  bool get isInCooldown => cooldownUntil != null && DateTime.now().isBefore(cooldownUntil!);
  Duration get cooldownRemaining => isInCooldown
      ? cooldownUntil!.difference(DateTime.now())
      : Duration.zero;

  bool get canClaimDailyBoost => lastDailyBoostClaim == null ||
      DateTime.now().difference(lastDailyBoostClaim!).inHours >= 24;

  Duration get timeUntilNextDailyBoost {
    if (lastDailyBoostClaim == null) return Duration.zero;
    final diff = lastDailyBoostClaim!.add(const Duration(hours: 24))
        .difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  // ==================== INIT ====================
  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) Get.log("⚙️ [SESSION] 🟢 Controller Initialized v5.0-DELUXE");

    _authStateSubscription = supabaseAuth.onAuthStateChange.listen((state) {
      final sessionUser = state.session?.user;
      if (sessionUser != null) {
        if (kDebugMode) Get.log("🔐 [AUTH] Usuario logueado: ${sessionUser.id}");
        uid = sessionUser.id;
        loadUserData();
      } else {
        if (kDebugMode) Get.log("🔓 [AUTH] Sin sesión - Limpiando datos");
        _clearUserData();
      }
    });
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    
    // 🆕 DELUXE: Cancelar retry para evitar ejecución post-dispose
    _retryTimer?.cancel();
    _retryTimer = null;

    _dailyLoginProcessed = false;
    _isLoadingData = false;

    super.onClose();
  }

  void _clearUserData() {
    uid = "";
    username = "";
    name = "";
    photoUrl = "";
    user.value = null;
    profile.value = null;
    isDataLoaded.value = false;
    _lastError.value = null;
    update();
    if (kDebugMode) Get.log("🧹 [SESSION] Datos limpiados");
  }

  // ==================== LOAD USER DATA ====================
  Future<void> loadUserData() async {
    if (_isLoadingData || uid.isEmpty) return;
    _isLoadingData = true;

    if (_isLoading.value) {
      _isLoadingData = false;
      return;
    }
    _isLoading.value = true;
    _lastError.value = null;
    if (kDebugMode) Get.log("🚀 [SESSION] Cargando datos para UID: $uid");

    try {
      final response = await local.SupabaseClient
          .from('users')
          .select('''
            id, username, email, photo_url, level, reputation,
            province, locality, puntos, xp, last_active_at,
            reels_semana, reels_mes, reels_activos,
            lo_quiero_hoy, lo_quiero_ultima_reset,
            dias_activos, matches_completados,
            verificado_mail, telefono_verificado, verificado_externo,
            genero, telefono,
            available_boost, boost_expiration, last_daily_boost_claim,
            lo_quiero_received, cooldown_until, lo_quiero_penalty_level,
            sin_respuesta, login_points, reel_points, intention_points,
            verification_points, login_count, successful_invites,
            show_phone, show_email, show_full_name, show_location,
            referred_by, referral_reward_given, profile_completed,
            full_name, country
          ''')
          .eq('id', uid)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) Get.log("⚠️ [SESSION] Usuario en Auth, sin perfil en DB");
        _isLoading.value = false;
        _isLoadingData = false;

        try {
          if (Get.isRegistered<FeedController>()) {
            Get.find<FeedController>().onSessionError("Perfil no encontrado");
          }
        } catch (_) {
          if (kDebugMode) Get.log("⚠️ [SESSION] FeedController no disponible");
        }

        isDataLoaded.value = true;
        _lastError.value = "Perfil no encontrado. Completa tu registro para acceder.";
        return;
      }

      // Asignación de campos desde la respuesta
      username = response['username'] ?? 'Sin username';
      name = response['full_name'] ?? username;
      photoUrl = response['photo_url'] ?? '';
      country = response['country'] ?? '';
      zone = response['locality'] ?? '';
      gender = response['genero'];
      profileCompleted = response['profile_completed'] ?? false;
      engagementScore = response['reputation'] ?? 0;
      availableBoost.value = response['available_boost'] ?? 0;

      lastLoginDate = _parseIsoDate(response['last_active_at']);
      loginStreak = response['dias_activos'] ?? 0;
      boostExpiration = _parseIsoDate(response['boost_expiration']);
      lastDailyBoostClaim = _parseIsoDate(response['last_daily_boost_claim']);

      dailyLoQuieroUsed = response['lo_quiero_hoy'] ?? 0;
      loQuieroReceived = response['lo_quiero_received'] ?? 0;
      lastLoQuieroReset = _parseIsoDate(response['lo_quiero_ultima_reset']);

      cooldownUntil = _parseIsoDate(response['cooldown_until']);
      loQuieroPenaltyLevel = response['lo_quiero_penalty_level'] ?? 0;
      missedSelectionsCount = response['sin_respuesta'] ?? 0;

      totalPoints = response['puntos'] ?? 0;
      loginPoints = response['login_points'] ?? 0;
      reelPoints = response['reel_points'] ?? 0;
      intentionPoints = response['intention_points'] ?? 0;
      verificationPoints = response['verification_points'] ?? 0;
      emailVerified = response['verificado_mail'] ?? false;
      whatsappVerified = response['telefono_verificado'] ?? false;
      externalVerified = response['verificado_externo'] ?? false;

      reelsPublished = response['reels_activos'] ?? 0;
      intencionesConcretadas = response['matches_completados'] ?? 0;
      loginCount = response['login_count'] ?? 0;
      successfulInvites = response['successful_invites'] ?? 0;

      showPhone = response['show_phone'] ?? true;
      showEmail = response['show_email'] ?? true;
      showFullName = response['show_full_name'] ?? true;
      showLocation = response['show_location'] ?? true;

      referredBy = response['referred_by'] as String?;
      referralRewardGiven = response['referral_reward_given'] ?? false;

      level = response['level'] ?? 1;
      dailyLoQuieroLimit = getDailyLoQuieroLimit(level);

      if (kDebugMode) Get.log("📊 [CALC] Nivel: $level | Límite LoQuiero: $dailyLoQuieroLimit");

      // 🆕 DELUXE: Construir ProfileModel
      final newProfile = ProfileModel(
        id: uid,
        username: username,
        photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
        fullName: name.isNotEmpty ? name : null,
        email: supabaseAuth.currentUser?.email,
        telefono: response['telefono'],
        level: level,
        reputation: engagementScore,
        puntos: totalPoints,
        xp: response['xp'] ?? 0,
        province: response['province'],
        locality: response['locality'],
        country: country.isNotEmpty ? country : null,
        genero: gender,
        verificadoMail: emailVerified,
        verificadoWhatsapp: whatsappVerified,
        verificadoFacebook: false,
        verificadoExterno: externalVerified,
        showPhone: showPhone,
        showEmail: showEmail,
        showFullName: showFullName,
        showLocation: showLocation,
        datosSensiblesOn: true,
        profileCompleted: profileCompleted,
        reelsSemana: response['reels_semana'] ?? 0,
        reelsMes: response['reels_mes'] ?? 0,
        reelsActivos: reelsPublished,
        loQuieroHoy: dailyLoQuieroUsed,
        loQuieroReceived: loQuieroReceived,
        matchesCompletados: intencionesConcretadas,
        indicadorRespuesta: null,
        progresoSiguienteNivel: null,
        limites: null,
        isOwner: true,
      );

      // 🆕 DELUXE: Asignar solo si cambió (evita rebuilds de GetX innecesarios)
      // Nota: Para máxima eficiencia, ProfileModel debería implementar operator ==
      if (profile.value == null || profile.value!.id != newProfile.id) {
        profile.value = newProfile;
      }

      _updateUserObject();
      isDataLoaded.value = true;
      _isLoading.value = false;
      update();

      if (kDebugMode) Get.log("👤 [SESSION] ✅ Perfil listo: @$username | Nivel: $level | Puntos: $totalPoints");

      // 🆕 DELUXE: Ejecutar tareas en background
      if (!_dailyLoginProcessed) {
        unawaited(handleDailyLogin().catchError((e) {
          if (kDebugMode) Get.log("⚠️ [BG] handleDailyLogin: $e");
        }));
      }
      unawaited(checkDailyReset().catchError((e) {
        if (kDebugMode) Get.log("⚠️ [BG] checkDailyReset: $e");
      }));
      unawaited(checkAndUpdateProfileCompletion().catchError((e) {
        if (kDebugMode) Get.log("⚠️ [BG] checkProfile: $e");
      }));
      unawaited(_checkReferralReward().catchError((e) {
        if (kDebugMode) Get.log("⚠️ [BG] referral: $e");
      }));
    } catch (e, stack) {
      _isLoading.value = false;
      if (kDebugMode) {
        Get.log("🔥 [SESSION] ERROR: $e");
        Get.log("📋 Stack: $stack");
      }

      // 🆕 DELUXE: Detección inteligente de errores transitorios
      final isNetworkError = e.toString().contains('SSL') ||
          e.toString().contains('Connection reset') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('BAD_RECORD');

      if (isNetworkError) {
        _retryTimer?.cancel();
        _retryTimer = Timer(const Duration(milliseconds: 1500), () {
          if (!isDataLoaded.value && uid.isNotEmpty) {
            _isLoadingData = false; // Resetear guardia para permitir reintento
            loadUserData();
          }
        });
        if (kDebugMode) Get.log("🔄 [SESSION] Error de red transitorio, reintentando en 1.5s...");
      } else {
        // Error real (DB, auth, parseo): bloquear fallback del feed
        _lastError.value = e.toString();
        isDataLoaded.value = true;
      }
    } finally {
      _isLoadingData = false;
    }
  }

  DateTime? _parseIsoDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return null;
  }

  void _updateUserObject() {
    final auth = local.SupabaseClient.currentUser;
    user.value = OpoleUser(
      id: uid,
      name: name,
      username: username,
      photoUrl: photoUrl,
      country: country,
      zone: zone,
      gender: gender,
      showPhone: showPhone,
      showEmail: showEmail,
      showFullName: showFullName,
      showLocation: showLocation,
      level: level,
      loQuieroReceived: loQuieroReceived,
      availableBoost: availableBoost.value,
      lastDailyBoostClaim: lastDailyBoostClaim,
      email: auth?.email,
      phone: auth?.phone,
    );
  }

  // ==================== LEVEL & LIMITS ====================
  int getDailyLoQuieroLimit(int level) {
    if (level >= 8) return 20;
    if (level >= 6) return 12;
    if (level >= 4) return 8;
    return 5;
  }

  Future<void> updateLevelIfNeeded() async {
    try {
      await local.SupabaseClient.rpc('calcular_nivel_usuario', params: {'p_user_id': uid});
      if (kDebugMode) Get.log("✅ [LEVEL] RPC ejecutado");
      await loadUserData();
    } catch (e) {
      if (kDebugMode) Get.log("❌ [LEVEL] Error: $e");
    }
  }

  // ==================== REFERRAL ====================
  Future<void> _checkReferralReward() async {
    if (referredBy == null || referralRewardGiven) return;
    try {
      final ref = await local.SupabaseClient.from('users')
          .select('available_boost').eq('id', referredBy).maybeSingle();
      if (ref == null) return;
      await local.SupabaseClient.from('users')
          .update({'available_boost': (ref['available_boost'] ?? 0) + referralLevel4Reward})
          .eq('id', referredBy);
      await local.SupabaseClient.from('users')
          .update({'referral_reward_given': true}).eq('id', uid);
      referralRewardGiven = true;
      if (kDebugMode) Get.log("🎉 [REFERRAL] Recompensa a $referredBy");
    } catch (e) {
      if (kDebugMode) Get.log("❌ [REFERRAL] Error: $e");
    }
  }

  Future<String> generateReferralLink() async => "https://opole.app/ref?userId=$uid";

  // ==================== DAILY LOGIN (RPC) ====================
  Future<void> handleDailyLogin() async {
    if (_dailyLoginProcessed) return;
    
    // 🆕 DELUXE: NO marcar como procesado hasta confirmar éxito del RPC
    try {
      final res = await local.SupabaseClient.rpc('claim_daily_login', params: {'p_user_id': uid});
      if (res != null && res['success'] == true) {
        _dailyLoginProcessed = true; // ✅ Solo en éxito
        if (kDebugMode) Get.log("📅 [LOGIN] ✅ ${res['message']} | Streak: ${res['streak']}");

        loginStreak = res['streak'] ?? loginStreak;
        if (res['xp_total'] != null) {
          totalPoints = res['xp_total'];
          loginPoints = res['xp_total'];
        }
        update();
        if (kDebugMode) Get.log("🔄 [LOGIN] Variables locales actualizadas");
      }
    } catch (e) {
      if (kDebugMode) Get.log("❌ [LOGIN] Error: $e");
      // No se marca _dailyLoginProcessed = true para permitir reintento en próxima sesión
    }
  }

  // ==================== POINTS SYSTEM ====================
  Future<void> addPoints({required int points, required String type, String? reason}) async {
    try {
      final valid = ['loginPoints', 'reelPoints', 'intentionPoints', 'verificationPoints'];
      if (!valid.contains(type)) throw Exception("Invalid type: $type");

      final prevTotal = totalPoints;
      final prevLogin = loginPoints;
      final prevReel = reelPoints;
      final prevIntention = intentionPoints;
      final prevVerification = verificationPoints;

      totalPoints += points;
      switch (type) {
        case 'loginPoints': loginPoints += points; break;
        case 'reelPoints': reelPoints += points; break;
        case 'intentionPoints': intentionPoints += points; intencionesConcretadas += 1; break;
        case 'verificationPoints': verificationPoints += points; break;
      }
      _updateUserObject();
      update();
      if (kDebugMode) Get.log("💎 [POINTS] UI: +$points ($type)");

      final rpcType = switch (type) {
        'loginPoints' => 'login_points',
        'reelPoints' => 'reel_points',
        'intentionPoints' => 'intention_points',
        'verificationPoints' => 'verification_points',
        _ => 'puntos',
      };

      await local.SupabaseClient.rpc('increment_user_points', params: {
        'p_user_id': uid,
        'p_points': points,
        'p_point_type': rpcType
      });
      if (kDebugMode) Get.log("✅ [POINTS] RPC sync OK");
      unawaited(updateLevelIfNeeded());
    } catch (e) {
      if (kDebugMode) Get.log("❌ [POINTS] Error: $e");
      await loadUserData(); // Rollback seguro
    }
  }

  // ==================== BOOST SYSTEM ====================
  Future<void> claimDailyBoost() async {
    if (!canClaimDailyBoost) return;
    final oldBoost = availableBoost.value;
    final oldClaim = lastDailyBoostClaim;
    availableBoost.value += 1;
    lastDailyBoostClaim = DateTime.now();
    _updateUserObject();
    update();
    try {
      await local.SupabaseClient.from('users').update({
        'available_boost': availableBoost.value,
        'last_daily_boost_claim': lastDailyBoostClaim!.toIso8601String()
      }).eq('id', uid);
    } catch (e) {
      availableBoost.value = oldBoost;
      lastDailyBoostClaim = oldClaim;
      _updateUserObject();
      update();
    }
  }

  // ==================== USE "LO QUIERO" ====================
  Future<bool> useLoQuiero(String reelId, String reelOwnerUid) async {
    if (kDebugMode) Get.log("❤️ [LOQUIERO] ▶️ Hacia Reel: $reelId");

    if (reelOwnerUid == uid) return false;
    if (isInCooldown) {
      final remaining = cooldownRemaining.inSeconds;
      Get.snackbar("⏳ Calma", "Esperá ${remaining}s antes de volver a interactuar");
      return false;
    }

    try {
      dailyLoQuieroUsed++;
      update();

      final response = await local.SupabaseClient.rpc('dar_lo_quiero', params: {
        'p_reel_id': reelId,
        'p_comprador_id': uid
      });

      if (response != null) {
        try {
          if (Get.isRegistered<OpoleFeedEngine>()) {
            OpoleFeedEngine.instance.invalidateCacheOnUserAction(uid);
          }
        } catch (_) {}

        unawaited(loadUserData().catchError((e) => null));
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) Get.log("❌ [LOQUIERO] Error: $e");
      await loadUserData();
      return false;
    }
  }

  // ==================== LOGOUT (CON RESET & COORDINACIÓN) ====================
  Future<void> logout() async {
    // 🆕 DELUXE: Cancelar timers y pausar recursos antes de cerrar sesión
    _retryTimer?.cancel();
    _retryTimer = null;
    
    try {
      await VideoControllerPool.instance.pauseAll();
    } catch (_) {}

    await supabaseAuth.signOut();

    _dailyLoginProcessed = false;
    _isLoadingData = false;
    _clearUserData();
    availableBoost.value = 0;
    update();
    if (kDebugMode) Get.log("🚪 [AUTH] Logout OK");
  }

  // ==================== RESTO DE MÉTODOS ====================
  Future<void> checkDailyReset() async {
    if (lastLoQuieroReset == null ||
        DateTime.now().difference(lastLoQuieroReset!).inHours >= 24) {
      await resetDailyCounter();
    }
  }

  Future<void> resetDailyCounter() async {
    dailyLoQuieroUsed = 0;
    lastLoQuieroReset = DateTime.now();
    _updateUserObject();
    update();
    try {
      await local.SupabaseClient.from('users')
          .update({'lo_quiero_hoy': 0, 'lo_quiero_ultima_reset': lastLoQuieroReset!.toIso8601String()})
          .eq('id', uid);
    } catch (e) {
      if (kDebugMode) Get.log('❌ [LOQUIERO] Reset error: $e');
    }
  }

  Future<void> checkAndUpdateProfileCompletion() async {
    if (username.isNotEmpty && photoUrl.isNotEmpty && zone.isNotEmpty && !profileCompleted) {
      profileCompleted = true;
      engagementScore += 10;
      _updateUserObject();
      update();
      try {
        await local.SupabaseClient.from('users')
            .update({'profile_completed': true, 'reputation': engagementScore})
            .eq('id', uid);
      } catch (e) {
        if (kDebugMode) Get.log('❌ [PROFILE] Error: $e');
      }
    }
  }

  Future<void> updatePrivacy({
    bool? showPhone,
    bool? showEmail,
    bool? showFullName,
    bool? showLocation,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (showPhone != null) { updates['show_phone'] = showPhone; this.showPhone = showPhone; }
      if (showEmail != null) { updates['show_email'] = showEmail; this.showEmail = showEmail; }
      if (showFullName != null) { updates['show_full_name'] = showFullName; this.showFullName = showFullName; }
      if (showLocation != null) { updates['show_location'] = showLocation; this.showLocation = showLocation; }
      if (updates.isEmpty) return;
      _updateUserObject();
      update();
      await local.SupabaseClient.from('users').update(updates).eq('id', uid);
    } catch (e) {
      if (kDebugMode) Get.log('❌ [PRIVACY] Error: $e');
      await loadUserData();
    }
  }

  Future<void> deleteAccount() async {
    try {
      await local.SupabaseClient.from('users')
          .update({'is_active': false, 'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', uid);
      await logout();
    } catch (e) {
      if (kDebugMode) Get.log('❌ [ACCOUNT] Error: $e');
      rethrow;
    }
  }
}