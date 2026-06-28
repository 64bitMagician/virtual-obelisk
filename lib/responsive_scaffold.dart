import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Uses the general [Scaffold] Widget, but this widget is configured to respond to any screen dimension changes.
class ResponsiveScaffold extends StatelessWidget {
  final Widget child;

  const ResponsiveScaffold({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user to check their role
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // If no user is logged in for some reason, just show the standard layout (user mode)
    if (uid == null) {
      return _buildLayout(context, false);
    }

    // StreamBuilder listens to the user's document for the "role" field
    return StreamBuilder<DocumentSnapshot>(
      // configure the stream to retreive the 'users' document snapshot of authenticated user
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        bool isAdmin = false;

        // if the document snapshot exists and has non-null data
        if (snapshot.hasData && snapshot.data!.exists) {
          // retreive the data
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          // if data is not null and the role of the user is 'admin' -> mark 'isAdmin' as true
          if (data != null && data['role'] == 'admin') {
            isAdmin = true;
          }
        }

        // Pass the isAdmin flag to our layout builder
        // we build the layout depending on wether user is admin or not
        return _buildLayout(context, isAdmin);
      },
    );
  }

  Widget _buildLayout(BuildContext context, bool isAdmin) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _calculateSelectedIndex(context, isAdmin), // highlight the selected destination
              destinations: _buildPhoneDestinations(isAdmin), // create the Destination Widget that will appear on the NavigationBar
              onDestinationSelected: (index) => _onItemTapped(index, context, isAdmin), // get the index of the destination you selected
              // then do something with it (in our case: we change route => then also change highlighting of selected destination)
            ),
          );
        } else {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  labelType: NavigationRailLabelType.all,
                  selectedIndex: _calculateSelectedIndex(context, isAdmin), // highlight the selected destination
                  destinations: _buildTabletDestinations(isAdmin),
                  onDestinationSelected: (index) => _onItemTapped(index, context, isAdmin), // get the index of the destination you selected
                  // then do something with it (in our case: we change route => then also change highlighting of selected destination)
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }
      },
    );
  }


  List<NavigationDestination> _buildPhoneDestinations(bool isAdmin) {
    List<NavigationDestination> destinations = [
      const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      const NavigationDestination(icon: Icon(Icons.category), label: 'Categories'),
      const NavigationDestination(icon: Icon(Icons.link), label: 'Chains'),
      const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
      const NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
    ];

    // admin button only visible if admin role authenticated
    if (isAdmin) {
      destinations.add(const NavigationDestination(icon: Icon(Icons.security, color: Colors.red), label: 'Admin'));
    }
    return destinations;
  }

  List<NavigationRailDestination> _buildTabletDestinations(bool isAdmin) {
    List<NavigationRailDestination> destinations = [
      const NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
      const NavigationRailDestination(icon: Icon(Icons.category), label: Text('Categories')),
      const NavigationRailDestination(icon: Icon(Icons.link), label: Text('Chains')),
      const NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
      const NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
    ];

    // admin button only visible if admin role authenticated
    if (isAdmin) {
      destinations.add(const NavigationRailDestination(icon: Icon(Icons.security, color: Colors.red), label: Text('Admin')));
    }
    return destinations;
  }


  // This returns the index (int) of the selected destination on the NavicationDestination Widget
  // By passing this back to our NavicationDestination Widget, it knows which destination to highlight
  // such that the user understands the page he is currently at
  int _calculateSelectedIndex(BuildContext context, bool isAdmin) {
    // get the uri/path of the current state of GoRounte as a string
    final String location = GoRouterState.of(context).uri.toString();
    // depending on what the uri looks like, we return the index
    if (location.startsWith('/categories')) return 1;
    if (location.startsWith('/chains')) return 2;
    if (location.startsWith('/personal_profile')) return 3;
    if (location.startsWith('/settings')) return 4;


    if (location.startsWith('/admin')) return isAdmin ? 5 : 0;

    return 0;
  }

  // go to the corresponding route based on the index of the selected destination on the NavigationBar/Rail
  void _onItemTapped(int index, BuildContext context, bool isAdmin) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/categories');
        break;
      case 2:
        context.go('/chains');
        break;
      case 3:
        context.go('/personal_profile');
        break;
      case 4:
        context.go('/settings');
        break;
      case 5:
        if (isAdmin) context.go('/admin');
        break;
    }
  }
}