import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/services/auth_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/currency_provider.dart';
import 'presentation/providers/transaction_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'core/themes/app_theme.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs      = await SharedPreferences.getInstance();
  final authService = AuthService(prefs);

  // Read the user's saved base currency so CurrencyProvider starts correctly.
  final baseCurrency = authService.baseCurrency; // defaults to 'USD'

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) {
            final provider = CurrencyProvider(baseCurrency: baseCurrency);
            // Kick off a rate fetch in the background; UI handles loading state.
            provider.loadRates();
            return provider;
          },
        ),
      ],
      child: const PocketLensApp(),
    ),
  );
}

class PocketLensApp extends StatelessWidget {
  const PocketLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider  = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final router        = createRouter(authProvider);

    return MaterialApp.router(
      title: 'PocketLens',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.lightTheme(),
      darkTheme:  AppTheme.darkTheme(),
      themeMode:  themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}