import 'package:flutter/material.dart';

/// Bottom navigation bar có hiệu ứng "chất lỏng" di chuyển giữa các tab.
/// Blob indicator trượt mượt từ tab cũ → tab mới, kéo giãn khi di chuyển.
class LiquidNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidNavItem> items;

  const LiquidNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<LiquidNavBar> createState() => _LiquidNavBarState();
}

class _LiquidNavBarState extends State<LiquidNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late double _currentPos; // vị trí hiện tại (liên tục, 0.0 → itemCount-1)

  @override
  void initState() {
    super.initState();
    _currentPos = widget.currentIndex.toDouble();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant LiquidNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animateTo(widget.currentIndex.toDouble());
    }
  }

  void _animateTo(double target) {
    final begin = _currentPos;
    final tween = Tween<double>(begin: begin, end: target);

    _slideCtrl.reset();

    late final Animation<double> anim;
    anim = tween.animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOutCubic),
    );

    void listener() {
      _currentPos = anim.value;
    }

    anim.addListener(listener);
    _slideCtrl.forward().then((_) {
      anim.removeListener(listener);
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  /// Tính hệ số stretch dựa vào tốc độ di chuyển (velocity) của blob.
  double get _stretch {
    if (!_slideCtrl.isAnimating) return 1.0;
    // Stretch mạnh nhất ở giữa animation
    final t = _slideCtrl.value;
    // Curve: 0→1→0 (mạnh nhất ở giữa)
    final s = 4.0 * t * (1.0 - t); // parabola peak=1 tại t=0.5
    return 1.0 + s * 0.5; // max stretch = 1.5x
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.items.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: CustomPaint(
            painter: _LiquidBlobPainter(
              position: _currentPos,
              stretch: _stretch,
              itemCount: itemCount,
              color: const Color(0xFF1565C0).withValues(alpha: 0.12),
            ),
            child: Row(
              children: List.generate(itemCount, (i) {
                final isActive = widget.currentIndex == i;
                // Khoảng cách từ blob tới item → dùng để scale/lift icon gần blob
                final dist = (_currentPos - i).abs();
                final proximity = (1.0 - dist.clamp(0.0, 1.0)); // 1=tại blob, 0=xa
                final scale = 1.0 + proximity * 0.12;
                final yOffset = proximity * -3.0;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onTap(i),
                    child: Transform.translate(
                      offset: Offset(0, yOffset),
                      child: Transform.scale(
                        scale: scale,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isActive
                                  ? widget.items[i].activeIcon
                                  : widget.items[i].icon,
                              color: isActive
                                  ? const Color(0xFF1565C0)
                                  : Colors.grey[500],
                              size: 24,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.items[i].label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isActive
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item cho LiquidNavBar
class LiquidNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const LiquidNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Painter vẽ blob "chất lỏng" trượt giữa các tab.
/// [position] là giá trị liên tục (vd: 0.0 → 2.0 khi trượt từ tab 0 → tab 2).
class _LiquidBlobPainter extends CustomPainter {
  final double position;
  final double stretch;
  final int itemCount;
  final Color color;

  _LiquidBlobPainter({
    required this.position,
    required this.stretch,
    required this.itemCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final itemWidth = size.width / itemCount;
    final centerX = itemWidth * position + itemWidth / 2;
    final centerY = size.height / 2;

    // Blob kéo giãn ngang khi di chuyển, co lại khi dừng
    final blobWidth = itemWidth * 0.82 * stretch;
    final blobHeight = 48.0 / (stretch * 0.7 + 0.3); // co dọc khi giãn ngang

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Vẽ blob chính — hình viên con nhộng
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: blobWidth,
        height: blobHeight,
      ),
      Radius.circular(blobHeight / 2),
    );
    canvas.drawRRect(rect, paint);

    // Vẽ "đuôi" trail khi đang trượt
    if (stretch > 1.08) {
      final intensity = ((stretch - 1.0) * 2.0).clamp(0.0, 1.0);
      final trailPaint = Paint()
        ..color = color.withValues(alpha: color.a * 0.35 * intensity)
        ..style = PaintingStyle.fill;

      final trailR = 5.0 * intensity;
      // 2 giọt nhỏ theo 2 hướng
      canvas.drawCircle(
        Offset(centerX - blobWidth * 0.52 - trailR, centerY),
        trailR,
        trailPaint,
      );
      canvas.drawCircle(
        Offset(centerX + blobWidth * 0.52 + trailR, centerY),
        trailR,
        trailPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidBlobPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.stretch != stretch;
  }
}
