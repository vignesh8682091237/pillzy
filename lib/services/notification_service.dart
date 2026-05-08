import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'dart:async';

// Conditional import to prevent errors on Android
import 'web_notification_helper.dart' if (dart.library.html) 'dart:html' as html;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static final StreamController<String?> onNotificationClick = 
      StreamController<String?>.broadcast();

  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint("Requesting Web Notification permissions...");
      if (html.Notification.permission != 'granted') {
        await html.Notification.requestPermission();
      }
      return;
    }
    
    try {
      tz.initializeTimeZones();
      
      // Initialize Alarm Manager
      await AndroidAlarmManager.initialize();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("Notification Interaction: ${response.actionId ?? 'Click'}");
          onNotificationClick.add(response.actionId ?? 'click');
        },
      );
      
      // Request Permission for Android 13+
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      // Request Exact Alarm permission for Android 12+
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
      
      // Create a high-priority channel for heads-up notifications
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'pill_reminders_high',
        'Urgent Pill Reminders',
        description: 'This channel is used for high-priority medicine alerts.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

    } catch (e) {
      debugPrint("Notification Init Error: $e");
    }
  }

  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      if (html.Notification.permission == 'granted') {
        final notification = html.Notification(title, body: body, icon: 'assets/logo.png');
        notification.onClick.listen((event) {
          onNotificationClick.add('action_taken');
        });
      }
      return;
    }
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pill_reminders_high',
      'Urgent Pill Reminders',
      channelDescription: 'This channel is used for high-priority medicine alerts.',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(''),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_taken',
          'Taken',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'action_skip',
          'Skip',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, platformDetails);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (kIsWeb) {
      final now = DateTime.now();
      final delay = scheduledTime.difference(now);
      if (delay.isNegative) return;

      Timer(delay, () {
        showImmediateNotification(id: id, title: title, body: body);
      });
      return;
    }
    
    try {
      // 1. Local Notification Scheduling (for when app is in foreground/background)
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pill_reminders_high',
            'Urgent Pill Reminders',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            styleInformation: BigTextStyleInformation(''),
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'action_taken',
                'Taken',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'action_skip',
                'Skip',
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ],
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // 2. AlarmManager Scheduling (for when app is terminated/closed)
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

    } catch (e) {
      debugPrint("Schedule Notification Error: $e");
    }
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint("Cancel All Notifications Error: $e");
    }
  }
}

@pragma('vm:entry-point')
void alarmCallback(int id) {
  debugPrint("Alarm Fired for ID: $id");
  NotificationService.showImmediateNotification(
    id: id,
    title: "Medication Reminder",
    body: "It's time to take your medicine!",
  );
}
