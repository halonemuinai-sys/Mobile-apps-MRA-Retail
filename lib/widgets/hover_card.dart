import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final double borderRadius;
  final Color backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 1.02,
    this.borderRadius = 16.0,
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.padding,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Only apply hover scale and styling on Web or Desktop
    final isWebOrDesktop = kIsWeb || 
        defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.macOS || 
        defaultTargetPlatform == TargetPlatform.linux;

    final activeScale = (_isHovered && isWebOrDesktop) ? widget.scale : 1.0;
    final primaryColor = Theme.of(context).primaryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: activeScale,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.borderColor ?? (_isHovered && isWebOrDesktop 
                    ? primaryColor.withValues(alpha: 0.4) 
                    : const Color(0xFFE2E8F0)),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isHovered && isWebOrDesktop ? 0.08 : 0.04,
                  ),
                  blurRadius: _isHovered && isWebOrDesktop ? 16 : 8,
                  offset: Offset(0, _isHovered && isWebOrDesktop ? 6 : 2),
                )
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
