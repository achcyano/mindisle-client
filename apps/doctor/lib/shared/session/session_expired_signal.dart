import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionExpiredTickProvider = StateProvider<int>((_) => 0);

final sessionExpiredEmitterProvider = Provider<VoidCallback>((ref) {
  return () {
    final notifier = ref.read(sessionExpiredTickProvider.notifier);
    notifier.state = notifier.state + 1;
  };
});
