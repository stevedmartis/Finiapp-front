import 'package:finiapp/screens/dashboard/components/header_custom.dart';
import 'package:finiapp/screens/providers/theme_provider.dart';
import 'package:finiapp/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TransactionsDashList extends StatelessWidget {
  const TransactionsDashList({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: true);

    if (transactionProvider.transactions.isEmpty) {
      return const Center(
        child: Text(
          'Tus movimientos aparecerán aquí.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final Map<String, IconData> categoryIcons = {
      "Comida": Icons.fastfood,
      "Transporte": Icons.directions_car,
      "Salud": Icons.health_and_safety,
      "Ocio": Icons.movie,
      "Educación": Icons.school,
      "Gasolina": Icons.local_gas_station,
      "Uber / Taxi": Icons.directions_car_filled,
      "Streaming": Icons.tv,
      "Hogar": Icons.home,
      "Mascota": Icons.pets,
      "Ropa": Icons.shopping_bag,
      "Videojuegos": Icons.sports_esports,
      "Gimnasio": Icons.fitness_center,
      "Regalos": Icons.card_giftcard,
      "Viajes": Icons.flight_takeoff,
      "Inversión": Icons.savings,
      "Sueldo": Icons.attach_money,
      "Ventas": Icons.shopping_cart,
      "Donaciones": Icons.volunteer_activism,
      "Aportes": Icons.payments,
      "Bonos": Icons.stars,
      "Premios": Icons.casino,
      "Otros": Icons.account_balance_wallet,
    };

    final latestTransaction = transactionProvider.transactions.last;
    final icon =
        categoryIcons[latestTransaction.category] ?? Icons.help_outline;
    final isIncome = latestTransaction.type == "Ingreso";
    final currentTheme = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: () {
        print("Abriendo detalles de la transacción ${latestTransaction.id}...");
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: currentTheme.getGradientCard(),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: isIncome ? Colors.green[400] : Colors.red[400],
              radius: 24,
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latestTransaction.category,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: currentTheme.getTitleColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd-MM-yyyy').format(
                        DateFormat('dd-MM-yyyy').parse(latestTransaction.date)),
                    style: TextStyle(
                      fontSize: 14,
                      color: currentTheme.getSubtitleColor(),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "${isIncome ? '+' : '-'} ${formatCurrency(latestTransaction.amount)}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isIncome ? Colors.greenAccent[400] : Colors.redAccent[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
