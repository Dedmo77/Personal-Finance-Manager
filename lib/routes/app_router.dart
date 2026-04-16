import 'package:go_router/go_router.dart';
//import 'package:provider/provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/profile/edit_profile_screen.dart';
import '../presentation/screens/transactions/add_edit_transaction_screen.dart';
import '../presentation/screens/transactions/transactions_screen.dart';
import '../presentation/screens/budget/budget_goals_screen.dart';
import '../presentation/screens/reports/reports_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/';

      if (!isLoggedIn && !isOnAuth) return '/login';
      if (isLoggedIn && isOnAuth) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/add-transaction', builder: (_, __) => const AddTransactionScreen()),
      GoRoute(path: '/transactions', builder: (_, __) => const TransactionsScreen()),
      GoRoute(path: '/budget', builder: (_, __) => const BudgetGoalsScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
    ],
  );
}