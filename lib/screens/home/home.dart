import 'package:daily_wallet_log/models/transaction_model.dart';
import 'package:daily_wallet_log/utility/utility.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> {
  final box = Hive.box<TransactionModel>('transactions');

  @override
  void initState() {
    super.initState();
    Utility.readBankSMS();
  }

  double _calcTotalAmount(
    List<TransactionModel> allTxns,
    TransactionType transactionType,
  ) {
    return allTxns
        .where((t) => t.type == transactionType)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Wallet Log"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await Utility.readBankSMS();
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<TransactionModel> box, _) {
          final txns = box.values.toList().reversed.toList();
          double totalSpent = _calcTotalAmount(txns, TransactionType.debit);
          double totalEarned = _calcTotalAmount(txns, TransactionType.credit);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade100,
                width: double.infinity,
                child: Text(
                  "Amount Spent: ₹${totalSpent.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 10),
                color: Colors.blue.shade100,
                width: double.infinity,
                child: Text(
                  "Amount Earned: ₹${totalEarned.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (txns.isEmpty)
                const Center(child: Text("No transactions found."))
              else
                Expanded(
                  // for listening to Hive DB changes
                  child: ListView.builder(
                    itemCount: txns.length,
                    itemBuilder: (context, i) {
                      final t = txns[i];
                      return ListTile(
                        title: Text("₹${t.amount} (${t.type.name})"),
                        subtitle: Text(t.message),
                        trailing: Text(
                          "${t.date.day}/${t.date.month}/${t.date.year}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
