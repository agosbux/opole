// lib/core/models/user_engagement_mode.dart
// ===================================================================
// USER ENGAGEMENT MODE + USER BROWSING MODE – Enums compartidos para todo el core
// ===================================================================
// ✅ Centraliza enums para evitar conflictos de importación
// ✅ Usado por: FeedPredictionEngine, VideoPreloadManager, FeedPreloadCoordinator, FeedSmartPreloadPolicy
// ===================================================================

enum UserEngagementMode { bored, engaged, exploring }

enum UserBrowsingMode { 
  normal, exploring, engaged, focused, bored 
}