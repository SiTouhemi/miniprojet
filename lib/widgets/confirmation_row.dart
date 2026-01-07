import 'package:flutter/material.dart';

/// A widget that displays label-value pairs with predictable sizing
/// to prevent layout calculation failures in dialogs.
///
/// This widget replaces complex Row layouts with MainAxisAlignment.spaceBetween
/// that can cause rendering issues when text lengths vary dynamically.
class ConfirmationRow extends StatelessWidget {
  const ConfirmationRow({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.padding,
    this.spacing,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final EdgeInsets? padding;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4.0),
      child: _buildSafeRow(context),
    );
  }

  /// Builds a safe row layout that prevents sizing issues
  Widget _buildSafeRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a more predictable layout approach
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label with fixed constraints
                SizedBox(
                  width: constraints.maxWidth * 0.4,
                  child: Text(
                    label,
                    style: labelStyle ?? _getDefaultLabelStyle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing ?? 8.0),
                // Value with flexible constraints
                Expanded(
                  child: Text(
                    value,
                    style: valueStyle ?? _getDefaultValueStyle(context),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Gets the default label text style
  TextStyle _getDefaultLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ) ??
        TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14.0,
        );
  }

  /// Gets the default value text style
  TextStyle _getDefaultValueStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF005BAA),
            ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF005BAA),
          fontSize: 14.0,
        );
  }
}

/// Alternative implementation using Table for even more predictable layout
class ConfirmationRowTable extends StatelessWidget {
  const ConfirmationRowTable({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.padding,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4.0),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(3),
        },
        children: [
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  label,
                  style: labelStyle ?? _getDefaultLabelStyle(context),
                ),
              ),
              Text(
                value,
                style: valueStyle ?? _getDefaultValueStyle(context),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Gets the default label text style
  TextStyle _getDefaultLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ) ??
        TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14.0,
        );
  }

  /// Gets the default value text style
  TextStyle _getDefaultValueStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF005BAA),
            ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF005BAA),
          fontSize: 14.0,
        );
  }
}
