import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> sendNotification() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? firebaseToken = prefs.getString('firebaseToken');
    print("Notification Token $firebaseToken");
    final String url =
        "https://womensafety-cppn.onrender.com/api/v3/notification/sendNotification";

    var TokenBody = {
      "fcm_token":firebaseToken
    };

    var response = await http.post(Uri.parse(url), body: TokenBody);
    print(response.statusCode);
    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: "Notification Send");
    } else {
      var responseError = json.decode(response.body);
      print(responseError);
      Fluttertoast.showToast(msg: "Error While Sending Notification");
    }
  } catch (err) {
    print(err);
    Fluttertoast.showToast(msg: "Error while sending notification");
  }
}

Future<void> makeCall()async{
  final String url = "https://womensafety-cppn.onrender.com/api/v3/notification/makeCall";
  try{
    var callBody ={
      "phoneNumber":"7559153594"
    };

    var response = await http.post(Uri.parse(url),body: json.encode(callBody),headers: {"Content-Type": "application/json"});

    if(response.statusCode==200){
      Fluttertoast.showToast(msg: "Call Initiated sucessfully");
    }
    else {
      var responseError = json.decode(response.body);
      print(responseError);
      Fluttertoast.showToast(msg: "Error While Making Call");
    }
  } catch (err) {
      print(err);
      Fluttertoast.showToast(msg: "Error while sending notification");
  }
}
