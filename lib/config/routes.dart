import 'package:art_platform/ui/screens/chain_detail_screen.dart';
import 'package:flutter/material.dart'; // Needed for GlobalKey
import 'package:go_router/go_router.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/chains_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/widgets/responsive_scaffold.dart'; // Import the new widget

// We need a key for the Navigator to keep state
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    // 1. Routes OUTSIDE the navigation shell (Login)
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // 2. Routes INSIDE the navigation shell
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        // This wraps the pages in our ResponsiveScaffold
        return ResponsiveScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/chains',
          builder: (context, state) => const ChainsScreen(),
          routes: [
            GoRoute(path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ChainDetailScreen(chainId: id);
            },
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);