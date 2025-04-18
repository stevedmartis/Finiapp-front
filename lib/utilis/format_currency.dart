String formatAbrevCurrency(double amount) {
  bool isNegative = amount < 0;
  double absAmount = amount.abs();
  String prefix = isNegative ? "-\$" : "\$";

  String formatValue(double value, String suffix) {
    String result = value.toStringAsFixed(1);
    if (result.endsWith(".0")) {
      result = result.substring(0, result.length - 2);
    }
    return '$prefix$result$suffix';
  }

  if (absAmount >= 1e9) {
    return formatValue(absAmount / 1e9, "B");
  } else if (absAmount >= 1e6) {
    return formatValue(absAmount / 1e6, "M");
  } else if (absAmount >= 1e3) {
    return formatValue(absAmount / 1e3, "K");
  } else {
    return absAmount % 1 == 0
        ? '$prefix${absAmount.toInt()}'
        : '$prefix${absAmount.toStringAsFixed(2)}';
  }
}
