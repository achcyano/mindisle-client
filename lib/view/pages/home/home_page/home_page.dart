import 'package:flutter/material.dart';
import 'package:mindisle_client/core/static.dart';
import 'package:mindisle_client/view/pages/home/chat_page/chat_page.dart';
import 'package:mindisle_client/view/pages/home/home_page/card_home.dart';
import 'package:mindisle_client/view/pages/home/home_page/today_mood_card.dart';
import 'package:mindisle_client/view/pages/home/medicine_page.dart';
import 'package:mindisle_client/view/pages/home/profile_page.dart';
import 'package:mindisle_client/view/pages/home/scale_page/scale_list_page.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onRouteRequested});

  final void Function(AppRouteBase route) onRouteRequested;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_outlined, size: 25),
              const SizedBox(width: 8),
              const Text(appDisplayName),
            ],
          ),
        ),
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
                subtitle: '绑定医生后可使用完整服务',
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
                      onTap: () {
                        ScaleListPage.route.goRoot(context);
                      },
                    ),
                  ),
                  Expanded(
                    child: HomeActionCard(
                      icon: Icons.messenger_outline,
                      title: '聊天',
                      onTap: () {
                        ChatPage.route.goRoot(context);
                        //onRouteRequested(ChatPage.route);
                      },
                    ),
                  ),
                ],
              ),
              const TodayMoodCard(),
            ],
          ),
        ),
      ),
    );
  }
}
