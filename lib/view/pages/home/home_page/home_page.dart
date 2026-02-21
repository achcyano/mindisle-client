import 'package:flutter/material.dart';
import 'package:mindisle_client/core/static.dart';
import 'package:mindisle_client/view/pages/home/chat_page/chat_page.dart';
import 'package:mindisle_client/view/pages/home/home_page/card_home.dart';
import 'package:mindisle_client/view/pages/home/medicine_page.dart';
import 'package:mindisle_client/view/pages/home/profile_page.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onRouteRequested});

  final void Function(AppRouteBase route) onRouteRequested;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appDisplayName),
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
            spacing: 8,
            children: [
              const HomeActionCard(
                icon: Icons.link,
                title: '绑定医生',
                subtitle: '绑定医生以使用完整服务',
              ),
              HomeActionCard(
                icon: Icons.medical_services_outlined,
                title: '导入用药计划',
                subtitle: '可使用用药提醒等功能',
                onTap: () {
                  onRouteRequested(MedicinePage.route);
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: HomeActionCard(
                      icon: Icons.assessment_outlined,
                      title: '量表评估',
                    ),
                  ),
                  Expanded(
                    child: HomeActionCard(
                      icon: Icons.messenger_outline,
                      title: '聊天',
                      onTap: () {
                        onRouteRequested(ChatPage.route);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
