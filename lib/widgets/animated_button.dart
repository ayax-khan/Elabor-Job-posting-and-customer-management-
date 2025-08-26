import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final bool disabled;

  const AnimatedButton({
    super.key,
    required this.text,
    this.icon,
    required this.color,
    required this.onPressed,
    this.width,
    this.height,
    this.disabled = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) {
        setState(() => _isTapped = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isTapped ? 0.95 : 1.0),
        width: widget.width ?? double.infinity,
        height: widget.height ?? size.height * 0.07,
        padding: EdgeInsets.symmetric(
          vertical: size.height * 0.015,
          horizontal: size.width * 0.04,
        ),
        decoration: BoxDecoration(
          color: widget.disabled ? Colors.grey : widget.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null)
              Icon(widget.icon, color: Colors.white, size: size.width * 0.05),
            if (widget.icon != null && widget.text.isNotEmpty)
              SizedBox(width: size.width * 0.02),
            if (widget.text.isNotEmpty)
              Flexible(
                child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: size.width * 0.045,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
