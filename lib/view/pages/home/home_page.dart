import 'package:flutter/material.dart';
import 'package:mindisle_client/core/static.dart';
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
      extendBodyBehindAppBar: true,
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
      body: const Center(
        child: Text('Placeholder'),
      ),
    );
  }
}
