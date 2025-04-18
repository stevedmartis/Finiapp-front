import 'package:finiapp/constants.dart';
import 'package:finiapp/screens/dashboard/components/header_custom.dart';
import 'package:finiapp/screens/providers/theme_provider.dart';
import 'package:finiapp/services/accounts_services.dart';
import 'package:finiapp/services/finance_summary_service.dart';
import 'package:finiapp/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final String? accountId;
  const AddTransactionBottomSheet({super.key, this.accountId});

  @override
  AddTransactionBottomSheetState createState() =>
      AddTransactionBottomSheetState();
}

class AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  late TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  int _selectedCategoryIndex = 0;
  bool _isIncome = true;
  bool _showMoreCategories = false;
  final DateTime _selectedDate = DateTime.now();
  bool _isEditing = false;
  String? _selectedAccountId;

  final List<Map<String, dynamic>> _categories = [
    {"icon": Icons.fastfood, "label": "Comida"},
    {"icon": Icons.directions_car, "label": "Transporte"},
    {"icon": Icons.health_and_safety, "label": "Salud"},
    {"icon": Icons.movie, "label": "Ocio"},
    {"icon": Icons.school, "label": "Educación"},
    {"icon": Icons.local_gas_station, "label": "Gasolina"},
    {"icon": Icons.directions_car_filled, "label": "Uber / Taxi"},
    {"icon": Icons.tv, "label": "Streaming"},
    {"icon": Icons.home, "label": "Hogar"},
    {"icon": Icons.pets, "label": "Mascota"},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {"icon": Icons.attach_money, "label": "Sueldo"},
    {"icon": Icons.shopping_cart, "label": "Ventas"},
    {"icon": Icons.volunteer_activism, "label": "Donaciones"},
    {"icon": Icons.payments, "label": "Aportes"},
    {"icon": Icons.stars, "label": "Bonos"},
    {"icon": Icons.casino, "label": "Premios"},
    {"icon": Icons.redeem, "label": "Regalos"},
    {"icon": Icons.account_balance_wallet, "label": "Otros"},
  ];

  final List<Map<String, dynamic>> _extraCategories = [
    {"icon": Icons.shopping_bag, "label": "Ropa"},
    {"icon": Icons.sports_esports, "label": "Videojuegos"},
    {"icon": Icons.fitness_center, "label": "Gimnasio"},
    {"icon": Icons.card_giftcard, "label": "Regalos"},
    {"icon": Icons.flight_takeoff, "label": "Viajes"},
    {"icon": Icons.savings, "label": "Ahorro"},
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _selectedAccountId = widget.accountId ??
        Provider.of<AccountsProvider>(context, listen: false).currentAccountId;
  }

  void _onBalanceChanged(TextEditingController controller, String value) {
    if (_isEditing) return;
    _isEditing = true;
    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    double balance = double.tryParse(cleanValue) ?? 0;
    String formattedValue = formatCurrency(balance);
    controller.value = TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
    _isEditing = false;
  }

  List<Map<String, dynamic>> get _displayedCategories {
    if (_isIncome) {
      return _incomeCategories;
    } else {
      return _showMoreCategories
          ? [..._categories, ..._extraCategories]
          : _categories;
    }
  }

  void _saveTransaction() {
    String cleanBalance =
        _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    double amount = double.tryParse(cleanBalance) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor ingresa un monto válido.")),
      );
      return;
    }

    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final financialProvider =
        Provider.of<FinancialDataService>(context, listen: false);

    if (_selectedCategoryIndex < 0 ||
        _selectedCategoryIndex >= _displayedCategories.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor selecciona una categoría válida.')),
      );
      return;
    }

    String selectedCategory =
        _displayedCategories[_selectedCategoryIndex]['label'];
    final String transactionId = const Uuid().v4();

    TransactionDto newTransaction = TransactionDto(
      id: transactionId,
      type: _isIncome ? "Ingreso" : "Gasto",
      amount: amount,
      category: selectedCategory,
      date: DateFormat('dd-MM-yyyy').format(_selectedDate),
      note: _noteController.text,
      accountId: _selectedAccountId!,
    );

    transactionProvider.addTransaction(newTransaction);
    financialProvider.addTransactionToSummary(newTransaction);

    setState(() {
      _selectedCategoryIndex = -1;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Provider.of<ThemeProvider>(context);
    final accountsProvider = Provider.of<AccountsProvider>(context);
    final accounts = accountsProvider.accounts;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _showMoreCategories ? 1.0 : 0.75,
      minChildSize: 0.5,
      maxChildSize: _showMoreCategories ? 1.0 : 0.75,
      builder: (context, scrollController) {
        return Container(
          padding:
              EdgeInsets.fromLTRB(16, _showMoreCategories ? 45 : 24, 16, 16),
          decoration: BoxDecoration(
            color: currentTheme.getBackgroundColor(),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Registrar movimiento",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: currentTheme.getTitleColor()),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: currentTheme.getSubtitleColor()),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(Icons.arrow_upward,
                        color: _isIncome ? Colors.white : Colors.green),
                    label: const Text("Ingreso"),
                    selected: _isIncome,
                    selectedColor: Colors.green,
                    backgroundColor:
                        currentTheme.getTitleColor().withOpacity(0.2),
                    onSelected: (val) => setState(() => _isIncome = true),
                    labelStyle: TextStyle(
                        color: _isIncome ? Colors.white : Colors.green),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(Icons.arrow_downward,
                        color: !_isIncome ? Colors.white : Colors.red),
                    label: const Text("Gasto"),
                    selected: !_isIncome,
                    selectedColor: Colors.red,
                    backgroundColor: Colors.black26,
                    onSelected: (val) => setState(() => _isIncome = false),
                    labelStyle: TextStyle(
                        color: !_isIncome ? Colors.white : Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField(
                value: _selectedAccountId,
                onChanged: (value) {
                  setState(() {
                    _selectedAccountId = value as String;
                  });
                },
                items: accounts.map((account) {
                  return DropdownMenuItem(
                    value: account.id,
                    child: Text(account.name),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Cuenta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField("Monto", _amountController, isNumeric: true),
              const SizedBox(height: 20),
              Text("Categoría",
                  style: TextStyle(color: currentTheme.getTitleColor())),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _displayedCategories
                    .map((category) => _buildCategoryChip(category))
                    .toList(),
              ),
              if (!_isIncome)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showMoreCategories = !_showMoreCategories;
                    });
                  },
                  child: Text(
                    _showMoreCategories ? "Ver menos" : "Ver más categorías",
                    style: const TextStyle(color: Colors.purpleAccent),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: currentTheme.getSubtitleColor(),
                    backgroundColor: _isIncome ? Colors.green : Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveTransaction,
                  child: Text(
                    "Agregar ${_isIncome ? 'Ingreso' : 'Gasto'} ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumeric = false, Function(String)? onChanged}) {
    final currentTheme = Provider.of<ThemeProvider>(context);
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
      style: TextStyle(color: currentTheme.getTitleColor()),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: currentTheme.getSubtitleColor()),
        filled: true,
        fillColor: currentTheme.getCardColor(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color:
                currentTheme.getSubtitleColor(), // ✅ Borde cuando no enfocado
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(Map<String, dynamic> category) {
    final currentTheme = Provider.of<ThemeProvider>(context);
    int index = _displayedCategories.indexOf(category);
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryIndex = index),
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor:
                _selectedCategoryIndex == index ? logoCOLOR2 : Colors.grey[800],
            child: Icon(category['icon'], color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(category['label'],
              style:
                  TextStyle(color: currentTheme.getTitleColor(), fontSize: 12)),
        ],
      ),
    );
  }
}
