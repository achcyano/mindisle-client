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
    final border = BorderRadius.circular(18);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: border,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0,  6, 0, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  icon,
                  size: 24,
              ),
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
