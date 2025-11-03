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

  factory TransactionWithDetails.fromMap(Map<String, dynamic> map) {
    IconData? _parseIconData(dynamic iconCodePoint) {
      if (iconCodePoint is int) {
        return IconData(iconCodePoint, fontFamily: 'MaterialIcons');
      } else if (iconCodePoint is String && iconCodePoint.isNotEmpty) {
        try {
          return IconData(int.parse(iconCodePoint), fontFamily: 'MaterialIcons');
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    Color? _parseColor(dynamic colorValue) {
      if (colorValue is int) {
        return Color(colorValue);
      } else if (colorValue is String && colorValue.isNotEmpty) {
        try {
          return Color(int.parse(colorValue));
        } catch (e) {
          return null;
        }
      }
      return null;
    }

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
      categoryIcon: _parseIconData(map[DbHelper.CATEGORY_ICON]),
      categoryColor: _parseColor(map[DbHelper.CATEGORY_COLOR]),
    );
  }
}
