import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fixops_frontend/core/constants.dart';

/// Reusable Glassmorphism Container with blur, translucent fill, and specular border
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.opacity = 0.72,
    this.color,
    this.gradient,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.constraints,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(16);
    final effectiveBorder =
        border ?? Border.all(color: Colors.white.withAlpha(180), width: 1.2);

    final effectiveShadow =
        boxShadow ??
        [
          BoxShadow(
            color: const Color(0xFFE00000).withAlpha(18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFFA97B).withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

    Widget content = Container(
      width: width,
      height: height,
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? Colors.white).withAlpha((opacity * 255).round())
            : null,
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (color ?? Colors.white).withAlpha((opacity * 255).round()),
                (color ?? const Color(0xFFFFECCB)).withAlpha(
                  ((opacity * 0.85) * 255).round(),
                ),
              ],
            ),
        borderRadius: effectiveRadius,
        border: effectiveBorder,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    Widget glassWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: effectiveShadow,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );

    return glassWidget;
  }
}

/// Ambient background with blurred gradient orbs matching the palette:
/// #E00000 (Crimson), #FFA97B (Peach), #FFECCB (Warm Cream), #9FED72 (Lime)
class GlassBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;

  const GlassBackground({super.key, required this.child, this.showOrbs = true});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base atmospheric gradient layer
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF9F0), // Ultra light cream
                Color(0xFFFFECCB), // Palette Cream
                Color(0xFFFFF3E2), // Soft warmth
                Color(0xFFF9FDF5), // Subtle lime tint
              ],
              stops: [0.0, 0.45, 0.8, 1.0],
            ),
          ),
        ),

        // Blurred chromatic ambient orbs that shine through glass surfaces
        if (showOrbs) ...[
          // Crimson Accent Orb (top-left)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withAlpha(55),
                    AppColors.primary.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          // Peach Glow Orb (top-right)
          Positioned(
            top: 40,
            right: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withAlpha(70),
                    AppColors.secondary.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          // Lime Fresh Orb (bottom-left)
          Positioned(
            bottom: -80,
            left: 60,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentLime.withAlpha(65),
                    AppColors.accentLime.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          // Crimson Soft Orb (bottom-right)
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withAlpha(35),
                    AppColors.secondary.withAlpha(30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],

        // Child content on top
        child,
      ],
    );
  }
}
