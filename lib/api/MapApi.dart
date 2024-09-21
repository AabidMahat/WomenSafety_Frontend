import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mega_project/consts.dart';
import 'package:http/http.dart' as http;


class GoogleMapAPI{

  Future<String> getPlace(double lat,double lng)async{
    final apiKey = GOOGLE_API_KEY;
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';

    try{
      final response = await http.get(Uri.parse(url));

      if(response.statusCode==200){
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
         final placeName = data['results'][0]['formatted_address'];
          return placeName;
        }
      }

    }catch(err){
      print("Failed to get place name $err");
    }
    return "Unknown Place";
  }

  Future<Map<String, dynamic>?> getLatLngFromPlaces(String placeName)async{
    final apiKey = GOOGLE_API_KEY;

    final String url  = "https://maps.googleapis.com/maps/api/geocode/json?address=$placeName&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    if(response.statusCode==200){
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        print(location);
        return {'lat': location['lat'], 'lng': location['lng']};
      }else{
        Fluttertoast.showToast(msg: "Not able to identify location");
        print('Error: ${data['status']}');
        return null;
      }
    }
    else {
      print('Error fetching coordinates: ${response.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDistanceAndDuration(
      LatLng origin, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?origins=${origin.latitude},${origin.longitude}&destinations=${destination.latitude},${destination.longitude}&key=$GOOGLE_API_KEY&mode=driving';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['rows'].isNotEmpty) {
        var elements = jsonData['rows'][0]['elements'][0];
        if (elements['status'] == 'OK') {
          final distance = elements['distance']['text'];
          final duration = elements['duration']['text'];

          return {
            'distance': distance,
            'duration': duration,
          };
        }
      }
    }
    return null;
  }

}