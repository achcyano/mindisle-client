import 'package:flutter/material.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static final route = AppRoute<void>(
    path: '/home/profile',
    builder: (_) => const ProfilePage(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Placeholder'),
      ),
    );
  }
}
