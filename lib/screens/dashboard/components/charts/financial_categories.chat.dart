import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finiapp/services/transaction_service.dart';
import 'package:finiapp/services/accounts_services.dart';
import 'package:finiapp/services/finance_summary_service.dart';
import 'package:finiapp/screens/providers/theme_provider.dart';

class BudgetedExpensesChart extends StatefulWidget {
  final List<TransactionDto> transactions;

  const BudgetedExpensesChart({
    super.key,
    required this.transactions,
  });

  @override
  State<BudgetedExpensesChart> createState() => _BudgetedExpensesChartState();
}

class _BudgetedExpensesChartState extends State<BudgetedExpensesChart> {
  // Categorías mantenidas del código original
  static const List<String> _needsCategories = [
    'Comida',
    'Transporte',
    'Salud',
    'Educación',
    'Gasolina',
    'Uber / Taxi',
    'Hogar',
    'Mascota'
  ];

  static const List<String> _wantsCategories = [
    'Ocio',
    'Streaming',
    'Ropa',
    'Videojuegos',
    'Gimnasio',
    'Regalos',
    'Viajes'
  ];

  static const List<String> _savingsCategories = ['Ahorro'];

  // Método de categorización global
  String _getGlobalCategory(String category) {
    if (_needsCategories.contains(category)) return 'Necesidades';
    if (_wantsCategories.contains(category)) return 'Deseos';
    if (_savingsCategories.contains(category)) return 'Ahorros';
    return 'Otro';
  }

  // Método de construcción de resumen de transacciones
  Map<String, Map<String, dynamic>> _buildSummaryFromTransactions(
      List<TransactionDto> transactions, double totalDisponible) {
    // Inicializar los montos gastados
    double totalNeeds = 0;
    double totalWants = 0;
    double totalSavings = 0;

    // Calcular gastos totales por categoría
    for (var transaction in transactions) {
      switch (_getGlobalCategory(transaction.category)) {
        case 'Necesidades':
          if (transaction.type == 'Gasto') totalNeeds += transaction.amount;
          break;
        case 'Deseos':
          if (transaction.type == 'Gasto') totalWants += transaction.amount;
          break;
        case 'Ahorros':
          if (transaction.type == 'Ingreso') totalSavings += transaction.amount;
          break;
      }
    }

    // Calcular los presupuestos basados en el método 50/30/20
    double needsBudget = totalDisponible * 0.50;
    double wantsBudget = totalDisponible * 0.30;
    double savingsBudget = totalDisponible * 0.20;

    // Calcular el dinero disponible en cada categoría
    double needsAvailable = needsBudget - totalNeeds;
    double wantsAvailable = wantsBudget - totalWants;
    double savingsAvailable = savingsBudget - totalSavings;

    // Calcular los porcentajes de uso
    double needsPercentage =
        needsBudget > 0 ? (totalNeeds / needsBudget) * 100 : 0;
    double wantsPercentage =
        wantsBudget > 0 ? (totalWants / wantsBudget) * 100 : 0;
    double savingsPercentage =
        savingsBudget > 0 ? (totalSavings / savingsBudget) * 100 : 0;

    // Determinar si alguna categoría excedió su presupuesto
    bool needsExceeded = needsPercentage > 100;
    bool wantsExceeded = wantsPercentage > 100;
    bool savingsExceeded = savingsPercentage > 100;

    return {
      'Necesidades': {
        'spent': totalNeeds,
        'budget': needsBudget,
        'available': needsAvailable,
        'percentage': needsPercentage,
        'isExceeded': needsExceeded,
      },
      'Deseos': {
        'spent': totalWants,
        'budget': wantsBudget,
        'available': wantsAvailable,
        'percentage': wantsPercentage,
        'isExceeded': wantsExceeded,
      },
      'Ahorros': {
        'spent': totalSavings,
        'budget': savingsBudget,
        'available': savingsAvailable,
        'percentage': savingsPercentage,
        'isExceeded': savingsExceeded,
      },
    };
  }

  // Obtener el color para la barra de progreso basado en el porcentaje
  Color _getProgressColor(
      double percentage, bool isExceeded, ThemeProvider theme) {
    if (isExceeded) return Colors.redAccent;
    if (percentage > 90) return Colors.orangeAccent;
    if (percentage > 75) return Colors.yellowAccent;
    return Colors.greenAccent;
  }

  // Widget de elemento de categoría con diseño mejorado
  Widget _buildCategoryItem(String category, Map<String, dynamic> data) {
    final percentage = data['percentage'];
    final isExceeded = data['isExceeded'];
    final available = data['available'];
    final budget = data['budget'];
    final spent = data['spent'];

    final currentTheme = Provider.of<ThemeProvider>(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: currentTheme.getGradientCard(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isExceeded
                ? Colors.red.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Ícono de categoría
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getColorForCategory(category).withOpacity(0.2),
            ),
            child: Icon(
              _getIconForCategory(category),
              color: _getColorForCategory(category),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Detalles de la categoría
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primera fila: Porcentaje y monto gastado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: isExceeded
                                ? Colors.redAccent
                                : currentTheme.getTitleColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' = ${formatCurrency(spent)}',
                          style: TextStyle(
                            color: isExceeded
                                ? Colors.redAccent.withOpacity(0.7)
                                : currentTheme.getSubtitleColor(),
                          ),
                        )
                      ]),
                    ),

                    // Mostrar relación gasto/presupuesto como en imagen 3
                    Text(
                      '${formatCurrency(spent)}/${formatCurrency(budget)}',
                      style: TextStyle(
                        color: currentTheme.getSubtitleColor().withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Barra de progreso con colores dinámicos
                LinearProgressIndicator(
                  value: percentage > 100 ? 1 : percentage / 100,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(percentage, isExceeded, currentTheme)),
                  minHeight: 6,
                ),

                const SizedBox(height: 8),

                // Información de disponibilidad o exceso
                Row(
                  children: [
                    Icon(
                      isExceeded ? Icons.warning_amber : Icons.check_circle,
                      color: isExceeded ? Colors.redAccent : Colors.greenAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isExceeded
                          ? 'Excedido por: ${formatCurrency(spent - budget)}'
                          : 'Disponible: ${formatCurrency(available)}',
                      style: TextStyle(
                        color:
                            isExceeded ? Colors.redAccent : Colors.greenAccent,
                        fontSize: 12,
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return const Center(
        child: Text(
          'Sin datos para mostrar',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final currentTheme = Provider.of<ThemeProvider>(context);
    final totalIncome =
        Provider.of<FinancialDataService>(context, listen: false)
            .getTotalDisponible(
                Provider.of<AccountsProvider>(context, listen: false));

    // Construir resumen con información detallada
    final summary =
        _buildSummaryFromTransactions(widget.transactions, totalIncome);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado con título y botón de información
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Distribución de gastos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: currentTheme.getSubtitleColor(),
              ),
            ),
            // Botón de información
            IconButton(
              icon: Icon(
                Icons.info_outline,
                color: currentTheme.getSubtitleColor(),
                size: 20,
              ),
              onPressed: () {
                _showInfoDialog(context);
              },
            ),
          ],
        ),

        // Elementos de categoría
        ...summary.entries.map((entry) {
          return _buildCategoryItem(
            entry.key,
            entry.value,
          );
        }),
      ],
    );
  }

  // Diálogo de información sobre el método 50/30/20
  void _showInfoDialog(BuildContext context) {
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Método 50/30/20',
          style: TextStyle(
            color: currentTheme.getTitleColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta distribución te ayuda a organizar tus finanzas de la siguiente manera:',
              style: TextStyle(color: currentTheme.getSubtitleColor()),
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'Necesidades (50%)',
              'Gastos esenciales como comida, vivienda, servicios básicos, etc.',
              Colors.redAccent,
              currentTheme,
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Deseos (30%)',
              'Gastos no esenciales como entretenimiento, ropa, salidas, etc.',
              Colors.blueAccent,
              currentTheme,
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Ahorros (20%)',
              'Fondos para emergencias, inversiones, metas financieras, etc.',
              Colors.greenAccent,
              currentTheme,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Entendido',
              style: TextStyle(color: currentTheme.getSubtitleColor()),
            ),
          ),
        ],
        backgroundColor: currentTheme.getBackgroundColor(),
      ),
    );
  }

  // Widget para cada ítem de información en el diálogo
  Widget _buildInfoItem(
      String title, String description, Color color, ThemeProvider theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.getTitleColor(),
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.getSubtitleColor(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Métodos existentes de iconos y colores
  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Necesidades':
        return Icons.shopping_cart;
      case 'Deseos':
        return Icons.star;
      case 'Ahorros':
        return Icons.savings;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Necesidades':
        return Colors.redAccent;
      case 'Deseos':
        return Colors.blueAccent;
      case 'Ahorros':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  // Función auxiliar para formatear moneda
  String formatCurrency(double amount) {
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }
}
