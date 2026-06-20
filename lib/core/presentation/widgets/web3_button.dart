import 'package:flutter/material.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';

class Web3Button extends StatefulWidget {
  const Web3Button({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = Colors.white,
    this.borderRadius = 16.0,
    this.hasGlow = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final double borderRadius;
  final bool hasGlow;

  @override
  State<Web3Button> createState() => _Web3ButtonState();
}

class _Web3ButtonState extends State<Web3Button> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final effectiveColor = isDisabled ? AppColors.divider : widget.color;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.0),
            boxShadow: [
              if (widget.hasGlow && !isDisabled)
                BoxShadow(
                  color: effectiveColor == Colors.white 
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : effectiveColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
