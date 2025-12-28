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
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerOneOffTask(
    "dailyTask",
    "dailyTask",
    existingWorkPolicy: ExistingWorkPolicy.replace,
    initialDelay: Utility.delayUntil(22, 0),
  );
  // testing
  // Timer.periodic(const Duration(seconds: 10), (timer) {
  //   BackgroundJob.processTransactionsFromLastDay();
  // });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}
