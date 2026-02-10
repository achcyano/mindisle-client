import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

typedef PrefDecode<T> = T Function(Object? raw);
typedef PrefEncode<T> = Object? Function(T value);
typedef PrefJsonFactory<T> = T Function(Map<String, dynamic> json);
typedef PrefJsonToMap<T> = Map<String, dynamic> Function(T value);

/// Core Hive-based preference tool.
final class HivePrefTool {
  HivePrefTool._();

  static final instance = HivePrefTool._();

  Box<dynamic>? _box;

  bool get isReady => _box != null;

  Box<dynamic> get _safeBox {
    final box = _box;
    if (box == null) {
      throw StateError('HivePrefTool is not initialized. Call init() first.');
    }
    return box;
  }

  Future<void> init({
    String boxName = 'app_preferences',
    HiveCipher? cipher,
    String? path,
  }) async {
    if (_box != null) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(
      boxName,
      encryptionCipher: cipher,
      path: path,
    );
  }

  T read<T>(PrefVar<T> pref) {
    final raw = _safeBox.get(pref.key);
    if (raw == null) return pref.defaultValue;
    if (raw is T) return raw;

    final decode = pref.decode;
    if (decode == null) {
      debugPrint(
        '[HivePrefTool] Type mismatch key=${pref.key}, expected=$T, actual=${raw.runtimeType}.',
      );
      return pref.defaultValue;
    }

    try {
      return decode(raw);
    } catch (e) {
      debugPrint('[HivePrefTool] Decode failed key=${pref.key}: $e');
      return pref.defaultValue;
    }
  }

  Future<void> write<T>(PrefVar<T> pref, T value) async {
    final encoded = pref.encode?.call(value) ?? value;
    await _safeBox.put(pref.key, encoded);
  }

  Future<void> remove(PrefVar<dynamic> pref) async {
    await _safeBox.delete(pref.key);
  }

  bool contains(PrefVar<dynamic> pref) {
    return _safeBox.containsKey(pref.key);
  }

  Future<void> clearAll() async {
    await _safeBox.clear();
  }

  Stream<T> watch<T>(PrefVar<T> pref, {bool emitCurrent = true}) async* {
    if (emitCurrent) yield read(pref);
    await for (final _ in _safeBox.watch(key: pref.key)) {
      yield read(pref);
    }
  }
}

/// One preference variable definition.
///
/// Add a new preference by adding one line in `app_prefs.dart`.
final class PrefVar<T> {
  const PrefVar(
      this.key, {
        required this.defaultValue,
        this.decode,
        this.encode,
      });

  final String key;
  final T defaultValue;
  final PrefDecode<T>? decode;
  final PrefEncode<T>? encode;

  T get value => HivePrefTool.instance.read(this);
  set value(T newValue) {
    unawaited(HivePrefTool.instance.write(this, newValue));
  }

  Future<void> set(T newValue) {
    return HivePrefTool.instance.write(this, newValue);
  }

  Future<void> remove() {
    return HivePrefTool.instance.remove(this);
  }

  bool get exists => HivePrefTool.instance.contains(this);

  Stream<T> watch({bool emitCurrent = true}) {
    return HivePrefTool.instance.watch(this, emitCurrent: emitCurrent);
  }

  factory PrefVar.json(
      String key, {
        required T defaultValue,
        required PrefJsonFactory<T> fromJson,
        required PrefJsonToMap<T> toJson,
      }) {
    return PrefVar<T>(
      key,
      defaultValue: defaultValue,
      decode: (raw) {
        if (raw is Map) {
          return fromJson(Map<String, dynamic>.from(raw));
        }
        if (raw is String) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          return fromJson(map);
        }
        throw StateError('Unsupported json raw type: ${raw.runtimeType}');
      },
      encode: (value) => toJson(value),
    );
  }
}
