import 'package:flutter/material.dart';
import 'package:mindisle_client/core/static.dart';
import 'package:mindisle_client/view/pages/home/home_page/card_home.dart';
import 'package:mindisle_client/view/pages/home/profile_page.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onRouteRequested,
  });

  final void Function(AppRouteBase route) onRouteRequested;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appDisplayName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              onRouteRequested(ProfilePage.route);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: const HomeIconTextTile(
                  icon: Icons.link,
                  title: '绑定医生',
                  subtitle: '绑定医生以使用完整服务',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
