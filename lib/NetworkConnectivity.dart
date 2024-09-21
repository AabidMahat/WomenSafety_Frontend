import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mega_project/api/NotificationApi.dart';


class ConnectivityService {
  late StreamSubscription<ConnectivityResult> _subscription;
  bool isDeviceConnected = false;
  bool isAlertSet = false;

  ConnectivityService() {
    _initializeConnectivity();
  }

  /// Initializes connectivity monitoring.
  void _initializeConnectivity() {
    _subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
      await _checkInternetConnection();
    });
  }

  /// Checks if the device is connected to the internet and triggers notification if not.
  Future<void> _checkInternetConnection() async {
    isDeviceConnected = await InternetConnectionChecker().hasConnection;

    if (!isDeviceConnected && !isAlertSet) {
      _showFirebaseNotification();
      isAlertSet = true;
    } else if (isDeviceConnected && isAlertSet) {
      isAlertSet = false; // Reset alert state when connection is restored
    }
  }

  /// Handles the display of Firebase notifications.
  void _showFirebaseNotification() {
    // Your notification logic goes here
    sendNotification();
    print("No internet connection. Please check your network.");
  }

  /// Cancels the subscription to avoid memory leaks.
  void dispose() {
    _subscription.cancel();
  }
}
