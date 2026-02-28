import 'package:flutter/material.dart';
import 'package:mindisle_client/view/route/app_route.dart';

class MedicinePage extends StatelessWidget {
  const MedicinePage({super.key});

  static final route = AppRoute<void>(
    path: '/home/medicine',
    builder: (_) => const MedicinePage(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("用药"),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: (){}
        ),
        body: SafeArea(
          child: Center(
            child: Text("PlaceHolder"),
          ),
        )
    );
  }
}
