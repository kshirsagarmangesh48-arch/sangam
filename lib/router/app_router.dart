import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:sangam/features/auth/controllers/auth_controller.dart';
import 'package:sangam/features/auth/presentation/login_page.dart';
import 'package:sangam/features/home/presentation/home_page.dart';
import 'package:sangam/features/expense/presentation/add_transaction_page.dart';
import 'package:sangam/core/utils/go_router_refresh_stream.dart';
import 'package:sangam/core/constants/global_keys.dart';

class AppRouter {
  static final AuthController authController = Get.find<AuthController>();

  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      authController.firebaseUser.stream,
    ),
    redirect: (context, state) {
      final isLoggedIn = authController.firebaseUser.value != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/add-expense', // Keeping path for now to avoid breaking links
        builder: (context, state) => const AddTransactionPage(),
      ),
    ],
  );
}
