import 'package:flutter/material.dart';

enum AppListTilePosition { single, first, middle, last }

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.leadingIcon,
    this.trailing,
    this.trailingIcon,
    this.onTap,
    this.onLongPress,
    this.contentPadding,
    this.paddingTop = 10,
    this.paddingBottom = 10,
    this.horizontalPadding = 16,
    this.titleSubtitleSpacing = 2,
    this.leadingGap = 12,
    this.trailingGap = 12,
    this.borderRadius,
    this.autoBorderRadius = true,
    this.position = AppListTilePosition.middle,
    this.autoRadius = 18,
  });

  final Widget title;
  final Widget? subtitle;

  final Widget? leading;
  final IconData? leadingIcon;

  final Widget? trailing;
  final IconData? trailingIcon;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final EdgeInsetsGeometry? contentPadding;
  final double paddingTop;
  final double paddingBottom;
  final double horizontalPadding;
  final double titleSubtitleSpacing;
  final double leadingGap;
  final double trailingGap;

  // If provided, manual value has highest priority.
  final BorderRadiusGeometry? borderRadius;

  // When enabled, border radius will be derived by [position].
  final bool autoBorderRadius;
  final AppListTilePosition position;
  final double autoRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final listTileTheme = theme.listTileTheme;
    final effectiveRadius = borderRadius ?? _resolveAutoRadius();
    final resolvedRadius = effectiveRadius.resolve(Directionality.of(context));
    final resolvedPadding =
        contentPadding ??
        EdgeInsets.fromLTRB(
          horizontalPadding,
          paddingTop,
          horizontalPadding,
          paddingBottom,
        );
    final effectiveLeading = leading ?? _iconOrNull(leadingIcon);
    final effectiveTrailing = trailing ?? _iconOrNull(trailingIcon);
    final titleStyle =
        listTileTheme.titleTextStyle ?? theme.textTheme.bodyMedium;
    final subtitleStyle =
        listTileTheme.subtitleTextStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        );

    Widget content = Padding(
      padding: resolvedPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (effectiveLeading != null) ...[
            IconTheme(
              data: IconThemeData(
                color: listTileTheme.iconColor ?? colorScheme.onSurfaceVariant,
              ),
              child: effectiveLeading,
            ),
            SizedBox(width: leadingGap),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle.merge(style: titleStyle, child: title),
                if (subtitle != null) ...[
                  SizedBox(height: titleSubtitleSpacing),
                  DefaultTextStyle.merge(
                    style: subtitleStyle,
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (effectiveTrailing != null) ...[
            SizedBox(width: trailingGap),
            IconTheme(
              data: IconThemeData(
                color: listTileTheme.iconColor ?? colorScheme.onSurfaceVariant,
              ),
              child: DefaultTextStyle.merge(
                style:
                    listTileTheme.leadingAndTrailingTextStyle ??
                    theme.textTheme.bodySmall,
                child: effectiveTrailing,
              ),
            ),
          ],
        ],
      ),
    );

    content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: resolvedRadius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: content,
      ),
    );

    if (resolvedRadius != BorderRadius.zero) {
      return ClipRRect(borderRadius: resolvedRadius, child: content);
    }
    return content;
  }

  BorderRadius _resolveAutoRadius() {
    if (!autoBorderRadius) return BorderRadius.zero;
    return switch (position) {
      AppListTilePosition.single => BorderRadius.circular(autoRadius),
      AppListTilePosition.first => BorderRadius.vertical(
        top: Radius.circular(autoRadius),
      ),
      AppListTilePosition.middle => BorderRadius.zero,
      AppListTilePosition.last => BorderRadius.vertical(
        bottom: Radius.circular(autoRadius),
      ),
    };
  }

  Widget? _iconOrNull(IconData? iconData) {
    if (iconData == null) return null;
    return Icon(iconData);
  }
}
