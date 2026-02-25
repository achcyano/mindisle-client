import 'package:flutter/material.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  static final route = AppRoute<void>(
    path: '/info',
    builder: (_) => const InfoPage(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const Center(child: Text('Placeholder')));
  }
}