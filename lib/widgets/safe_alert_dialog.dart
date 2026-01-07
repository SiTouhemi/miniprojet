import 'package:flutter/material.dart';
import 'dialog_error_boundary.dart';

/// A completely custom dialog widget that avoids Flutter's AlertDialog
/// and its internal IntrinsicWidth usage that causes rendering crashes.
///
/// This widget builds a dialog from scratch using basic layout widgets
/// to ensure stable rendering without layout calculation failures.
class SafeAlertDialog extends StatelessWidget {
  const SafeAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.shape,
    this.backgroundColor,
    this.elevation,
    this.insetPadding,
    this.contentPadding,
    this.titlePadding,
    this.actionsPadding,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final ShapeBorder? shape;
  final Color? backgroundColor;
  final double? elevation;
  final EdgeInsets? insetPadding;
  final EdgeInsets? contentPadding;
  final EdgeInsets? titlePadding;
  final EdgeInsets? actionsPadding;

  @override
  Widget build(BuildContext context) {
    return DialogErrorBoundary(
      fallback: _buildFallbackDialog(context),
      onError: (details) {
        DialogErrorLogger.logError(
          errorType: 'SafeAlertDialog',
          message: details.exception.toString(),
          stackTrace: details.stack.toString(),
          context: {
            'hasTitle': title != null,
            'hasContent': content != null,
            'actionsCount': actions?.length ?? 0,
          },
        );
      },
      child: _buildCustomDialog(context),
    );
  }

  /// Builds a completely custom dialog without using AlertDialog
  Widget _buildCustomDialog(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.8).clamp(280.0, 400.0);

    return Dialog(
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
      backgroundColor:
          backgroundColor ?? Theme.of(context).dialogBackgroundColor,
      elevation: elevation ?? 24.0,
      insetPadding: insetPadding ??
          const EdgeInsets.symmetric(
            horizontal: 40.0,
            vertical: 24.0,
          ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: screenSize.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title section
            if (title != null)
              Container(
                padding: titlePadding ??
                    const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                child: title!,
              ),

            // Content section
            if (content != null)
              Flexible(
                child: Container(
                  padding: contentPadding ??
                      const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
                  child: SingleChildScrollView(
                    child: content!,
                  ),
                ),
              ),

            // Actions section
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: actionsPadding ??
                    const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: action,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a fallback dialog when the main dialog fails to render
  Widget _buildFallbackDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: 300.0,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Confirmation',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'An error occurred while displaying the dialog. '
              'Do you want to continue?',
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8.0),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
