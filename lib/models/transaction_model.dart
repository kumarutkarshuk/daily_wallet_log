import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final String type; // "credit" or "debit"

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String description;

  TransactionModel(this.amount, this.type, this.date, this.description);
}