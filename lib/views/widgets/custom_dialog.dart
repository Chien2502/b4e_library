import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final Color? confirmColor;
  final Widget? content;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    this.confirmLabel = 'Xác nhận',
    this.cancelLabel = 'Hủy',
    required this.onConfirm,
    this.confirmColor,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final effectiveIconColor = iconColor ?? context.colors.primary;
    final effectiveConfirmColor = confirmColor ?? context.colors.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: context.isDarkMode
            ? Border.all(color: context.divider, width: 0.8)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: context.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (content != null) ...[
            const SizedBox(height: 20),
            content!,
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    cancelLabel,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: effectiveConfirmColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
