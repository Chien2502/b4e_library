import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                color: (iconColor ?? const Color(0xFF1565C0)).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: iconColor ?? const Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
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
                    style: const TextStyle(
                      color: Colors.grey,
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
                    backgroundColor: confirmColor ?? const Color(0xFF1565C0),
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
