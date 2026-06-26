import 'package:art_platform/ui/widgets/media_reader_and_widgets/exit_reader_button.dart';
import 'package:flutter/material.dart';

class MediaNavigator extends StatelessWidget {
  final bool isVisible;
  final bool? exitButton;
  final PageController pageController;
  final VoidCallback callStartHideTimer; // we pass it the _startHideTimer()

  const MediaNavigator({
    super.key,
    required this.isVisible,
    required this.pageController,
    required this.callStartHideTimer,
    this.exitButton,
});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Exit button, or nothing at all, based on reader configuration
        if(exitButton==true)
          ExitReaderButton(isVisible: isVisible),

        // Retracting Animation (For the arrow left)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 600), // retraction animation duration
          left: isVisible ? 20 : -100, // on the left edge, from 20px right goes out of view -100px
          top: 0,
          bottom: 0,
          child: AnimatedOpacity( // Fading Animation
            duration: const Duration(milliseconds: 600), // fading animation duration
            opacity: isVisible ? 0.6 : 0.0, // the fading goes to 0 when ui is no longer visible
            child: Center(
              child: _buildNavButton( // method that creates the arrow button and it's function
                  Icons.chevron_left, // left arrow icon
                      ()  {
                    callStartHideTimer;
                    pageController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut,);
                  }
              ),
            ),
          ),
        ),

        // Retracting Animation (For the arrow right)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 600), // retraction animation duration
          right: isVisible ? 20 : -100, // on the right edge, from 20px left goes out of view -100px
          top: 0,
          bottom: 0,
          child: AnimatedOpacity( // Fading animation
            duration: const Duration(milliseconds: 600), // fading animation duration
            opacity: isVisible ? 0.6 : 0.0, // the fading goes to 0 when ui is no longer visible
            child: Center(
              child: _buildNavButton( // method that creates the arrow button and it's function
                  Icons.chevron_right, // right arrow icon
                      () {
                    callStartHideTimer();
                    pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut,);
                  }
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Returns the arrow button, the logic of the button resides within the received argument (the onTap callback function)
  // Here we just create the design of the arrow and throw in the logic received (onTap) within the onPressed: property of the IconButton
  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 48),
        onPressed: onTap,
      ),
    );
  }

}


