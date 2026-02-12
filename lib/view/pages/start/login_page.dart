import 'package:flutter/material.dart';
import 'package:mindisle_client/view/pages/home_page.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static final route = AppRoute<void>(
    path: '/login',
    builder: (_) => const LoginPage(),
    middlewares: [
      (context, route) => !route.alreadyIn,
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            HomePage.route.replace(context);
          },
          child: const Text('Mock login success'),
        ),
      ),
    );
  }
}
