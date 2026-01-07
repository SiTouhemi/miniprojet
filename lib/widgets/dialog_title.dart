import 'package:flutter/material.dart';

/// A dialog title widget that uses Column layout instead of Row
/// to prevent rendering issues with RenderIntrinsicWidth calculations.
///
/// This widget replaces the problematic Row-based title layout that causes
/// "Cannot hit test a render box with no size" errors.
class DialogTitle extends StatelessWidget {
  const DialogTitle({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.titleStyle,
    this.spacing,
    this.iconSize,
    this.useRowLayout = false,
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final TextStyle? titleStyle;
  final double? spacing;
  final double? iconSize;
  final bool useRowLayout;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return _buildTitleOnly(context);
    }

    // Use Column layout by default for safety, Row as fallback option
    return useRowLayout
        ? _buildRowLayout(context)
        : _buildColumnLayout(context);
  }

  /// Builds title without icon
  Widget _buildTitleOnly(BuildContext context) {
    return Text(
      title,
      style: titleStyle ?? _getDefaultTitleStyle(context),
    );
  }

  /// Builds safe Column-based layout (recommended)
  Widget _buildColumnLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(),
        SizedBox(height: spacing ?? 8.0),
        Text(
          title,
          style: titleStyle ?? _getDefaultTitleStyle(context),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds Row-based layout with explicit constraints (use with caution)
  Widget _buildRowLayout(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 300.0, // Explicit max width to prevent overflow
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIcon(),
            SizedBox(width: spacing ?? 12.0),
            Flexible(
              child: Text(
                title,
                style: titleStyle ?? _getDefaultTitleStyle(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the icon widget
  Widget _buildIcon() {
    return Container(
      width: iconSize ?? 40.0,
      height: iconSize ?? 40.0,
      decoration: BoxDecoration(
        color: iconBackgroundColor ?? const Color(0xFF005BAA),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: iconColor ?? Colors.white,
        size: (iconSize ?? 40.0) * 0.5,
      ),
    );
  }

  /// Gets the default title text style
  TextStyle _getDefaultTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF005BAA),
            ) ??
        const TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF005BAA),
        );
  }
}

/// A simplified dialog title that only uses text for maximum safety
class SimpleDialogTitle extends StatelessWidget {
  const SimpleDialogTitle({
    super.key,
    required this.title,
    this.style,
  });

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style ??
          Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF005BAA),
              ) ??
          const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF005BAA),
          ),
      textAlign: TextAlign.center,
    );
  }
}

/// A dialog title with icon positioned above text for guaranteed safety
class SafeIconDialogTitle extends StatelessWidget {
  const SafeIconDialogTitle({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.titleStyle,
    this.spacing,
    this.iconSize,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final TextStyle? titleStyle;
  final double? spacing;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize ?? 40.0,
          height: iconSize ?? 40.0,
          decoration: BoxDecoration(
            color: iconBackgroundColor ?? const Color(0xFF005BAA),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: (iconSize ?? 40.0) * 0.5,
          ),
        ),
        SizedBox(height: spacing ?? 8.0),
        Text(
          title,
          style: titleStyle ??
              Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF005BAA),
                  ) ??
              const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF005BAA),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
