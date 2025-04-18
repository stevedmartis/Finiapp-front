import 'package:finiapp/firebase_options.dart';
import 'package:finiapp/helper/lifecycle_event.dart';
import 'package:finiapp/screens/credit_card/credit_cards_page.dart';
import 'package:finiapp/screens/login/add_accouts_explain_page.dart';
import 'package:finiapp/screens/login/onboarding_page.dart';
import 'package:finiapp/screens/main/components/login_precharge.dart';
import 'package:finiapp/screens/providers/theme_provider.dart';
import 'package:finiapp/services/accounts_services.dart';
import 'package:finiapp/services/auth_service.dart';
import 'package:finiapp/services/finance_summary_service.dart';
import 'package:finiapp/services/token_interceptor.dart';
import 'package:finiapp/services/transaction_service.dart';
import 'package:finiapp/utilis/navigator_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:finiapp/controllers/menu_app_controller.dart';
import 'package:finiapp/screens/main/main_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
    } else {
      rethrow;
    }
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasCompletedOnboarding =
      prefs.getBool("hasCompletedOnboarding") ?? false;

  await initializeDateFormatting('es_ES');
  AuthService authService = AuthService();

  AccountsProvider accountsProvider = AccountsProvider();

  TransactionProvider transactionProvider = TransactionProvider();

  FinancialDataService financialProvider = FinancialDataService();

  await authService.loadUserData();

  await financialProvider.loadData();

  await accountsProvider.loadAccounts();

/*   await authService.signOut();
  await accountsProvider.clearAccounts();
  await transactionProvider.clearTransactions();
  await financialProvider
      .clearFinanceData(); // Asegúrate de haber implementado este método

  await prefs.setBool("hasCompletedOnboarding", false);
 */
  // Load financial data first

  await transactionProvider.loadTransactions();

  if (hasCompletedOnboarding) {
    // Only sync if we don't have existing financial data
    if (financialProvider.financialSummary.isEmpty) {
      // Initialize if needed
      financialProvider.initializeData();

      // Add each account to the summary if not already there
      if (accountsProvider.accounts.isNotEmpty) {
        for (var account in accountsProvider.accounts) {
          // Check if this account is already in the summary
          bool accountExists = financialProvider.financialSummary
              .any((summary) => summary.accountId.toString() == account.id);

          if (!accountExists) {
            financialProvider.addAccountToSummary(account);
          } else {}
        }

        // Then sync transactions
        if (transactionProvider.transactions.isNotEmpty) {
          financialProvider.syncTransactionsWithSummary(
            transactionProvider.transactions,
          );
        } else {}

        financialProvider.calculateGlobalSummary();
      } else {}
    } else {}
  } else {}

  CustomHttpClient httpClient = CustomHttpClient(authService);

  (await SharedPreferences.getInstance()).getString("accounts");
  runApp(MyApp(
      httpClient: httpClient,
      authService: authService,
      hasCompletedOnboarding: hasCompletedOnboarding,
      accountsProvider: accountsProvider,
      transactionProvider: transactionProvider,
      financialProvider: financialProvider));
}

Future<void> resetOnboarding() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove("hasCompletedOnboarding"); // 🔥 Elimina la clave guardada`
}

class MyApp extends StatefulWidget {
  final CustomHttpClient httpClient;
  final AuthService authService;
  final bool hasCompletedOnboarding;
  final AccountsProvider accountsProvider;
  final TransactionProvider transactionProvider; // ✅ Recibe el provider cargado
  final FinancialDataService financialProvider;

  const MyApp({
    super.key,
    required this.httpClient,
    required this.authService,
    required this.hasCompletedOnboarding,
    required this.accountsProvider,
    required this.transactionProvider,
    required this.financialProvider,

    // ✅ Lo pasamos aquí
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider themeProvider = ThemeProvider();
  @override
  void dispose() {
    // No olvides cerrar el cliente HTTP cuando la app se cierre
    widget.httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        onResumed: () => widget.authService.checkSession(),
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MenuAppController()),
        ChangeNotifierProvider.value(value: widget.authService),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: widget.accountsProvider),
        ChangeNotifierProvider.value(value: widget.transactionProvider),

        ChangeNotifierProvider.value(value: widget.financialProvider),

        Provider.value(
            value: widget.httpClient), // ✅ Se usa el que ya está cargado
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            locale: const Locale('es', 'ES'),
            debugShowCheckedModeBanner: false,
            title: 'finIA',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode, // Usa el tema oscuro
            routes: {
              '/mainScreen': (context) => const MainScreen(),
              '/signIn': (context) => const SignInWithPrecache(),
              '/cards': (context) => const CreditCardDemo(),
              '/onB': (context) => const OnboardingScreen(),
              '/addAccount': (context) => const AddAccountScreen(),
            },
            home: Consumer<AuthService>(
              builder: (context, auth, _) {
                if (auth.currentUser == null) {
                  return const SignInWithPrecache();
                }
                return widget.hasCompletedOnboarding
                    ? const MainScreen()
                    : const OnboardingScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
