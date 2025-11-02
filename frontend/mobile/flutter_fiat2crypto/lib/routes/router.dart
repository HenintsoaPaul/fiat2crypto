import 'package:flutter/material.dart';
import 'package:flutter_fiat2crypto/features/auth/state/auth_state_notifier.dart';
import 'package:flutter_fiat2crypto/features/home/home_screen.dart';
import 'package:flutter_fiat2crypto/features/login/login_screen.dart';
import 'package:flutter_fiat2crypto/l10n/locale_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _routerNavigatorKey = GlobalKey<NavigatorState>(debugLabel: "router");

/// Defines when GoRouter should refresh
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
    ref.listen(localeProvider, (_, _) => notifyListeners());
  }
}

/// Router
final goRouterProvider = Provider<GoRouter>((ref) {
  final routerRefresh = RouterRefreshNotifier(ref);
  final routes = ref.read(goRoutesProvider);

  final goRouter = GoRouter(
    navigatorKey: _routerNavigatorKey,
    initialLocation: LoginScreen.path,
    refreshListenable: routerRefresh,
    routes: routes,
    redirect: (BuildContext context, GoRouterState state) {
      final loc = state.matchedLocation;

      final authenticated = ref.read(authProvider).isLoggedIn;

      final loggingIn = loc == LoginScreen.path;

      if (!authenticated && !loggingIn) return LoginScreen.path;
      if (authenticated && loggingIn) return HomeScreen.path;

      return null;
    },
  );

  return goRouter;
});

/// Routes
final goRoutesProvider = Provider(
  (_) => [
    GoRoute(
      path: HomeScreen.path,
      name: HomeScreen.name,
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: LoginScreen.path,
      name: LoginScreen.name,
      builder: (context, state) => LoginScreen(),
    ),
  ],
);
