// lib/core/feed/feed_execution_context.dart
// ✅ Contexto inmutable para coordinadores
// ✅ Zero estado compartido stale
// ✅ Validación de generación integrada

import 'package:flutter/foundation.dart';

@immutable
class FeedExecutionContext {
  const FeedExecutionContext({
    required this.generation,
    required this.requestId,
    required this.userId,
    required this.currentIndex,
    this.isUserPaused = false,
    this.hasMore = true,
    this.isLoading = false,
  });

  final int generation;
  final int requestId;
  final String? userId;
  final int currentIndex;
  final bool isUserPaused;
  final bool hasMore;
  final bool isLoading;

  /// ✅ Validación anti-race
  bool isStale({required int expectedGeneration}) => generation != expectedGeneration;

  FeedExecutionContext copyWith({
    int? generation,
    int? requestId,
    String? userId,
    int? currentIndex,
    bool? isUserPaused,
    bool? hasMore,
    bool? isLoading,
  }) => FeedExecutionContext(
    generation: generation ?? this.generation,
    requestId: requestId ?? this.requestId,
    userId: userId ?? this.userId,
    currentIndex: currentIndex ?? this.currentIndex,
    isUserPaused: isUserPaused ?? this.isUserPaused,
    hasMore: hasMore ?? this.hasMore,
    isLoading: isLoading ?? this.isLoading,
  );
}