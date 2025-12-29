import 'package:daily_wallet_log/models/transaction_model.dart';
import 'package:daily_wallet_log/utility/utility.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

// dispatcher is a traffic controller for background tasks
// ask compiler not the remove this code which it might as it might think it to be not useful
// must be outside a class
@pragma('vm:entry-point')
void callbackDispatcher() {
  // runs independently with its own memory
  Workmanager().executeTask((_, _) async {
    return await BackgroundJob.processTransactionsFromLastDay();
  });
}

class BackgroundJob {
  static Future<bool> processTransactionsFromLastDay() async {
    // print("executing background task...");
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    // required as main won't run in background
    await Hive.initFlutter();

    // Initialize notifications for this background isolate
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launch_background');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await notifications.initialize(initializationSettings);

    // prevent duplicate registration error
    if (!Hive.isAdapterRegistered(TransactionModelAdapter().typeId)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }

    var box = await Hive.openBox<TransactionModel>('transactions');

    await box.clear();
    await Utility.readBankSMS();

    // print("box values length: ${box.values.length}");

    final today = DateTime.now();
    final totalSpent = box.values
        .where(
          (t) => t.date.day == today.day && t.type == TransactionType.debit,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalEarned = box.values
        .where(
          (t) => t.date.day == today.day && t.type == TransactionType.credit,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily',
        'Daily Wallet Log',
        icon: 'launch_background',
      ), // icon must
    );
    await notifications.cancel(1);
    await notifications.show(
      1,
      "Daily Wallet Log",
      "₹${totalSpent.toStringAsFixed(2)} spent, ₹${totalEarned.toStringAsFixed(2)} earned today",
      details,
    );

    await Workmanager().registerOneOffTask(
      "dailyTask",
      "dailyTask",
      existingWorkPolicy: ExistingWorkPolicy.replace,
      initialDelay: const Duration(days: 1),
    );

    return true;
  }
}
