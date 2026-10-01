import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final bool isOutlined;
  final double? width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.isOutlined = false,
    this.width,
    this.height = 48.0,
    this.borderRadius = 12.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    final effectiveOnPressed = isLoading ? null : onPressed;

    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? effectiveColor : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: textStyle ??
                      const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          );

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: effectiveColor,
            side: BorderSide(color: effectiveColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: effectiveColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          );

    final Widget buttonWidget = isOutlined
        ? OutlinedButton(
            onPressed: effectiveOnPressed,
            style: buttonStyle,
            child: content,
          )
        : ElevatedButton(
            onPressed: effectiveOnPressed,
            style: buttonStyle,
            child: content,
          );

    if (width != null) {
      return SizedBox(
        width: width,
        height: height,
        child: buttonWidget,
      );
    }

    return SizedBox(
      height: height,
      child: buttonWidget,
    );
  }
}
