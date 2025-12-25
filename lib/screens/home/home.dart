import 'package:daily_wallet_log/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:telephony/telephony.dart';

final telephony = Telephony.instance;

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
    _readBankSMS();
  }

  Future<void> _readBankSMS() async {
    bool? granted = await telephony.requestSmsPermissions;
    if (granted ?? false) {
      List<SmsMessage> messages = await telephony.getInboxSms();

      for (var msg in messages) {
        if (msg.body != null && msg.body!.toLowerCase().contains("debited")) {
          final match = RegExp(r'Rs\.? ?(\d+\.?\d*)').firstMatch(msg.body!);
          if (match != null) {
            double amount = double.parse(match.group(1)!);
            final alreadyExists = box.values.any((t) => t.description == msg.body);
            if (!alreadyExists) {
              box.add(TransactionModel(amount, "debit", DateTime.fromMillisecondsSinceEpoch(msg.date!), msg.body!));
            }
          }
        }
      }

      setState(() {});
    }
  }

  // List<TransactionModel> _getTransactionsByRange(DateTime start, DateTime end) {
  //   final box = Hive.box<TransactionModel>('transactions');
  //   return box.values.where((t) => t.date.isAfter(start) && t.date.isBefore(end)).toList();
  // }

  // double _getTotal(List<TransactionModel> txns) =>
  //     txns.fold(0.0, (sum, t) => sum + t.amount);

  // final now = DateTime.now();
  // final weekAgo = now.subtract(const Duration(days: 7));
  // final weeklyTotal = getTotal(getTransactionsByRange(weekAgo, now));

  @override
  Widget build(BuildContext context) {
    final allTxns = box.values.toList();
    final totalSpent = allTxns
        .where((t) => t.type == "debit")
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Wallet Log"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _readBankSMS,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade100,
            width: double.infinity,
            child: Text(
              "Total Spent: ₹${totalSpent.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            // for listening to Hive DB changes
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box<TransactionModel> box, _) {
                final txns = box.values.toList().reversed.toList();
                if (txns.isEmpty) {
                  return const Center(child: Text("No transactions found"));
                }
                return ListView.builder(
                  itemCount: txns.length,
                  itemBuilder: (context, i) {
                    final t = txns[i];
                    return ListTile(
                      title: Text("₹${t.amount} ${t.type}"),
                      subtitle: Text(t.description),
                      trailing: Text(
                        "${t.date.day}/${t.date.month}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}