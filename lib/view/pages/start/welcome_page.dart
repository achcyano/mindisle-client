import 'package:flutter/material.dart';
import 'package:mindisle_client/core/static.dart';
import 'package:mindisle_client/view/pages/start/login_page.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static final route = AppRoute<void>(
    path: '/welcome',
    builder: (_) => const WelcomePage(),
    middlewares: [
      (context, route) => !route.alreadyIn,
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'assets/icon/app_icon_foreground.png',
                width: 230,
                height: 200,
              ),
              const Text(
                appDisplayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              const Spacer(flex: 4),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 280,
                  child: FilledButton.tonal(
                    onPressed: () {
                      LoginPage.route.replace(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '进入$appDisplayName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 1)
            ],
          ),
        ),
      ),
    );
  }
}
