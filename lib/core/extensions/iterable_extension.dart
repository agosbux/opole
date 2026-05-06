// lib/core/extensions/iterable_extension.dart
// ===================================================================
// EXTENSIONES GLOBALES - Utilidades reutilizables para toda la app
// ===================================================================

/// Extensión para Iterable que permite buscar elementos opcionales sin lanzar excepción.
/// Equivalentes a `firstWhereOrNull` y `lastWhereOrNull` de `package:collection` pero sin dependencia externa.
extension IterableExtension<T> on Iterable<T> {
  /// Retorna el primer elemento que cumple la condición, o `null` si no hay ninguno.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final user = users.firstWhereOrNull((u) => u.id == '123');
  /// if (user != null) { /* hacer algo */ }
  /// ```
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  /// Retorna el último elemento que cumple la condición, o `null` si no hay ninguno.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final lastAdmin = users.lastWhereOrNull((u) => u.isAdmin);
  /// if (lastAdmin != null) { /* hacer algo */ }
  /// ```
  T? lastWhereOrNull(bool Function(T) test) {
    T? result;
    for (final element in this) {
      if (test(element)) result = element;
    }
    return result;
  }
}