import 'package:finiapp/firebase_options.dart';
import 'package:finiapp/helper/lifecycle_event.dart';
import 'package:finiapp/screens/credit_card/credit_cards_page.dart';
import 'package:finiapp/screens/login/onboarding_page.dart';
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
import 'package:finiapp/screens/login/sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print("🚀 Iniciando la aplicación...");
  WidgetsFlutterBinding.ensureInitialized();

  print("✅ Flutter inicializado");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase inicializado correctamente");
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print("⚠️ Firebase ya estaba inicializado: ${e.message}");
    } else {
      rethrow;
    }
  }

  print("✅ Firebase inicializado");

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasCompletedOnboarding =
      prefs.getBool("hasCompletedOnboarding") ?? false;
  print(
      "✅ Preferencias cargadas - Onboarding completado: $hasCompletedOnboarding");

  await initializeDateFormatting('es_ES');
  print("✅ Formato de fecha inicializado");

  AuthService authService = AuthService();
  print("✅ AuthService inicializado");

  AccountsProvider accountsProvider = AccountsProvider();
  print("✅ AccountsProvider inicializado");

  TransactionProvider transactionProvider = TransactionProvider();
  print("✅ TransactionProvider inicializado");

  FinancialDataService financialProvider = FinancialDataService();
  print("✅ FinancialDataService inicializado");

  print("🧹 Limpiando todos los datos de la aplicación...");

  await authService.loadUserData();
  print("🔄 Cargando datos financieros guardados...");
  await financialProvider.loadData();
  print("🔄 Cargando cuentas...");
  await accountsProvider.loadAccounts();

/*   await authService.signOut();
  await accountsProvider.clearAccounts();
  await transactionProvider.clearTransactions();
  await financialProvider
      .clearFinanceData(); // Asegúrate de haber implementado este método
  print("✅ Todos los datos han sido eliminados");

  await prefs.setBool("hasCompletedOnboarding", false);
 */
  // Load financial data first

  print("🔄 Cargando transacciones...");
  await transactionProvider.loadTransactions();

  if (hasCompletedOnboarding) {
    print("📊 Verificando datos financieros...");
    // Only sync if we don't have existing financial data
    if (financialProvider.financialSummary.isEmpty) {
      print("⚠️ No hay datos financieros, inicializando...");

      // Initialize if needed
      financialProvider.initializeData();

      // Add each account to the summary if not already there
      if (accountsProvider.accounts.isNotEmpty) {
        print(
            "📊 Agregando ${accountsProvider.accounts.length} cuentas al resumen financiero...");
        for (var account in accountsProvider.accounts) {
          // Check if this account is already in the summary
          bool accountExists = financialProvider.financialSummary
              .any((summary) => summary.accountId.toString() == account.id);

          if (!accountExists) {
            print(
                "📊 Agregando cuenta ${account.id} (${account.name}) con saldo ${account.balance}");
            financialProvider.addAccountToSummary(account);
          } else {
            print("📊 La cuenta ${account.id} ya existe en el resumen");
          }
        }

        // Then sync transactions
        if (transactionProvider.transactions.isNotEmpty) {
          print(
              "📊 Sincronizando ${transactionProvider.transactions.length} transacciones...");
          financialProvider.syncTransactionsWithSummary(
            transactionProvider.transactions,
          );
        } else {
          print("📊 No hay transacciones para sincronizar");
        }

        // Calculate the summary
        print("📊 Calculando resumen global...");
        financialProvider.calculateGlobalSummary();
      } else {
        print(
            "⚠️ No hay cuentas disponibles para agregar al resumen financiero");
      }
    } else {
      print(
          "✅ Datos financieros ya cargados, omitiendo sincronización inicial");
    }
  } else {
    print("ℹ️ Onboarding no completado, omitiendo carga de datos");
  }

  CustomHttpClient httpClient = CustomHttpClient(authService);
  print("🚀 Lanzando aplicación...");

  print("📦 Cuentas guardadas:");
  print((await SharedPreferences.getInstance()).getString("accounts"));
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
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
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
              '/signIn': (context) => const SignIn(),
              '/cards': (context) => const CreditCardDemo(),
              '/onB': (context) => const OnboardingScreen(),
            },
            home: Consumer<AuthService>(
              builder: (context, auth, _) {
                if (auth.currentUser == null) {
                  return const SignIn();
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
