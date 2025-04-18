import 'package:finiapp/constants.dart';
import 'package:finiapp/screens/credit_card/credit_card_slider.dart';
import 'package:finiapp/screens/dashboard/dashboard_home.dart';
import 'package:finiapp/services/accounts_services.dart';

import 'package:finiapp/services/auth_service.dart';
import 'package:finiapp/services/finance_summary_service.dart';
import 'package:finiapp/services/transaction_service.dart';
import 'package:finiapp/widgets/buttons/button_continue_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreditCardDemo extends StatefulWidget {
  const CreditCardDemo({super.key});
  @override
  CreditCardDemoState createState() => CreditCardDemoState();
}

class CreditCardDemoState extends State<CreditCardDemo> {
  int _currentCardIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    int initialIndex = Provider.of<AuthService>(context, listen: false).index;

    super.initState();
    _pageController =
        PageController(initialPage: initialIndex, viewportFraction: 0.3);

    _currentCardIndex = initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCardClicked(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentCardIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var isScreenWide = MediaQuery.of(context).size.width > 600;

    return Consumer3<AccountsProvider, FinancialDataService,
        TransactionProvider>(
      builder:
          (context, accountsProvider, financialData, transactionProvider, _) {
        // ✅ Combinar cuentas + resumen financiero + saldo dinámico desde TransactionProvider
        final combinedAccounts = financialData.getCombinedAccounts(
          accountsProvider.accounts,
          Provider.of<TransactionProvider>(context,
              listen: false), // ✅ Pasar directamente
        );

        if (combinedAccounts.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mis Cuentas')),
            body: const Center(child: Text('No hay cuentas disponibles')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: logoAppBarCOLOR,
            title: const Text('Mis Cuentas'),
          ),
          floatingActionButton: IconOrSpinnerButton(
            showIcon: true,
            loading: false,
            isMenu: true,
            onPressed: () {
              Navigator.pushNamed(context, '/addAccount'); // O tu ruta real
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          body: isScreenWide
              ? Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(0.0),
                        height: MediaQuery.of(context).size.height * 0.235,
                        child: CreditCardSlider(
                          combinedAccounts, // ✅ Ahora el saldo está actualizado
                          pageController: _pageController,
                          initialCard: _currentCardIndex,
                          onCardClicked: _onCardClicked,
                          isVertical: true,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: CreditCardDetailWidget(
                          key: ValueKey(_currentCardIndex),
                          card: combinedAccounts[_currentCardIndex],
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.all(0.0),
                  height: MediaQuery.of(context).size.height * 0.70,
                  child: CreditCardSlider(
                    combinedAccounts, // ✅ Ahora el saldo está actualizado
                    pageController: _pageController,
                    initialCard: _currentCardIndex,
                    onCardClicked: _onCardClicked,
                    isVertical: true,
                  ),
                ),
        );
      },
    );
  }
}

class CreditCardDetailWidget extends StatelessWidget {
  final AccountWithSummary card;

  const CreditCardDetailWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 4.0,
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... Otros detalles de la tarjeta
            ],
          ),
        ),
      ),
    );
  }
}
