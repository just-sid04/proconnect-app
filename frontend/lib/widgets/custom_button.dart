import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

/// A premium gradient button with optional glow shadow.
/// Use [isGold] for the gold-accent "primary action" style.
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isGold;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isGold = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 54,
    this.icon,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.isGold
        ? AppTheme.goldGradient
        : widget.isOutlined
            ? null
            : LinearGradient(
                colors: widget.backgroundColor != null
                    ? [widget.backgroundColor!, widget.backgroundColor!]
                    : [AppTheme.primaryColor, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

    final glowColor =
        widget.isGold ? AppTheme.accentColor : AppTheme.primaryColor;

    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isOutlined ? AppTheme.primaryColor : Colors.white),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    size: 19, color: widget.textColor ?? Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.textColor ??
                      (widget.isOutlined
                          ? AppTheme.primaryColor
                          : Colors.white),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );

    final disabled = widget.isLoading || widget.onPressed == null;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => _ctrl.forward(),
      onTapUp: disabled
          ? null
          : (_) {
              _ctrl.reverse();
              widget.onPressed?.call();
            },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.isOutlined
            ? Container(
                width: widget.width ?? double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  border: Border.all(
                      color:
                          disabled ? AppTheme.textHint : AppTheme.primaryColor,
                      width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: child),
              )
            : Container(
                width: widget.width ?? double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: disabled
                      ? const LinearGradient(colors: [
                          AppTheme.navyElevated,
                          AppTheme.navyElevated
                        ])
                      : gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: disabled
                      ? []
                      : AppTheme.glowShadow(glowColor, blur: 18, spread: -2),
                ),
                child: Center(child: child),
              ),
      ),
    );
  }

  bool get isLoading => widget.isLoading;
}
