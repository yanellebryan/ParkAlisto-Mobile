import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

enum GlassButtonVariant { primary, destructive, ghost }

class GlassButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final GlassButtonVariant variant;
  final bool isFullWidth;
  
  const GlassButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.variant = GlassButtonVariant.primary,
    this.isFullWidth = false,
  }) : super(key: key);

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 150),
       reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate( // 0.97 scale — UNCHANGED
      CurvedAnimation(
        parent: _animController, 
        curve: AppTheme.appleEaseOut, // UNCHANGED
        reverseCurve: Curves.easeOutCubic,
      )
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animController.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animController.reverse();
  }

  Color _getTintColor(BuildContext context) {
    switch (widget.variant) {
      case GlassButtonVariant.primary:
        return AppTheme.brandGreen.withOpacity(0.18);
      case GlassButtonVariant.destructive:
        return AppTheme.destructiveDark.withOpacity(0.3); // Red — UNCHANGED
      case GlassButtonVariant.ghost:
        return Colors.white.withOpacity(0.35);
    }
  }

  Color _getBorderColor(BuildContext context) {
    switch (widget.variant) {
      case GlassButtonVariant.primary:
        return AppTheme.brandGreen.withOpacity(0.45);
      case GlassButtonVariant.destructive:
        return AppTheme.destructiveDark.withOpacity(0.5);
      case GlassButtonVariant.ghost:
        return Colors.white.withOpacity(0.60);
    }
  }

  Color _getLabelColor(BuildContext context) {
    switch (widget.variant) {
      case GlassButtonVariant.primary:
        return AppTheme.brandGreenDeep;
      case GlassButtonVariant.destructive:
        return AppTheme.destructiveDark;
      case GlassButtonVariant.ghost:
        return AppTheme.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tintColor = _getTintColor(context);
    final borderColor = _getBorderColor(context);
    final labelColor = _getLabelColor(context);
    
    // Add inner glow for Primary and Destructive variants
    final hasInnerGlow = widget.variant != GlassButtonVariant.ghost;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
               width: widget.isFullWidth ? double.infinity : null,
               child: child,
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            // Slightly reduce blur if pressed — UNCHANGED behavior
            filter: ImageFilter.blur(sigmaX: _isPressed ? 20.0 : 28.0, sigmaY: _isPressed ? 20.0 : 28.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12), // UNCHANGED
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.65), // Top specular sheen — brighter for light mode
                    tintColor,
                    tintColor,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: 0.5,
                ),
                boxShadow: hasInnerGlow ? [
                   // Inner glow approximation
                   BoxShadow(
                      color: Colors.white.withOpacity(0.25),
                      blurRadius: 10,
                      spreadRadius: -2,
                      offset: const Offset(0, -2),
                   )
                ] : null,
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontFamilyFallback: const ['Helvetica Neue', 'sans-serif'],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.01,
                  color: labelColor,
                ),
                child: Center(
                  widthFactor: widget.isFullWidth ? null : 1.0,
                  heightFactor: 1.0,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
