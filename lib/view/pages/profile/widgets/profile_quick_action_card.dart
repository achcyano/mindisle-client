import 'package:flutter/material.dart';

class ProfileQuickActionCard extends StatelessWidget {
  const ProfileQuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(child: Column(children: [Icon(icon), Text(title)])),
    );
  }
}
