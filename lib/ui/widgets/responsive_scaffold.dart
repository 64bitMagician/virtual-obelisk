import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'upload_dialog.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;

  const ResponsiveScaffold({
    required this.child,
    super.key,
  });

  // Helper to show the dialog
  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UploadDialog(), // Import this!
    );
  }

  @override
  Widget build(BuildContext context) {
    // We use LayoutBuilder to read the screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile Layout (Bottom Navigation)
          return Scaffold(
            body: child,
            floatingActionButton: FloatingActionButton(onPressed: () => _showUploadDialog(context), child: const Icon(Icons.add),),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _calculateSelectedIndex(context),
              onDestinationSelected: (index) => _onItemTapped(index, context),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.link), label: 'Chains'),
                NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          );
        } else {
          // Desktop/Web Layout (Side Navigation Rail)
          return Scaffold(
            floatingActionButton: FloatingActionButton.extended(onPressed: () => _showUploadDialog(context), label: const Text("Create"), icon: const Icon(Icons.add),),
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
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // "Expanded" makes the child take up the rest of the screen
                Expanded(child: child),
              ],
            ),
          );
        }
      },
    );
  }

  // Helper to determine the index based on the URL path
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/chains')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0; // Default to Home
  }

  // Helper to handle navigation clicks
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
    }
  }
}