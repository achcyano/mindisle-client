import 'package:flutter/material.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class MedicinePage extends StatelessWidget {
  const MedicinePage({super.key});

  static final route = AppRoute<void>(
    path: '/home/medicine',
    builder: (_) => const MedicinePage(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const Center(child: Text('Placeholder')));
  }
}
