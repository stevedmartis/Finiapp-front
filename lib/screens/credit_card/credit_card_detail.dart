import 'package:finiapp/screens/credit_card/account_cards_widget.dart';
import 'package:finiapp/screens/dashboard/components/header_custom.dart';
import 'package:finiapp/screens/dashboard/dashboard_home.dart';
import 'package:finiapp/screens/providers/theme_provider.dart';
import 'package:finiapp/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finiapp/constants.dart';
import 'package:finiapp/responsive.dart';
import 'package:finiapp/screens/dashboard/components/transactions_list.page.dart';
import 'package:finiapp/services/auth_service.dart';

class CreditCardDetail extends StatefulWidget {
  final AccountWithSummary accountSummary;

  const CreditCardDetail({super.key, required this.accountSummary});

  @override
  CreditCardDetailState createState() => CreditCardDetailState();
}

class CreditCardDetailState extends State<CreditCardDetail> {
  @override
  Widget build(BuildContext context) {
    var authService = Provider.of<AuthService>(context, listen: false);
    var tagActual = authService.cardsHero;
    final heroTag = '$tagActual-${widget.accountSummary.account.name}';
    final currentTheme = Provider.of<ThemeProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final double totalIncome = transactionProvider.transactions
        .where((t) => t.type == "Ingreso")
        .fold(0.0, (sum, t) => sum + t.amount);

    final double totalExpense = transactionProvider.transactions
        .where((t) => t.type == "Gasto")
        .fold(0.0, (sum, t) => sum + t.amount);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: logoAppBarCOLOR,
        title: Text('Cuenta: ${widget.accountSummary.account.name}'),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Hero(
                tag: heroTag,
                child: AccountCard(accountSumarry: widget.accountSummary),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildCurrentBalance(
                    currentTheme,
                    widget.accountSummary.summary.balance,
                    totalIncome,
                    totalExpense,
                  ),
                  const SizedBox(height: defaultPadding),
                  /*  InfoCardsAmounts(
                    fileInfo: widget.card.fileInfo,
                  ), */
                  if (Responsive.isMobile(context))
                    TransactionHistorialPage(
                        accountId: widget.accountSummary.account.id),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBalance(ThemeProvider themeProvider, double available,
      double totalIncome, double totalExpense) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 0.0, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Saldo Disponible
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formatCurrency(available),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ✅ Ingresos y Gastos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAmount("+", totalIncome, Colors.greenAccent),
                    _buildAmount("-", totalExpense, Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ✅ Crear un método para evitar código repetido
  Widget _buildAmount(String prefix, double amount, Color color) {
    return Row(
      children: [
        Icon(
          prefix == "+" ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          "$prefix${formatCurrency(amount)}",
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
