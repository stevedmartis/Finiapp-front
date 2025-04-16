import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finiapp/screens/dashboard/components/header_custom.dart';
import 'package:finiapp/screens/providers/theme_provider.dart';
import 'package:finiapp/services/transaction_service.dart';
import 'package:finiapp/services/accounts_services.dart';
import 'package:finiapp/services/finance_summary_service.dart';
import 'package:finiapp/utilis/format_currency.dart';

class BudgetPlanWidget extends StatefulWidget {
  final List<TransactionDto> transactions;

  const BudgetPlanWidget({
    super.key,
    required this.transactions,
  });

  @override
  State<BudgetPlanWidget> createState() => _BudgetPlanWidgetState();
}

class _BudgetPlanWidgetState extends State<BudgetPlanWidget> {
  // Categorías
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

  // Método para calcular la distribución del presupuesto
  Map<String, Map<String, dynamic>> _calculateBudgetDistribution(
      List<TransactionDto> transactions, double totalIncome) {
    // Inicializar gastos por categoría
    double spentNeeds = 0;
    double spentWants = 0;
    double savedAmount = 0;

    // Calcular gastos por categoría
    for (var transaction in transactions) {
      switch (_getGlobalCategory(transaction.category)) {
        case 'Necesidades':
          if (transaction.type == 'Gasto') spentNeeds += transaction.amount;
          break;
        case 'Deseos':
          if (transaction.type == 'Gasto') spentWants += transaction.amount;
          break;
        case 'Ahorros':
          if (transaction.type == 'Ingreso') savedAmount += transaction.amount;
          break;
      }
    }

    // Calcular presupuestos según la regla 50/30/20
    double needsBudget = totalIncome * 0.50;
    double wantsBudget = totalIncome * 0.30;
    double savingsBudget = totalIncome * 0.20;

    // Calcular disponibilidad
    double needsAvailable = needsBudget - spentNeeds;
    double wantsAvailable = wantsBudget - spentWants;
    double savingsAvailable = savingsBudget - savedAmount;

    // Calcular porcentajes
    double needsPercentage =
        needsBudget > 0 ? (spentNeeds / needsBudget) * 100 : 0;
    double wantsPercentage =
        wantsBudget > 0 ? (spentWants / wantsBudget) * 100 : 0;
    double savingsPercentage =
        savingsBudget > 0 ? (savedAmount / savingsBudget) * 100 : 0;

    return {
      'Necesidades': {
        'spent': spentNeeds,
        'budget': needsBudget,
        'available': needsAvailable,
        'percentage': needsPercentage,
        'isExceeded': needsPercentage > 100,
      },
      'Deseos': {
        'spent': spentWants,
        'budget': wantsBudget,
        'available': wantsAvailable,
        'percentage': wantsPercentage,
        'isExceeded': wantsPercentage > 100,
      },
      'Ahorros': {
        'spent': savedAmount,
        'budget': savingsBudget,
        'available': savingsAvailable,
        'percentage': savingsPercentage,
        'isExceeded': savingsPercentage > 100,
      },
    };
  }

  // Obtener color para la barra de progreso según el porcentaje
  Color _getProgressColor(double percentage, bool isExceeded) {
    if (isExceeded) return Colors.redAccent;
    if (percentage > 85) return Colors.orangeAccent;
    if (percentage > 65) return Colors.yellowAccent;
    return Colors.greenAccent;
  }

  // Método para obtener el ícono de categoría
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

  String _getCategoryTooltip(String category) {
    switch (category) {
      case 'Necesidades':
        return 'Gastos esenciales (50%): vivienda, alimentación, servicios básicos, etc.';
      case 'Deseos':
        return 'Gastos no esenciales (30%): entretenimiento, ropa, viajes, etc.';
      case 'Ahorros':
        return 'Fondos para futuro (20%): emergencias, inversiones, metas a largo plazo';
      default:
        return category;
    }
  }

  // Método para obtener el color de categoría
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

  // Widget para cada categoría en la sección de distribución de gastos
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
          Tooltip(
            message: _getCategoryTooltip(category),
            decoration: BoxDecoration(
              color: currentTheme.getTitleColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
            child: Container(
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
          ),
          const SizedBox(width: 12),

          // Información de la categoría
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primera fila: Porcentaje y valores
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Nombre de la categoría
                        Text(
                          category,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentTheme.getTitleColor(),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Porcentaje con color dinámico
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isExceeded
                                ? Colors.redAccent.withOpacity(0.2)
                                : (percentage > 85
                                    ? Colors.orangeAccent.withOpacity(0.2)
                                    : Colors.greenAccent.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(percentage > 100 ? 100 : percentage).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: isExceeded
                                  ? Colors.redAccent
                                  : (percentage > 85
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Valor gastado
                    Text(
                      formatAbrevCurrency(spent),
                      style: TextStyle(
                        color: currentTheme.getSubtitleColor(),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentage > 100 ? 1 : percentage / 100,
                    backgroundColor:
                        currentTheme.getSubtitleColor().withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(percentage, isExceeded)),
                    minHeight: 8,
                  ),
                ),

                const SizedBox(height: 8),

                // Mensaje de disponibilidad
                Row(
                  children: [
                    Icon(
                      isExceeded ? Icons.warning_amber : Icons.check_circle,
                      color: isExceeded ? Colors.redAccent : Colors.greenAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isExceeded
                          ? 'Disponible: ${formatCurrency(available)}'
                          : 'Disponible: ${formatCurrency(available)}',
                      style: TextStyle(
                        color:
                            isExceeded ? Colors.redAccent : Colors.greenAccent,
                        fontSize: 14,
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

    // Calcular datos del presupuesto
    final budgetData =
        _calculateBudgetDistribution(widget.transactions, totalIncome);

    // Calcular el balance total (ingresos - gastos)
    double totalSpent = widget.transactions
        .where((transaction) => transaction.type == "Gasto")
        .fold(0, (sum, transaction) => sum + transaction.amount);

    double totalSaved = widget.transactions
        .where((transaction) =>
            transaction.type == "Ingreso" &&
            _getGlobalCategory(transaction.category) == "Ahorros")
        .fold(0, (sum, transaction) => sum + transaction.amount);

    // Balance actual
    double currentBalance = totalIncome - totalSpent;

    return Container(
      decoration: BoxDecoration(
        gradient: currentTheme.getGradientCard(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECCIÓN 1: Mi Plan con gráfico circular
          Row(
            children: [
              Text(
                'Mi Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: currentTheme.getTitleColor(),
                ),
              ),
              const Spacer(),
              // Botón de información
              Tooltip(
                message:
                    "La regla 50/30/20 sugiere destinar 50% de tus ingresos a necesidades, 30% a deseos y 20% a ahorros.",
                textStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: currentTheme.getSubtitleColor(),
                  ),
                  onPressed: () {
                    _showInfoDialog(context);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

// Gráfico circular
          Center(
            child: Stack(
              children: [
                // Gráfico base (mantén el código existente)
                SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Círculo exterior (distribución ideal)
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: RulePieChartPainter(
                            needsPercentage: 50,
                            wantsPercentage: 30,
                            savingsPercentage: 20,
                            needsColor: Colors.redAccent.withOpacity(0.3),
                            wantsColor: Colors.blueAccent.withOpacity(0.3),
                            savingsColor: Colors.greenAccent.withOpacity(0.3),
                            showBorder: true,
                          ),
                        ),
                      ),

                      // Círculo interior (progreso actual)
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: RulePieChartPainter(
                            needsPercentage:
                                budgetData['Necesidades']!['percentage'] > 50
                                    ? 50
                                    : budgetData['Necesidades']!['percentage'],
                            wantsPercentage:
                                budgetData['Deseos']!['percentage'] > 30
                                    ? 30
                                    : budgetData['Deseos']!['percentage'],
                            savingsPercentage:
                                budgetData['Ahorros']!['percentage'] > 20
                                    ? 20
                                    : budgetData['Ahorros']!['percentage'],
                            needsColor: Colors.redAccent,
                            wantsColor: Colors.blueAccent,
                            savingsColor: Colors.greenAccent,
                            showBorder: true,
                          ),
                        ),
                      ),

                      // Centro con balance
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: currentTheme.getBackgroundColor(),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Balance',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: currentTheme.getSubtitleColor()),
                              ),
                              Text(
                                formatAbrevCurrency(currentBalance),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: currentTheme.getTitleColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Áreas de tooltip para cada sección del gráfico
                // Necesidades (sección superior)
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  height: 50,
                  child: Tooltip(
                    message:
                        'Necesidades (50%): Gastos esenciales como vivienda, comida, servicios',
                    preferBelow: true,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),

                // Deseos (sección derecha)
                Positioned(
                  right: 20,
                  top: 60,
                  width: 50,
                  height: 70,
                  child: Tooltip(
                    message:
                        'Deseos (30%): Gastos no esenciales como entretenimiento, ropa',
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),

                // Ahorros (sección izquierda)
                Positioned(
                  left: 20,
                  top: 60,
                  width: 50,
                  height: 70,
                  child: Tooltip(
                    message:
                        'Ahorros (20%): Fondos para emergencia, inversiones, metas',
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // SECCIÓN 2: Distribución de gastos (barras de progreso detalladas)
          Text(
            'Distribución de gastos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: currentTheme.getSubtitleColor(),
            ),
          ),

          const SizedBox(height: 12),

          // Lista de categorías con detalles
          ...budgetData.entries.map((entry) {
            return _buildCategoryItem(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  // Diálogo de información sobre el método 50/30/20
  void _showInfoDialog(BuildContext context) {
    final currentTheme = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Regla 50/30/20',
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
              'Esta distribución te ayuda a organizar tus finanzas:',
              style: TextStyle(color: currentTheme.getSubtitleColor()),
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'Necesidades (50%)',
              'Gastos esenciales como comida, vivienda, servicios.',
              Colors.redAccent,
              currentTheme,
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Deseos (30%)',
              'Gastos no esenciales como entretenimiento, ropa.',
              Colors.blueAccent,
              currentTheme,
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Ahorros (20%)',
              'Fondos para emergencias, inversiones, metas.',
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
}

// Clase para dibujar el gráfico circular
class RulePieChartPainter extends CustomPainter {
  final double needsPercentage;
  final double wantsPercentage;
  final double savingsPercentage;
  final Color needsColor;
  final Color wantsColor;
  final Color savingsColor;
  final bool showBorder;

  RulePieChartPainter({
    required this.needsPercentage,
    required this.wantsPercentage,
    required this.savingsPercentage,
    required this.needsColor,
    required this.wantsColor,
    required this.savingsColor,
    this.showBorder = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Convertir porcentajes a radianes
    final double needsRadians = 2 * pi * (needsPercentage / 100);
    final double wantsRadians = 2 * pi * (wantsPercentage / 100);
    final double savingsRadians = 2 * pi * (savingsPercentage / 100);

    // Dibujar los arcos
    final paint = Paint()..style = PaintingStyle.fill;

    // Necesidades (comenzando desde arriba)
    paint.color = needsColor;
    canvas.drawArc(rect, -pi / 2, needsRadians, true, paint);

    // Deseos
    paint.color = wantsColor;
    canvas.drawArc(rect, -pi / 2 + needsRadians, wantsRadians, true, paint);

    // Ahorros
    paint.color = savingsColor;
    canvas.drawArc(rect, -pi / 2 + needsRadians + wantsRadians, savingsRadians,
        true, paint);

    // Opcional: Agregar bordes finos entre segmentos
    if (showBorder) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 0.5;

      // Borde entre necesidades y deseos
      if (needsPercentage > 0 && wantsPercentage > 0) {
        final needsEndAngle = -pi / 2 + needsRadians;
        canvas.drawLine(
          center,
          Offset(
            center.dx + cos(needsEndAngle) * radius,
            center.dy + sin(needsEndAngle) * radius,
          ),
          borderPaint,
        );
      }

      // Borde entre deseos y ahorros
      if (wantsPercentage > 0 && savingsPercentage > 0) {
        final wantsEndAngle = -pi / 2 + needsRadians + wantsRadians;
        canvas.drawLine(
          center,
          Offset(
            center.dx + cos(wantsEndAngle) * radius,
            center.dy + sin(wantsEndAngle) * radius,
          ),
          borderPaint,
        );
      }

      // Borde entre ahorros y necesidades (si el círculo está completo)
      if (savingsPercentage > 0 &&
          (needsPercentage + wantsPercentage + savingsPercentage) >= 99) {
        const savingsEndAngle = -pi / 2;
        canvas.drawLine(
          center,
          Offset(
            center.dx + cos(savingsEndAngle) * radius,
            center.dy + sin(savingsEndAngle) * radius,
          ),
          borderPaint,
        );
      }

      // Borde exterior
      canvas.drawCircle(center, radius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
