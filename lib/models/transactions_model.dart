import 'package:budget/screens/database/db_helper.dart';
import 'package:flutter/material.dart';

class TransactionWithDetails {
  final int? id;
  final double amount;
  final String type;
  final DateTime date;
  final String? description;
  final int? accountId;
  final String? accountName;
  final int? categoryId;
  final String? categoryName;
  final IconData? categoryIcon;
  final Color? categoryColor;

  TransactionWithDetails({
    this.id,
    required this.amount,
    required this.type,
    required this.date,
    this.description,
    this.accountId,
    this.accountName,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  // Liste statique avec les codes de points corrects pour résoudre le tree-shaking
  static final Map<String, IconData> _iconMap = {
    '58700': Icons.shopping_cart,
    '57946': Icons.fastfood,
    '57933': Icons.directions_car,
    '58412': Icons.movie,
    '58509': Icons.house,
    '59721': Icons.work,
    '59229': Icons.savings,
    '60233': Icons.receipt_long,
    '58807': Icons.medical_services,
    '59313': Icons.school,
    '58801': Icons.local_gas_station,
    '59056': Icons.phone_android,
    '59682': Icons.train,
    '58763': Icons.lightbulb_outline,
    '59013': Icons.pets,
    '59508': Icons.book,
    '57749': Icons.airplanemode_active, 
    '60249': Icons.fitness_center,
    // Ajoutez d'autres icônes ici si nécessaire
  };

  static IconData? _getIconByCodePoint(dynamic codePointValue) {
    if (codePointValue == null) return null;

    String key;
    if (codePointValue is num) {
      key = codePointValue.toInt().toString();
    } else {
      key = codePointValue.toString().trim();
    }

    return _iconMap[key];
  }

  static Color? _parseColor(dynamic colorValue) {
    if (colorValue is String && colorValue.startsWith('#')) {
      final hexColor = colorValue.replaceFirst('#', '');
      if (hexColor.length == 6) {
        return Color(int.parse("FF$hexColor", radix: 16));
      }
    } else if (colorValue is int) {
      return Color(colorValue);
    }
    return null;
  }

  factory TransactionWithDetails.fromMap(Map<String, dynamic> map) {
    return TransactionWithDetails(
      id: map[DbHelper.TRANSACTION_ID] as int?,
      amount: (map[DbHelper.MONTANT] as num?)?.toDouble() ?? 0.0,
      type: map[DbHelper.TRANSACTION_TYPE] as String? ?? 'expense',
      date: map[DbHelper.TRANSACTION_DATE] != null ? DateTime.parse(map[DbHelper.TRANSACTION_DATE] as String) : DateTime.now(),
      description: map[DbHelper.TRANSACTION_DESCRIPTION] as String?,
      accountId: map[DbHelper.ACCOUNT_ID] as int?,
      accountName: map[DbHelper.ACCOUNT_NAME] as String?,
      categoryId: map[DbHelper.CATEGORY_ID] as int?,
      categoryName: map[DbHelper.CATEGORY_NAME] as String?,
      categoryIcon: _getIconByCodePoint(map[DbHelper.CATEGORY_ICON]),
      categoryColor: _parseColor(map[DbHelper.CATEGORY_COLOR]),
    );
  }
}
