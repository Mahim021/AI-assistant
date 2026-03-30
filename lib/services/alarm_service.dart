import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart'; // needed for FLAG_ACTIVITY_NEW_TASK

class AlarmService {
  /// Returns an [AlarmTime] if [text] looks like an alarm request, else null.
  static AlarmTime? parseAlarmRequest(String text) {
    final lower = text.toLowerCase();

    final isRequest = lower.contains('alarm') ||
        lower.contains('wake me up') ||
        lower.contains('wake me at') ||
        lower.contains('set a reminder');
    if (!isRequest) return null;

    // Match patterns: "7", "7:30", "7 am", "7:30pm", "07:00"
    final match = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    ).firstMatch(lower);

    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3)?.toLowerCase();

    if (period == 'pm' && hour != 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;

    if (hour > 23 || minute > 59) return null;

    return AlarmTime(hour: hour, minute: minute);
  }

  /// Fires the Android SET_ALARM intent with [time].
  static Future<void> setAlarm(AlarmTime time, {String label = 'AI Assistant'}) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.HOUR': time.hour,
        'android.intent.extra.alarm.MINUTES': time.minute,
        'android.intent.extra.alarm.MESSAGE': label,
        'android.intent.extra.alarm.VIBRATE': true,
      },
    );
    await intent.launch();
  }
}

class AlarmTime {
  final int hour;
  final int minute;

  const AlarmTime({required this.hour, required this.minute});

  String get formatted {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}
