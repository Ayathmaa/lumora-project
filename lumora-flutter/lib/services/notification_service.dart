import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// Action IDs used in the mood notification.
const String kMoodChannelId = 'lumora_mood';
const int kMoodNotificationId = 100;

// One action ID per mood score (1–5).
const String kActionMood1 = 'mood_1';
const String kActionMood2 = 'mood_2';
const String kActionMood3 = 'mood_3';
const String kActionMood4 = 'mood_4';
const String kActionMood5 = 'mood_5';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  Future<void> init({
    required void Function(NotificationResponse) onActionReceived,
  }) async {
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: onActionReceived,
      // Background action handler is registered as a top-level function in
      // main.dart because it must be a static / top-level function.
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
  }

  Future<void> requestPermissions() async {
    // Android 13+
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    // iOS
    final ios = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Schedule (or reschedule) the daily 7 PM mood reminder.
  Future<void> scheduleDailyMoodReminder() async {
    await flutterLocalNotificationsPlugin.cancel(kMoodNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    // If 7 PM has already passed today, schedule for tomorrow.
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      kMoodChannelId,
      'Daily Mood Reminder',
      channelDescription: 'Evening reminder to log your daily mood',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(kActionMood1, '😢'),
        AndroidNotificationAction(kActionMood2, '😔'),
        AndroidNotificationAction(kActionMood3, '😐'),
        AndroidNotificationAction(kActionMood4, '🙂'),
        AndroidNotificationAction(kActionMood5, '😊'),
      ],
    );

    // iOS uses a category with actions defined during init.
    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'mood_category',
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      kMoodNotificationId,
      'How was your day? 🌙',
      'Tap an emoji below to log your mood, or open Lumora.',
      scheduled,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // matchDateTimeComponents makes it repeat daily at 19:00.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMoodReminder() async {
    await flutterLocalNotificationsPlugin.cancel(kMoodNotificationId);
  }
}

// Must be a top-level function — handles actions when the app is terminated.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  // Mood saves from background are handled in main.dart which registers
  // this callback and has access to Firebase. We only need the entry-point
  // annotation here so the isolate is kept alive.
  handleMoodAction(response.actionId);
}

// Shared logic for both foreground and background action handling.
// Called by the top-level handler and by main.dart's foreground handler.
void handleMoodAction(String? actionId) {
  if (actionId == null) return;
  final score = switch (actionId) {
    kActionMood1 => 1,
    kActionMood2 => 2,
    kActionMood3 => 3,
    kActionMood4 => 4,
    kActionMood5 => 5,
    _ => null,
  };
  if (score == null) return;
  // Delegate to the registered callback set by main.dart.
  onNotificationMoodScore?.call(score);
}

// Mutable hook so main.dart can inject a save callback after Firebase is ready.
void Function(int score)? onNotificationMoodScore;
