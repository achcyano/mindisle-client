import 'package:flutter/material.dart';
import 'package:mindisle_client/core/static.dart';
import 'package:mindisle_client/view/pages/login/login_page.dart';
import 'package:mindisle_client/view/route/app_route.dart';
import 'package:mindisle_client/view/widget/guided_entry_button.dart';

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
              Text(
                appDisplayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Spacer(flex: 4),
              Align(
                alignment: Alignment.center,
                child: GuidedEntryButton(
                  width: 290,
                  height: 43,
                  label: '进入$appDisplayName',
                  onPressed: () {
                    LoginPage.route.replace(context);
                  },
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
