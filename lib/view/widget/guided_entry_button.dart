import 'package:flutter/material.dart';

class GuidedEntryButton extends StatefulWidget {
  const GuidedEntryButton({
    required this.width,
    required this.height,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final double width;
  final double height;
  final String label;
  final VoidCallback onPressed;

  @override
  State<GuidedEntryButton> createState() => _GuidedEntryButtonState();
}

class _GuidedEntryButtonState extends State<GuidedEntryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(90));
    final barWidth = widget.width * 0.34;
    final travel = widget.width + barWidth;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FilledButton.tonal(
              onPressed: widget.onPressed,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const RoundedRectangleBorder(
                  borderRadius: borderRadius,
                ),
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final left = _controller.value * travel - barWidth;
                  return Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: -10,
                        bottom: -10,
                        width: barWidth,
                        child: Transform.rotate(
                          angle: -0.20,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.42),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
