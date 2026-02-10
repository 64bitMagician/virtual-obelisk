import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/chains_screen.dart';
import '../ui/screens/chain_detail_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/widgets/responsive_scaffold.dart';
import '../ui/auth_gate.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// To not be mixed up with [GoRoute]
/// [GoRouter] is the object that manages all routes in our app
/// [GoRoute] is one of multiple route object types
/// These routes make up the routing system that GoRouter Manages
final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // We use ShellRoute for Nested Navigation
    // This makes having a part of the UI persistent while the nested content changes possible.
    // Ex: A bottom bar (or whataver part of a UI you want) that is persistent and independent
    // Whatever navigation change of Screens you'd make, that one UI bottom bar instance would stay the same
    // ShellRoute does not preserve any previous states during navigations
    // Use StatefulShellRoute to preserve state of previous routes (Ex: scroll positions of previous screens)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      // the builder property is of type Widget Function(BuildContext, GoRouterState, Widget)?
      // BuildContext corresponds to the parent widget of the one returned in builder property,
      //    it determines the position of the widget in the widget tree
      // GoRouterState belongs to the go_router package. It is a type holding state data corresponding
      //    to the current route path being processed
      // Widget is the widget that will be added within the body of the Shell Wrapper
      //    let's call this Widget "child" for simplicity
      //    The Shell Wrapper will represent all the widgets returned in the builder property
      //    up til the insertion of the "child" widget in the widget tree.
      //    In our case, the Shell Wrapper will be the nested AuthGate(child: ResponsiveScaffold) widgets
      //    And since the ResponsiveScaffold(child: child) widget nests the given "child" from the lambda function
      //    within its child property, it means that from this level down in the widget tree, all widget will
      //    be part as the inside content of the Shell Wrapper, that can change, while the Shell Wrapper stays
      //    the same.
      builder: (context, state, child) => AuthGate(child: ResponsiveScaffold(child: child),),
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