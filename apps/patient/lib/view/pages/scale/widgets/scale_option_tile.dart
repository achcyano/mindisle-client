import 'package:flutter/material.dart';

class ScaleOptionTile extends StatelessWidget {
  const ScaleOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.selectedIcon,
    this.unselectedIcon,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final IconData? selectedIcon;
  final IconData? unselectedIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.secondaryContainer.withValues(
      alpha: 0.62,
    );
    final unselectedColor = colorScheme.surface;

    return Material(
      color: selected ? selectedColor : unselectedColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected
                    ? (selectedIcon ?? Icons.radio_button_checked)
                    : (unselectedIcon ?? Icons.radio_button_off_outlined),
                size: 20,
                color: selected
                    ? colorScheme.secondary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: enabled
                        ? null
                        : colorScheme.onSurface.withValues(alpha: 0.56),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
