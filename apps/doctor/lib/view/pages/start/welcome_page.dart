import 'package:app_ui/app_ui.dart';
import 'package:doctor/core/static.dart';
import 'package:doctor/data/preference/app_prefs.dart';
import 'package:doctor/view/pages/auth/login_page.dart';
import 'package:flutter/material.dart';

class DoctorWelcomePage extends StatelessWidget {
  const DoctorWelcomePage({super.key});

  static final route = AppRoute<void>(
    path: '/welcome',
    builder: (_) => const DoctorWelcomePage(),
    middlewares: [(context, route) => !route.alreadyIn],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(flex: 2),
              Image.asset(
                'assets/icon/app_icon_foreground.png',
                width: 230,
                height: 200,
              ),
              Text(
                "心岛医生端",
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
                  onPressed: () async {
                    await AppPrefs.hasSeenWelcome.set(true);
                    if (!context.mounted) return;
                    await DoctorLoginPage.route.replace(context);
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
