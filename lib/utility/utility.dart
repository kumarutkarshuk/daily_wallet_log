import 'package:daily_wallet_log/models/transaction_model.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

class Utility {
  static Future<void> readBankSMS() async {
    final telephony = Telephony.instance;
    final box = Hive.box<TransactionModel>('transactions');

    bool? granted = await telephony.requestSmsPermissions;
    if (granted ?? false) {
      // from last 24 hours
      List<SmsMessage> messages = await telephony.getInboxSms(
        filter: SmsFilter.where(SmsColumn.DATE).greaterThan(
          DateTime.now()
              .subtract(Duration(hours: 24))
              .millisecondsSinceEpoch
              .toString(),
        ),
      );

      // matching algo
      for (var msg in messages) {
        if (msg.body != null && msg.body!.toLowerCase().contains("rs")) {
          final match = RegExp(r'Rs\.? ?(\d+\.?\d*)').firstMatch(msg.body!);
          if (match != null) {
            double amount = double.parse(match.group(1)!);
            final alreadyExists = box.values.any((t) => t.message == msg.body);
            if (!alreadyExists) {
              box.add(
                TransactionModel(
                  amount,
                  msg.body!.toLowerCase().startsWith("credit") ? TransactionType.credit.index : TransactionType.debit.index,
                  DateTime.fromMillisecondsSinceEpoch(msg.date!),
                  msg.body!,
                ),
              );
            }
          }
        }
      }
    }
  }

  static Future<void> askNotificationsPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
}
