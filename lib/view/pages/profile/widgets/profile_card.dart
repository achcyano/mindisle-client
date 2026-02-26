import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              SizedBox(height: 2),
              Text(
                title,
                style: Theme
                    .of(context)
                    .textTheme
                    .labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
