import 'dart:async';

import 'package:daily_wallet_log/models/transaction_model.dart';
import 'package:daily_wallet_log/screens/home/home.dart';
import 'package:daily_wallet_log/utility/background_job.dart';
import 'package:daily_wallet_log/utility/utility.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  await Hive.openBox<TransactionModel>('transactions');

  await Utility.askNotificationsPermission();

  // android's limitation of min 15 mins for scheduled tasks
  await Workmanager().initialize(BackgroundJob.callbackDispatcher);
  await Workmanager().registerPeriodicTask("1", "dailyTask",
      frequency: const Duration(hours: 24), existingWorkPolicy: ExistingPeriodicWorkPolicy.replace);

  // testing
  Timer.periodic(const Duration(seconds: 10), (timer) {
    BackgroundJob.processTransactionsFromLastDay();
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}
