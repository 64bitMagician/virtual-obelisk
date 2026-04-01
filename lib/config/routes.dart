import 'package:art_platform/core/constants.dart';
import 'package:art_platform/ui/screens/categories_screen.dart';
import 'package:art_platform/ui/widgets/media_readers/media_reader.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/chains_screen.dart';
import '../ui/screens/chain_detail_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/settings_screen.dart';
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
      //    within its child property, it means that from this level down in the widget tree, all widgets will
      //    be part as the inside content of the Shell Wrapper, that can change, while the Shell Wrapper stays
      //    the same.
      // AuthGate requires a "child" which is of type Widget, to know wether to return (and display)
      // the given "child" Widget ResponsiveScaffold() (but only in the case where the User
      // is in the Authenticated State). Otherwiser, it will either return/display the LoginScreen (in case
      // User is not authenticated (User is null). ), or a loading screen (when it waits for the authentication
      // status of the User)
      // Because AuthGate represents part of the ShellWrapper, it means that the AuthGate will always determine
      // what User can see...
      // If User is indeed logged in, then AuthGate will return/display the ResponsiveScaffold, which is also part
      // of the ShellWrapper. And only now, the child Widget given within ResponsiveScaffold will represent the
      // content that the Shell Wrapper encapsulates. The content that can shift while the ShellWrapper (AuthGate
      // and ResponsiveScaffold) stay the same. This is because this is the moment we use the child parameter
      // received through the lamba Widget Function.
      builder: (context, state, child) => AuthGate(child: ResponsiveScaffold(child: child)),
      // But who is the child Widget passed to the lambda function?
      // Well, it is the returned Widget of the route (from the list of routes: bellow) that is
      // currently being processed.
      // EX: If current route processed is '/', then HomeScreen() is be the child Widget inside the ShellWrapper
      //     If current route processed is '/chains', then ChainsScreen() is be the child
      //  Widget inside the ShellWrapper.
      //     For '/chains/123', it will be ChainDetailScreen(chainId: 123)
      // So that's how go_routing decides what to display within the ShellWrapper based on the current route
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
          routes: [
            GoRoute(
              path: 'media_reader/:post_index',
              builder: (context, state) {
                // Extract the variable from the URL path
                final int postIndex = int.parse(state.pathParameters['post_index']!);
                // Pass it to the screen
                return MediaReader(mediaReaderConfiguration: MediaReaderConfiguration.PROFILE_FEED, profilePostIndex: postIndex, exitButton: true);
              }
            )
          ]
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => CategoriesScreen(),
          routes: [
            GoRoute(
              // NO leading slash here!
              // By nesting it, go_router automatically prepends '/categories/' to it.
              // So the full absolute URL becomes: /categories/feed/:categoryName
              path: 'feed/:category_name',
              builder: (context, state) {
                // Extract the variable from the URL path
                final String categoryName = state.pathParameters['category_name']!;
                // Pass it to the screen
                return MediaReader(mediaReaderConfiguration: MediaReaderConfiguration.CATEGORY_FEED, category: categoryName, exitButton: true);
              },
            )
          ],
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);