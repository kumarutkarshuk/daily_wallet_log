import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  // final TransactionType type; // hive can't store enums directly
  final int typeIndex;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String message;

  TransactionModel(this.amount, this.typeIndex, this.date, this.message);

  TransactionType get type => TransactionType.values[typeIndex];
}

enum TransactionType {
  credit, debit
}