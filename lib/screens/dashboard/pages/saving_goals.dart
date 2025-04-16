import 'package:finiapp/constants.dart';
import 'package:finiapp/models/savind_dto.dart';
import 'package:finiapp/screens/dashboard/components/header_custom.dart';
import 'package:finiapp/screens/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SavingGoalsWidget extends StatelessWidget {
  final List<SavingGoalDto> goals;
  final VoidCallback onAddGoal;

  const SavingGoalsWidget({
    super.key,
    required this.goals,
    required this.onAddGoal,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: currentTheme.getGradientCard(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.flag,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mis Metas de Ahorro',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: currentTheme.getTitleColor(),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: logoCOLOR1,
                ),
                onPressed: onAddGoal,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (goals.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.savings_outlined,
                    color: Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No tienes metas de ahorro',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Crea metas para organizar tus ahorros y visualizar tu progreso',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onAddGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Crear Meta'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: goals
                  .map((goal) => _buildGoalItem(goal, currentTheme))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(SavingGoalDto goal, ThemeProvider currentTheme) {
    final double progress = goal.currentAmount / goal.targetAmount;
    final int daysLeft = goal.targetDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentTheme.getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getGoalIcon(goal.category),
                  color: Colors.greenAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: currentTheme.getTitleColor(),
                      ),
                    ),
                    Text(
                      daysLeft > 0
                          ? '$daysLeft días restantes'
                          : 'Meta vencida',
                      style: TextStyle(
                        fontSize: 12,
                        color: daysLeft > 0 ? Colors.grey : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: progress >= 1 ? Colors.greenAccent : Colors.white,
                    ),
                  ),
                  Text(
                    '${formatCurrency(goal.currentAmount)}/${formatCurrency(goal.targetAmount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              backgroundColor: currentTheme.getSubtitleColor().withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1 ? Colors.greenAccent : Colors.purpleAccent,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon(String category) {
    switch (category.toLowerCase()) {
      case 'viaje':
        return Icons.flight;
      case 'educación':
        return Icons.school;
      case 'emergencia':
        return Icons.health_and_safety;
      case 'retiro':
        return Icons.beach_access;
      case 'inversión':
        return Icons.trending_up;
      default:
        return Icons.savings;
    }
  }
}
