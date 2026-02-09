import 'package:flutter/material.dart';
import '../core/app_route.dart';
//import 'detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final route = AppRoute<void>(
    path: '/',
    builder: (_) => HomePage(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // DetailPage.route.go(context, 'Hello Flutter');
          },
          child: const Text('Go to detail'),
        ),
      ),
    );
  }
}
