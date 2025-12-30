import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/chains_screen.dart';
import '../ui/screens/chain_detail_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/widgets/responsive_scaffold.dart';
import '../ui/auth_gate.dart'; // Ensure this file exists

// Keys to maintain state during navigation
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/', // Always start at root, AuthGate decides where to go
  routes: [
    // We do NOT need a separate '/login' route here anymore.
    // The AuthGate handles showing the LoginScreen automatically.

    // SHELL ROUTE (The Main App)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        // WRAPPER MAGIC:
        // 1. AuthGate checks if user is logged in.
        // 2. If NO -> It returns LoginScreen (and ignores the child).
        // 3. If YES -> It returns ResponsiveScaffold (Sidebar) containing the child.
        return AuthGate(
          child: ResponsiveScaffold(child: child),
        );
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
            GoRoute(
              path: ':id',
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