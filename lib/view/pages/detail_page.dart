import 'package:flutter/material.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class DetailPage extends StatelessWidget {
  final String message;

  const DetailPage(this.message, {super.key});

  static final route = AppRouteArg<void, String>(
    path: '/detail',
    builder: DetailPage.new,
    middlewares: [
      // 防止重复进入
          (context, route) => !route.alreadyIn,
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: Center(child: Text(message)),
    );
  }
}
