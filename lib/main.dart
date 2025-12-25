import 'package:daily_wallet_log/models/transaction_model.dart';
import 'package:daily_wallet_log/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  await Hive.openBox<TransactionModel>('transactions');
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask("1", "dailyTask",
      frequency: const Duration(hours: 24));

  runApp(MyApp());
}

// dispatcher is a traffic controller for background tasks
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionModelAdapter());
    var box = await Hive.openBox<TransactionModel>('transactions');

    final today = DateTime.now();
    final dailyTotal = box.values
        .where((t) => t.date.day == today.day && t.type == "debit")
        .fold(0.0, (sum, t) => sum + t.amount);

    const details = NotificationDetails(
        android: AndroidNotificationDetails('daily', 'Daily Summary')
    );
    await notifications.show(0, "Daily Expense", "₹${dailyTotal.toStringAsFixed(2)} spent today", details);

    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}