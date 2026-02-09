import 'package:mindisle_client/data/storage/hive_pref_tool.dart';

abstract final class AppPrefs {

  static const favoriteServerIds = PrefVar<List<String>>(
    'favorite_server_ids',
    defaultValue: <String>[],
    decode: _decodeStringList,
  );

  static const featureFlags = PrefVar<Map<String, dynamic>>(
    'feature_flags',
    defaultValue: <String, dynamic>{},
    decode: _decodeStringDynamicMap,
  );
}

List<String> _decodeStringList(Object? raw) {
  if (raw is List) return raw.map((e) => e.toString()).toList();
  return const <String>[];
}

Map<String, dynamic> _decodeStringDynamicMap(Object? raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const <String, dynamic>{};
}