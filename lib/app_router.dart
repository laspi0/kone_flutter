import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/products_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/sale_history_screen.dart';
import 'screens/cash_journal_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_management_screen.dart'; // New import

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: '/products',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ProductsScreen()),
      ),
      GoRoute(
        path: '/categories',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: CategoriesScreen()),
      ),
      GoRoute(
        path: '/sales',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SalesScreen()),
      ),
      GoRoute(
        path: '/customers',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: CustomersScreen()),
      ),
      GoRoute(
        path: '/sale-history',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SaleHistoryScreen()),
      ),
      GoRoute(
        path: '/cash-journal',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: CashJournalScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SettingsScreen()),
      ),
      GoRoute( // New route for user management
        path: '/users-management',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: UserManagementScreen()),
      ),
    ],
  );
}
