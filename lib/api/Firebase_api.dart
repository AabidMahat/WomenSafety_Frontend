import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mega_project/shake.dart';
import 'package:shared_preferences/shared_preferences.dart';


Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}

class FirebaseApi {
  // Instance of Firebase Messaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? FIREBASE_TOKEN;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Android notification channel for important notifications
  final AndroidNotificationChannel _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    "High Importance Notifications",
    description: "This channel is used for important notifications",
    importance: Importance.high, // Use 'Importance.high' to ensure notifications are displayed prominently
  );

  final FlutterLocalNotificationsPlugin _localNotification = FlutterLocalNotificationsPlugin();

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    navigatorKey.currentState?.pushNamed("/shake");
  }

  // Function to initialize notifications
  Future<void> initPushNotification() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle the message when the app is initially opened
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    // Handle the message when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Listen to messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;

      if (notification == null) return;

      _localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@drawable/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
    });
  }

  Future<void> initLocalNotification() async {
    const android = AndroidInitializationSettings('@drawable/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _localNotification.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload == null) return;
        final message = RemoteMessage.fromMap(jsonDecode(response.payload!));
        handleMessage(message);
      },
    );

    final platform = _localNotification.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await platform?.createNotificationChannel(_androidChannel);
  }

  Future<void> initNotification() async {
    await _firebaseMessaging.requestPermission();

    final firebaseToken = await _firebaseMessaging.getToken();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString("firebaseToken", firebaseToken!);
    print("Firebase Token: $firebaseToken");

    await initPushNotification();
    await initLocalNotification();
  }

  Future<String> uploadVideo(String videoUrl)async{
      Reference ref = _storage.ref().child('videos/${DateTime.now()}.mp4');

      await ref.putFile(File(videoUrl));

      String downloadUrl = await ref.getDownloadURL();

      return downloadUrl;

  }
}
