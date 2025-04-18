import 'package:finiapp/screens/dashboard/components/header_custom.dart';
import 'package:finiapp/screens/providers/theme_provider.dart';
import 'package:finiapp/services/accounts_services.dart';
import 'package:finiapp/services/finance_summary_service.dart';
import 'package:finiapp/shared_preference/global_preference.dart';
import 'package:flutter/material.dart';
import 'package:finiapp/constants.dart';
import 'package:finiapp/widgets/buttons/button_continue_loading_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import '../../widgets/reouter_pages.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  AddAccountScreenState createState() => AddAccountScreenState();
}

class AddAccountScreenState extends State<AddAccountScreen> {
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  String _selectedAccountType = "Cuenta Corriente";
  bool _hasCompletedOnboarding = false; // 🔥 Nuevo flag

  final List<String> _accountTypes = [
    "Cuenta Corriente",
    "Cuenta de Ahorro",
    "Cuenta Vista",
    "Tarjeta de Crédito",
    "Efectivo"
  ];

  double _needs = 0.0;
  double _wants = 0.0;
  double _savings = 0.0;
  bool _isEditing = false; // Evita bucles de actualización

  @override
  void initState() {
    super.initState();
    _loadOnboardingStatus(); // 🔥 Carga si ya completó el onboarding
  }

  /// ✅ Cargar `hasCompletedOnboarding` desde `SharedPreferences`
  Future<void> _loadOnboardingStatus() async {
    await Future.delayed(Duration.zero); // 🔥 Espera a que todo esté listo

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool status = prefs.getBool("hasCompletedOnboarding") ?? false;

    setState(() {
      _hasCompletedOnboarding = status;
    });
  }

  void _onBalanceChanged(TextEditingController controller, String value) {
    if (_isEditing) return; // Evita llamadas múltiples innecesarias
    _isEditing = true;

    // Eliminar cualquier formato previo para obtener solo números
    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    double balance = double.tryParse(cleanValue) ?? 0;

    // Aplicar formateo en el TextField sin afectar cálculos
    String formattedValue = formatCurrency(balance);
    controller.value = TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );

    // Asegurar que se actualice la distribución correctamente
    _calculateBudget(balance);

    _isEditing = false;
  }

  void _calculateBudget(double balance) {
    setState(() {
      _needs = balance * 0.50;
      _wants = balance * 0.30;
      _savings = balance * 0.20;
    });
  }

  void _addAccount() async {
    String name = _accountNameController.text.trim();
    String cleanBalance =
        _balanceController.text.replaceAll(RegExp(r'[^\d]'), '');
    double balance = double.tryParse(cleanBalance) ?? 0;

    if (name.isEmpty || balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor ingresa un nombre y saldo válido."),
        ),
      );
      return;
    }

    final String accountId = const Uuid().v4();

    Account newAccount = Account(
      id: accountId,
      name: name,
      type: _selectedAccountType,
      balance: balance,
      bankName: 'bank_chile',
    );

    final accountsProvider =
        Provider.of<AccountsProvider>(context, listen: false);
    accountsProvider.addAccount(newAccount);

    final financialProvider =
        Provider.of<FinancialDataService>(context, listen: false);

    financialProvider.addAccountToSummary(newAccount);
    financialProvider.calculateGlobalSummary();

    accountsProvider.setCurrentAccountId(newAccount.id);

    _accountNameController.clear();
    _balanceController.clear();

    // ✅ Guardar estado actualizado
    await _saveAccountsToPrefs();

    if (_hasCompletedOnboarding) {
      Navigator.pop(context);
    } else {
      setState(() {});
    }
  }

  Future<void> _saveAccountsToPrefs() async {
    final accountsProvider =
        Provider.of<AccountsProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(
      "accounts",
      jsonEncode(
        accountsProvider.accounts.map((e) => e.toJson()).toList(),
      ),
    );
    prefs.setDouble("totalBalance", _calculateTotalBalance());
    prefs.setDouble("totalNeeds", _calculateTotalNeeds());
    prefs.setDouble("totalWants", _calculateTotalWants());
    prefs.setDouble("totalSavings", _calculateTotalSavings());
  }

  void _finishSetup() async {
    await _saveAccountsToPrefs(); // ✅ Reutilizar función

    final prefs = await SharedPreferences.getInstance();
    bool hasCompletedOnboarding =
        prefs.getBool("hasCompletedOnboarding") ?? false;

    await setOnboardingCompleted();

    if (!hasCompletedOnboarding) {
      await prefs.setBool("hasCompletedOnboarding", true);
      Navigator.pushReplacement(
        context,
        bubleSuccessRouter(),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumeric = false, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      onChanged: (value) {
        if (isNumeric) {
          _onBalanceChanged(controller, value);
        }
        if (onChanged != null) {
          onChanged(value);
        }
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

// Función para construir el selector de tipo de cuenta
  Widget _buildDropdownField(String label, String value) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: darkCardBackground,
      style: const TextStyle(color: Colors.white),
      items: _accountTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedAccountType = newValue!;
        });
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  double _calculateTotalBalance() {
    final accountsProvider =
        Provider.of<AccountsProvider>(context, listen: false);
    return accountsProvider.accounts
        .fold(0.0, (sum, account) => sum + account.balance);
  }

  double _calculateTotalNeeds() {
    return _calculateTotalBalance() * 0.50;
  }

  double _calculateTotalWants() {
    return _calculateTotalBalance() * 0.30;
  }

  double _calculateTotalSavings() {
    return _calculateTotalBalance() * 0.20;
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Agrega tus cuentas 📊",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: currentTheme.darkTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              Navigator.pop(context), // 🔙 Regresa a la pantalla anterior
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkCardBackground, darkCardBackground],
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints
                      .maxHeight, // 🔥 Ocupar mínimo toda la pantalla
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Ingresa tus cuentas para empezar a administrar tu dinero automáticamente con la regla 50/30/20.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                          "Nombre de la Cuenta", _accountNameController),
                      const SizedBox(height: 15),
                      _buildDropdownField(
                          "Tipo de Cuenta", _selectedAccountType),
                      const SizedBox(height: 15),
                      _buildTextField("Saldo Inicial", _balanceController,
                          isNumeric: true, onChanged: (value) {
                        double balance = double.tryParse(
                                value.replaceAll(RegExp(r'[^\d]'), '')) ??
                            0;
                        _calculateBudget(
                            balance); // Llamar con un `double` corregido
                      }),
                      const SizedBox(height: 15),
                      _buildBudgetDistribution(),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                logoCOLOR1, // Usa el color principal de la app
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _addAccount,
                          child: const Text(
                            "Agregar Cuenta",
                            style: TextStyle(
                              color: Colors.white, // Asegura buen contraste
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_hasCompletedOnboarding)
                        Consumer<AccountsProvider>(
                          builder: (context, accountsProvider, child) {
                            return accountsProvider.accounts.isNotEmpty
                                ? _buildAccountsList()
                                : const SizedBox();
                          },
                        ),
                      const SizedBox(height: 20),
                      Consumer<AccountsProvider>(
                        builder: (context, accountsProvider, child) {
                          return (!_hasCompletedOnboarding &&
                                  accountsProvider.accounts.isNotEmpty)
                              ? SizedBox(
                                  width: double.infinity,
                                  child: IconOrSpinnerButton(
                                    loading: false,
                                    showIcon: true,
                                    onPressed: _finishSetup,
                                  ),
                                )
                              : const SizedBox();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountsList() {
    return Consumer<AccountsProvider>(
      builder: (context, accountsProvider, child) {
        if (accountsProvider.accounts.isEmpty) {
          return const Center(
            child: Text(
              "No tienes cuentas agregadas.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }
        return Column(
          children: accountsProvider.accounts.map((account) {
            return Card(
              color: Colors.white10,
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                title: Text(account.name,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                    "${account.type} - Saldo: ${formatCurrency(account.balance)}",
                    style: const TextStyle(color: Colors.white70)),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBudgetDistribution() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Distribución del saldo:",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildCategoryRow("Necesidades", formatCurrency(_needs), "50%",
              Colors.redAccent, Icons.shopping_cart),
          const SizedBox(height: 10),
          _buildCategoryRow("Deseos", formatCurrency(_wants), "30%",
              Colors.blueAccent, Icons.star),
          const SizedBox(height: 10),
          _buildCategoryRow("Ahorro", formatCurrency(_savings), "20%",
              Colors.greenAccent, Icons.savings),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String title, String amount, String percentage,
      Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(amount,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
