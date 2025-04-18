import 'package:finiapp/models/payment_dto.dart';
import 'package:finiapp/screens/dashboard/components/header_custom.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class UpcomingPaymentsWidget extends StatelessWidget {
  final List<PaymentDto> upcomingPayments;
  final Function(PaymentDto) onPaymentMarked;

  const UpcomingPaymentsWidget({
    super.key,
    required this.upcomingPayments,
    required this.onPaymentMarked,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = Provider.of<ThemeProvider>(context);
    if (upcomingPayments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: currentTheme.getGradientCard(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Próximos Pagos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: currentTheme.getTitleColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentTheme.getBackgroundColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: currentTheme.getSubtitleColor(),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No tienes pagos programados próximos. Añade pagos recurrentes para recibir recordatorios.',
                      style: TextStyle(
                        fontSize: 12,
                        color: currentTheme.getSubtitleColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.purple,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Próximos Pagos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Lista de pagos próximos
          ...upcomingPayments
              .map((payment) => _buildPaymentItem(payment, context))
              ,
        ],
      ),
    );
  }

  Widget _buildPaymentItem(PaymentDto payment, BuildContext context) {
    final bool isOverdue = payment.dueDate.isBefore(DateTime.now());
    final int daysLeft = payment.dueDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdue
              ? Colors.redAccent.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCategoryColor(payment.category).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(payment.category),
              color: _getCategoryColor(payment.category),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOverdue
                      ? 'Vencido hace ${daysLeft.abs()} días'
                      : daysLeft == 0
                          ? 'Vence hoy'
                          : 'Vence en $daysLeft días',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue
                        ? Colors.redAccent
                        : daysLeft <= 3
                            ? Colors.orangeAccent
                            : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(payment.amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.greenAccent,
              size: 24,
            ),
            onPressed: () => onPaymentMarked(payment),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Implementar según las categorías de tu aplicación
    switch (category.toLowerCase()) {
      case 'arriendo':
        return Colors.purpleAccent;
      case 'servicios':
        return Colors.blueAccent;
      case 'suscripciones':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    // Implementar según las categorías de tu aplicación
    switch (category.toLowerCase()) {
      case 'arriendo':
        return Icons.home;
      case 'servicios':
        return Icons.power;
      case 'suscripciones':
        return Icons.subscriptions;
      default:
        return Icons.receipt_long;
    }
  }
}
