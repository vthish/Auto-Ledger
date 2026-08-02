import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 28,
    this.color,
    this.gradient,
    this.blurSigma = 18,
    this.borderColor,
    this.borderWidth = 1.2,
    this.onTap,
    this.shadowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? color;
  final Gradient? gradient;
  final double blurSigma;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    final card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.82),
            gradient: gradient,
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.45),
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: (shadowColor ?? Colors.black).withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    return Container(
      margin: margin,
      child: onTap == null
          ? card
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                splashColor: AppTheme.policeBlue.withValues(alpha: 0.06),
                highlightColor: Colors.transparent,
                child: card,
              ),
            ),
    );
  }
}