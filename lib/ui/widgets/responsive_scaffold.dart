import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Uses the general [Scaffold] Widget, but this widget is configured to respond to any screen dimension changes.
/// You give it a [Widget] to configure what is displayed in the main area of the [Scaffold].
/// While the other components of the [Scaffold] are hardcoded and will always be and appear the same.
///
/// Through the use of [LayoutBuilder], to determine the manner in which to display the widgets based on the
/// screen size. Tablet like, or phone like, or a browser that can change to both whenever it wants...
/// For Vertical Phone Like View, we have a [NavigationBar], which is part of the ShellWrapper, meaning
/// it preserves it's state regardless of navigation.
/// The body: property of the [Scaffold] makes the inner ShellWrapper content responsive.
///
/// For Tablet Like View, we have a [Row], which contains a [NavigationRail], which is the same
/// as a [NavigationBar] but on the side of the screen. A [VerticalDivider] and the inner ShellWrapper content.
/// In this view, the inner ShellWrapper content is nested within an [Expanded] Widget, making it responsive to
/// screen size changes.
///
/// In both LayoutViews, the NavigationBars have a fixed size. It is the inner ShellWrapper content which is
/// responsive.
class ResponsiveScaffold extends StatelessWidget {
  // We store the Widget received from the constructor within this 'child' variable
  final Widget child;

  // Constructor requires a Widget object
  const ResponsiveScaffold({required this.child, super.key,});

  @override
  Widget build(BuildContext context) {
    // We use LayoutBuilder to display Widgets in different manner depending on the Physical Screen Size
    // Any mutation in the Screen Size (Such as, changing the web browser size, turning the phone horizontally)
    // can trigger the LayoutBuilder (depending on it's configuration) to display Widgets in different manner
    return LayoutBuilder(
      builder: (context, constraints) {
        // Here we set the constraints that will dictate what layout will be displayed
        // The maximum width that this widget is allowed to take, based on the current screen size and its parent layout.
        if (constraints.maxWidth < 600) {
          // Let's call this the phone screen size configuration
          return Scaffold(
            body: child, // the main body will be represented by the Widget passed through the ResponsiveScaffold() constructor
            bottomNavigationBar: NavigationBar( // Battom Navigation Bar
              // display the selected button on the NavigationBar based on what route/uri we are on
              selectedIndex: _calculateSelectedIndex(context),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.link), label: 'Chains'),
                NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
              ],
              // We need a callback for when a destination is selected
              onDestinationSelected: (index) => _onItemTapped(index, context),
            ),
          );
        } else // constraints.maxWidth >= 600 (ScreenSize)
        { // Let's call this the Tablet screen Size Configuration
          // It acts the same as the Phone Screen Size configurations
          // Only difference is that the NavigationBar is on the Side, and to the Right of it (Use of Row)
          // there is a delimitator, that separates the NavigationRail from the received child Widget:
          // the received Widget that is to be displayed within the ShellWrapper
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _calculateSelectedIndex(context),
                  onDestinationSelected: (index) => _onItemTapped(index, context),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
                    NavigationRailDestination(icon: Icon(Icons.link), label: Text('Chains')),
                    NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
                    NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
                  ],
                ),
                // A vertical line that devides the Navigation from the ShellWrapper Inside Content
                const VerticalDivider(thickness: 1, width: 1),
                // here is the dynamic part of the screen, that changes while shell wrapper state preserved.
                // it represents the screen corresponding to the currently processed route
                // We use expanded such that it fills the rest of the available area on the screen
                // This makes the expanded content reactive to any changes in screen dimensions
                Expanded(child: child),
              ],
            ),
          );
        }
      },
    );
  }

  //  This method returns the index (an integer | starting from 0) of the item on the NavigationBar
  // that represents the currently processed route in our app.
  int _calculateSelectedIndex(BuildContext context) {
    // we store the full uri of the currently processed route (The GoRouterState holds this information)
    // in simple terms, we get the uri we are currently on
    final String location = GoRouterState.of(context).uri.toString();
    // And now we return the index based on what uri we are in
    if (location.startsWith('/chains')) return 1; // return 1 because chains button is the 2nd on NavigationBar
    if (location.startsWith('/profile')) return 2; // return 2 because profile button is 3rd on NavigationBar
    if (location.startsWith('/settings')) return 3; // return 3 because settings button is 4th on NavigationBar
    return 0; // return 0 because the home button is 1st on NavigationBar
  }

  // This method gets called whenever you press one of the buttons on the NavigationBar
  // Based on what button you have pressed on the NavigationBar, you will receive the index associated
  // with that button, and you can access it as the 'index' parameter in this method.
  // And based on the index/button, we navigate to the corresponding uri/route (screen), using the 'go' method
  // of the go_route package.
  // calling context.go triggers the rebuilding of the widgets affected by the new processed route
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/chains');
        break;
      case 2:
        context.go('/profile');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}