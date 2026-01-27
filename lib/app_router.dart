import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/products_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/sales_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/sales',
        builder: (context, state) => const SalesScreen(),
      ),
    ],
  );
}