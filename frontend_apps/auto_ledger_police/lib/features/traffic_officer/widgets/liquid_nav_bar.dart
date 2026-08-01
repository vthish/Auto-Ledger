import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class LiquidNavBar extends StatefulWidget {
  const LiquidNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  State<LiquidNavBar> createState() => _LiquidNavBarState();
}

class _LiquidNavBarState extends State<LiquidNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _animation;
  double _currentValue = 1.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selectedIndex.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _animation = AlwaysStoppedAnimation<double>(_currentValue);
  }

  @override
  void didUpdateWidget(covariant LiquidNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      final targetValue = widget.selectedIndex.toDouble();

      _animation = Tween<double>(
        begin: _currentValue,
        end: targetValue,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.fastOutSlowIn,
        ),
      );

      _controller
        ..stop()
        ..reset()
        ..forward().whenComplete(() {
          if (mounted) {
            setState(() {
              _currentValue = targetValue;
            });
          } else {
            _currentValue = targetValue;
          }
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavBarItemData(Icons.person_rounded, 'Profile'),
      _NavBarItemData(Icons.home_rounded, 'Home'),
      _NavBarItemData(Icons.settings_rounded, 'Settings'),
    ];

    return Container(
      padding: const EdgeInsets.only(left: 36, right: 36, bottom: 24),
      color: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        height: 72,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final itemWidth = barWidth / items.length;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final animationValue =
                    _controller.isAnimating ? _animation!.value : _currentValue;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size(barWidth, 72),
                      painter: _LiquidNavPainter(animationValue, items.length),
                    ),
                    Positioned(
                      top: -14,
                      left: (animationValue * itemWidth) + (itemWidth / 2) - 26,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.policeBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.policeBlue.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(items.length, (index) {
                        final distance = (animationValue - index).abs();
                        final activeFactor = (1.0 - distance).clamp(0.0, 1.0);
                        final isActive = index == widget.selectedIndex;

                        return GestureDetector(
                          onTap: () => widget.onTap(index),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: itemWidth,
                            height: 72,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.translate(
                                  offset: Offset(0, -24 * activeFactor),
                                  child: Transform.scale(
                                    scale: 0.96 + (0.08 * activeFactor),
                                    child: Icon(
                                      items[index].icon,
                                      color: isActive
                                          ? Colors.white
                                          : AppTheme.textGray,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 11,
                                  left: 0,
                                  right: 0,
                                  child: Opacity(
                                    opacity: activeFactor,
                                    child: Transform.translate(
                                      offset: Offset(0, 6 * (1 - activeFactor)),
                                      child: Center(
                                        child: Text(
                                          items[index].label,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.policeBlue,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NavBarItemData {
  final IconData icon;
  final String label;

  _NavBarItemData(this.icon, this.label);
}

class _LiquidNavPainter extends CustomPainter {
  final double animValue;
  final int count;

  _LiquidNavPainter(this.animValue, this.count);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final path = Path();
    final double itemWidth = size.width / count;
    final double centerX = (animValue * itemWidth) + (itemWidth / 2);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(36),
    );
    path.addRRect(rrect);

    final cutoutPath = Path()
      ..moveTo(0, 0)
      ..lineTo(centerX - 50, 0)
      ..cubicTo(centerX - 30, 0, centerX - 25, 45, centerX, 45)
      ..cubicTo(centerX + 22, 45, centerX + 30, 0, centerX + 50, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final finalPath = Path.combine(PathOperation.intersect, path, cutoutPath);

    canvas.drawShadow(
      finalPath,
      AppTheme.policeBlue.withValues(alpha: 0.12),
      14.0,
      true,
    );

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidNavPainter oldDelegate) {
    return oldDelegate.animValue != animValue || oldDelegate.count != count;
  }
}