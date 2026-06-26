import 'package:art_platform/ui/widgets/media_reader_and_widgets/media_reader.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A Go Back to previous page button for [MediaReader] objects that want to adopt this [ExitReaderButton],
/// because it is optional.
///
/// It has animation to dissapear. It gets triggered whenever [isVisible] becomes flase.
class ExitReaderButton extends StatelessWidget {
  final bool isVisible;
  final double top; // distance from top
  final double right; // distance from right
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final Duration animationDuration;

  const ExitReaderButton({
    required this.isVisible,
    this.top = 40,
    this.right = 16,
    this.backgroundColor = const Color(0x80000000), // semi-transparent black
    this.iconColor = Colors.white,
    this.size = 28,
    this.animationDuration = const Duration(milliseconds: 600), // retraction animation duration;
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: animationDuration,
      top: isVisible ? top : -100, // at top defined position, or out of view (-100 px)
      right: right, // at right defined position, or out of view (-100 px)
      child: AnimatedOpacity(
        duration: animationDuration,
        opacity: isVisible ? 0.6 : 0.0, // the fading goes to 0 when ui is no longer visible
        child: GestureDetector(
          onTap: () => context.pop(), // pop the screen on top of stack / go back to previous page
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle), child: Icon(Icons.close, color: iconColor, size: size)),
        ),
      ),
    );
  }
}
