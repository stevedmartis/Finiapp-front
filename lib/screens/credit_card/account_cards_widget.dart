import 'package:finiapp/screens/dashboard/components/header_custom.dart';
import 'package:finiapp/screens/dashboard/dashboard_home.dart';
import 'package:finiapp/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:finiapp/services/accounts_services.dart';
import 'package:provider/provider.dart';

class AccountCard extends StatelessWidget {
  final AccountWithSummary accountSumarry;

  const AccountCard({super.key, required this.accountSumarry});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: _getBackgroundDecoration(accountSumarry.account.type),
        child: Stack(
          children: [
            Positioned(
              top: 30,
              right: 10,
              child: _getBankLogo(accountSumarry.account.bankName),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(accountSumarry.account),
                const SizedBox(height: 12),
                Text(
                  accountSumarry.account.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Saldo: ${formatCurrency(accountSumarry.getCalculatedBalance(transactionProvider))}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getBackgroundDecoration(String type) {
    return BoxDecoration(
      gradient: _getGradient(type),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          spreadRadius: 2,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _getBankLogo(String bankName) {
    return Opacity(
      opacity: 0.25,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          "assets/images/banks/${bankName.toLowerCase()}.png",
          width: 50,
          height: 50,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// 📌 Obtiene el gradiente según el tipo de cuenta
  LinearGradient _getGradient(String type) {
    switch (type) {
      case "Cuenta Corriente":
        return const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case "Cuenta de Ahorro":
        return const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case "Efectivo":
        return const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case "Cuenta Vista":
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 59, 59, 59),
            Color.fromARGB(255, 8, 16, 30)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF607D8B), Color(0xFF455A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Widget _buildHeader(Account account) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _getAccountIcon(account.type),
        Text(
          account.type,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _getAccountIcon(String type) {
    switch (type) {
      case "Cuenta Corriente":
        return const Icon(Icons.account_balance, color: Colors.white);
      case "Cuenta de Ahorro":
        return const Icon(Icons.savings, color: Colors.white);
      case "Efectivo":
        return const Icon(Icons.money, color: Colors.white);
      default:
        return const Icon(Icons.account_balance_wallet, color: Colors.white);
    }
  }
}
