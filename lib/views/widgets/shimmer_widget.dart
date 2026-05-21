import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

/// Shimmer loading effect — gradient sáng chạy qua placeholder.
/// Dùng thay cho các khối xám tĩnh khi đang tải dữ liệu.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 14,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final isDark = context.isDarkMode;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
              end: Alignment(-1.0 + 2.0 * _ctrl.value + 1.0, 0),
              colors: isDark
                  ? [
                      Colors.grey[850]!,
                      Colors.grey[800]!,
                      Colors.grey[850]!,
                    ]
                  : [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!,
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Card shimmer dùng cho danh sách sách — mô phỏng layout BookListCard.
class BookCardShimmer extends StatelessWidget {
  const BookCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 110,
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        border: isDark
            ? Border.all(color: context.divider, width: 0.5)
            : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Cover shimmer
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
            child: ShimmerBox(width: 80, height: 110, borderRadius: 0),
          ),
          const SizedBox(width: 12),
          // Text shimmer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerBox(height: 14, width: 180, borderRadius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(height: 12, width: 120, borderRadius: 4),
                  const SizedBox(height: 12),
                  ShimmerBox(height: 20, width: 60, borderRadius: 6),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
