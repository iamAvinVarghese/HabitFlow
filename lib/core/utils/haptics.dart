import 'package:flutter/services.dart';

/// Premium Haptics Utility for HabitFlow
///
/// Provides ergonomic, comfortable, and tactile haptic feedback functions.
/// Soft and crisp clicks are used for navigation and selection,
/// while satisfying double-taps/impacts are used for completing habits and tasks.

class AppHaptics {
  /// Ultra-soft, comfortable tick for pickers, tabs, toggles, and item selection.
  static void selection() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Soft tactile tap for standard buttons, cards, and interactive chips.
  static void light() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Crisp, solid feedback for opening modals, saving forms, and primary actions.
  static void medium() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Deep, distinct impact for destructive or high-importance actions (delete, clear).
  static void heavy() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Rewarding, premium double-pulse feedback when completing a task or habit.
  static void success() async {
    try {
      HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 60));
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Distinct double-impact feedback for errors or warnings.
  static void warning() async {
    try {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ergonomic Callback Wrappers
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps a callback with a gentle selection click (ideal for tabs, pickers, chips).
T hapticSelection<T extends Function?>(T callback) {
  if (callback == null) return null as T;

  if (callback is void Function()) {
    final void Function() cb = callback;
    return (() {
      AppHaptics.selection();
      cb();
    }) as T;
  }

  final Function cb = callback;
  return ((dynamic arg) {
    AppHaptics.selection();
    return cb(arg);
  }) as T;
}

/// Wraps a callback with a soft, comfortable light impact (ideal for buttons, cards).
T hapticLight<T extends Function?>(T callback) {
  if (callback == null) return null as T;

  if (callback is void Function()) {
    final void Function() cb = callback;
    return (() {
      AppHaptics.light();
      cb();
    }) as T;
  }

  final Function cb = callback;
  return ((dynamic arg) {
    AppHaptics.light();
    return cb(arg);
  }) as T;
}

/// Wraps a callback with a crisp medium impact (ideal for saves, primary actions).
T hapticMedium<T extends Function?>(T callback) {
  if (callback == null) return null as T;

  if (callback is void Function()) {
    final void Function() cb = callback;
    return (() {
      AppHaptics.medium();
      cb();
    }) as T;
  }

  final Function cb = callback;
  return ((dynamic arg) {
    AppHaptics.medium();
    return cb(arg);
  }) as T;
}

/// Wraps a callback with a rewarding, tactile success pulse (ideal for completions).
T hapticSuccess<T extends Function?>(T callback) {
  if (callback == null) return null as T;

  if (callback is void Function()) {
    final void Function() cb = callback;
    return (() {
      AppHaptics.success();
      cb();
    }) as T;
  }

  final Function cb = callback;
  return ((dynamic arg) {
    AppHaptics.success();
    return cb(arg);
  }) as T;
}

/// Wraps a callback with a heavy impact (ideal for deletes, resets).
T hapticHeavy<T extends Function?>(T callback) {
  if (callback == null) return null as T;

  if (callback is void Function()) {
    final void Function() cb = callback;
    return (() {
      AppHaptics.heavy();
      cb();
    }) as T;
  }

  final Function cb = callback;
  return ((dynamic arg) {
    AppHaptics.heavy();
    return cb(arg);
  }) as T;
}

/// Compatibility redirect for 1-argument callbacks.
T hapticLight1<T extends Function?>(T callback) => hapticLight<T>(callback);
