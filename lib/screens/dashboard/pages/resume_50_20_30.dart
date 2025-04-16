import 'dart:math';
import 'package:finiapp/screens/dashboard/components/header_custom.dart';
import 'package:finiapp/screens/providers/theme_provider.dart';
import 'package:finiapp/utilis/format_currency.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Rule50_30_20Widget extends StatelessWidget {
  final double totalIncome;
  final double totalNeeds;
  final double totalWants;
  final double totalSavings;

  const Rule50_30_20Widget({
    super.key,
    required this.totalIncome,
    required this.totalNeeds,
    required this.totalWants,
    required this.totalSavings,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = Provider.of<ThemeProvider>(context);

    // Calcular presupuestos basados en el total de ingresos
    final double needsBudget = totalIncome * 0.5;
    final double wantsBudget = totalIncome * 0.3;
    final double savingsBudget = totalIncome * 0.2;

    // Calcular porcentajes de uso (para la visualización)
    final double needsPercentage =
        needsBudget > 0 ? (totalNeeds / needsBudget) * 100 : 0;
    final double wantsPercentage =
        wantsBudget > 0 ? (totalWants / wantsBudget) * 100 : 0;
    final double savingsPercentage =
        savingsBudget > 0 ? (totalSavings / savingsBudget) * 100 : 0;

    // Calcular disponibilidad
    final double needsAvailable = needsBudget - totalNeeds;
    final double wantsAvailable = wantsBudget - totalWants;
    final double savingsAvailable = savingsBudget - totalSavings;

    // Calcular si hay exceso (gastos mayores al presupuesto)
    final bool needsExceeded = needsAvailable < 0;
    final bool wantsExceeded = wantsAvailable < 0;
    final bool savingsExceeded = savingsAvailable < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    // Mostrar diálogo explicativo si se necesita más detalle
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Sobre la Regla 50/30/20"),
                        content: const Text(
                            "La regla 50/30/20 es una guía simple para el presupuesto personal:\n\n"
                            "• 50% para Necesidades: gastos esenciales como vivienda, comida, servicios y transporte.\n\n"
                            "• 30% para Deseos: gastos no esenciales como entretenimiento, ropa, salidas y suscripciones.\n\n"
                            "• 20% para Ahorros: dinero destinado a ahorros, inversiones y pago de deudas.\n\n"
                            "Esta distribución te ayuda a mantener un equilibrio entre disfrutar del presente y construir tu futuro financiero."),
                        backgroundColor: currentTheme.getCardColor(),
                        titleTextStyle: TextStyle(
                          color: currentTheme.getSubtitleColor(),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        contentTextStyle: TextStyle(
                          color: currentTheme.getSubtitleColor(),
                          fontSize: 14,
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Entendido"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gráfico circular dividido en 3 secciones
          Center(
            child: SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Círculo de fondo que muestra la distribución ideal
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

                  // Círculo interior que muestra el progreso actual
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: RulePieChartPainter(
                        needsPercentage:
                            needsPercentage > 50 ? 50 : needsPercentage,
                        wantsPercentage:
                            wantsPercentage > 30 ? 30 : wantsPercentage,
                        savingsPercentage:
                            savingsPercentage > 20 ? 20 : savingsPercentage,
                        needsColor: Colors.redAccent,
                        wantsColor: Colors.blueAccent,
                        savingsColor: Colors.greenAccent,
                        showBorder: true,
                      ),
                    ),
                  ),

                  // Centro del círculo con el texto de balance
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
                            formatAbrevCurrency(totalIncome),
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
          ),

          // Leyenda y detalles mejorados
          const SizedBox(height: 16),
          _buildLegendItem(
              'Necesidades',
              needsPercentage,
              needsBudget,
              totalNeeds,
              Colors.redAccent,
              Icons.shopping_cart,
              currentTheme,
              needsExceeded),
          const SizedBox(height: 8),
          _buildLegendItem('Deseos', wantsPercentage, wantsBudget, totalWants,
              Colors.blueAccent, Icons.star, currentTheme, wantsExceeded),
          const SizedBox(height: 8),
          _buildLegendItem(
              'Ahorro',
              savingsPercentage,
              savingsBudget,
              totalSavings,
              Colors.greenAccent,
              Icons.savings,
              currentTheme,
              savingsExceeded),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      String title,
      double percentage,
      double budget,
      double actual,
      Color color,
      IconData icon,
      ThemeProvider currentTheme,
      bool isExceeded) {
    bool isIncome = title == 'Ahorro';

    // Calcular disponible y exceso
    double available = budget - actual;

    // Progress indicator value entre 0.0 y 1.0
    double progressValue = min(actual / budget, 1.0);

    // Color para la barra de progreso
    Color progressColor = isExceeded ? Colors.redAccent : color;

    // Color para el texto de disponibilidad
    Color availableTextColor =
        isExceeded ? Colors.redAccent : Colors.greenAccent;

    return Row(
      children: [
        // Ícono de categoría
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),

        // Nombre de categoría y barra de progreso
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: currentTheme.getTitleColor(),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor:
                      currentTheme.getSubtitleColor().withOpacity(0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              // Disponible o Excedido
              Text(
                'Disponible: ${formatCurrency(available)}',
                style: TextStyle(
                  color: availableTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Detalles financieros
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Monto actual / presupuesto
            Text(
              '${formatAbrevCurrency(actual)}/${formatAbrevCurrency(budget)}',
              style: TextStyle(
                color: isExceeded
                    ? Colors.redAccent
                    : currentTheme.getTitleColor(),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Para el ahorro, mostrar el indicador de ingreso
            if (isIncome && actual > 0)
              Text(
                '+${formatAbrevCurrency(actual)}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

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
