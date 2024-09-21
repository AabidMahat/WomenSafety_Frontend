import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mega_project/Database/Database.dart';
import 'package:mega_project/FeedBack/FeedbackForm.dart';
import 'package:mega_project/api/FeedbackApi.dart';
import 'package:mega_project/api/MapApi.dart';

class FeedbackScreen extends StatefulWidget {
  final Position currentPosition;

  const FeedbackScreen({required this.currentPosition, super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  List<FeedbackData> feedbackList = [];
  final Completer<GoogleMapController> _mapController =
  Completer<GoogleMapController>();

  MapType _currentMapType = MapType.normal;

  FeedbackApi feedbackApi = new FeedbackApi();
  GoogleMapAPI googleMapAPI = new GoogleMapAPI();

  late CameraPosition _initialCameraPosition;

  @override
  void initState() {
    _fetchFeedbackData();
    _listenToFeedbackStream();
    super.initState();

    _initialCameraPosition = CameraPosition(
      target: LatLng(
          widget.currentPosition.latitude, widget.currentPosition.longitude),
      zoom: 17,
    );
  }

  void _listenToFeedbackStream() {
    feedbackApi.feedbackStream.listen((newFeedback) {
      setState(() {
        feedbackList.add(newFeedback);
        _showMarker(feedbackList);
        _renderDomeOnMap();
      });
    });
  }


  void _fetchFeedbackData()async {
     await feedbackApi.getAllFeedback();

     setState(() {
       feedbackList = feedbackApi.getFeedBackData().where((newFeedback) =>
       !feedbackList.any((existingFeedback) => existingFeedback.id == newFeedback.id)
       ).toList();
       _showMarker(feedbackList);
       _renderDomeOnMap();
     });

     print("FeedbackList ${feedbackList[feedbackList.length -1 ].comments}");
  }

  void _onMapTap(LatLng position) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return FeedbackForm(position: position);
        });
  }

  void _showMarker(List<FeedbackData> feedbackList) {
    setState(() {
      _markers.clear(); // Clear existing markers
    });
    feedbackList.forEach((feedback) async {
      Color markerColor = Colors.green;

      switch (feedback.category) {
        case 'Dangerous':
          markerColor = Colors.red;
          break;

        case 'Suspicious':
          markerColor = Colors.yellow;
          break;

        case 'Safe':
          markerColor = Colors.green;
          break;
      }

      String placeName = await googleMapAPI.getPlace(
          feedback.location['latitude']!, feedback.location['longitude']!);

      setState(() {
        _markers.add(Marker(
          markerId: MarkerId(feedback.id),
          infoWindow: InfoWindow(
            title: placeName, // Show the place name in the InfoWindow
            snippet: feedback.comments,
          ),
          onTap: (){
            _showMarkerOptions(feedback);
          },
          position: LatLng(
              feedback.location['latitude']!, feedback.location['longitude']!),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor == Colors.red
              ? BitmapDescriptor.hueRed
              : markerColor == Colors.yellow
                  ? BitmapDescriptor.hueYellow
                  : BitmapDescriptor.hueGreen),
        ));
      });
    });
  }

  void _showMarkerOptions(FeedbackData feedbackData) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("What do you want to do"),
            content:
                Text('You can either view the reviews or create a new review.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _showReviews(
                      feedbackData); // Show the reviews for the location
                },
                child: Text('See Reviews'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _createNewReview(
                      feedbackData); // Open the form to create a new review
                },
                child: Text('Create Review'),
              ),
            ],
          );
        });
  }

  void _showReviews(FeedbackData feedbackData) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true, // Makes the bottom sheet take full height if needed
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          minChildSize: 0.25,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Top indicator for dragging the sheet
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Reviews for Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  Divider(thickness: 1.5),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: feedbackList.length,
                      itemBuilder: (context, index) {
                        var currentFeedback = feedbackList[index];

                        if (currentFeedback.location['latitude'] ==
                            feedbackData.location['latitude'] &&
                            currentFeedback.location['longitude'] ==
                                feedbackData.location['longitude']) {
                          // Customize ListTile with more visuals and interaction
                          return Card(
                            elevation: 4,
                            color: Colors.white,
                            surfaceTintColor: Colors.white,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Icon(
                                _getFeedbackIcon(currentFeedback.category),
                                size: 40,
                                color: _getFeedbackColor(currentFeedback.category),
                              ),
                              title: Text(
                                currentFeedback.category,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getFeedbackColor(currentFeedback.category),
                                ),
                              ),
                              subtitle: Text(
                                currentFeedback.comments,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey[400],
                              ),
                            ),
                          );
                        }
                        return Container(); // Return empty container for other feedback
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getFeedbackIcon(String category) {
    switch (category) {
      case 'Dangerous':
        return Icons.warning_amber_rounded;
      case 'Suspicious':
        return Icons.help_outline_rounded;
      case 'Safe':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getFeedbackColor(String category) {
    switch (category) {
      case 'Dangerous':
        return Colors.redAccent;
      case 'Suspicious':
        return Colors.orangeAccent;
      case 'Safe':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }


  void _createNewReview(FeedbackData feedbackData) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext contexr) {
          return FeedbackForm(
              position: LatLng(feedbackData.location['latitude']!,
                  feedbackData.location['longitude']!));
        });
  }

  void _updateDomeRiskZone(List<FeedbackData> feedbackList) {
    Map<String, int> dangerCount = {};
    Map<String, int> suspiciousCount = {};
    Map<String, int> safeCount = {};

    for (var feedback in feedbackList) {
      String locationKey =
          '${feedback.location['latitude']!},${feedback.location['longitude']!}';

      if (feedback.category == 'Dangerous') {
        dangerCount[locationKey] = (dangerCount[locationKey] ?? 0) + 1;
      } else if (feedback.category == 'Suspicious') {
        suspiciousCount[locationKey] = (suspiciousCount[locationKey] ?? 0) + 1;
      } else if (feedback.category == 'Safe') {
        safeCount[locationKey] = (safeCount[locationKey] ?? 0) + 1;
      }
    }

    // Combine all location keys from the three categories
    Set<String> allLocations = {
      ...dangerCount.keys,
      ...suspiciousCount.keys,
      ...safeCount.keys
    };

    // Iterate over all unique locations to calculate dome zones
    allLocations.forEach((location) {
      int danger = dangerCount[location] ?? 0;
      int suspicious = suspiciousCount[location] ?? 0;
      int safe = safeCount[location] ?? 0;

      // Calculate the color intensity of the dome
      Color domeColor = _calculateDomeColor(danger, suspicious, safe);

      setState(() {
        _circles.add(Circle(
          circleId: CircleId('$location'),
          center: LatLng(
            double.parse(location.split(",")[0]),
            double.parse(location.split(',')[1]),
          ),
          radius: (danger + suspicious + safe) * 4.0,
          fillColor: domeColor.withOpacity(0.5),
          strokeWidth: 2,
          strokeColor: domeColor,
        ));
      });
    });
  }

  Color _calculateDomeColor(
      int dangerCount, int suspiciousCount, int safeCount) {
    // Calculate intensity for each category
    int dangerIntensity = (dangerCount * 50).clamp(0, 255);
    int suspiciousIntensity = (suspiciousCount * 50).clamp(0, 255);
    int safeIntensity = (safeCount * 50).clamp(0, 255);

    if (dangerCount >= suspiciousCount && dangerCount >= safeCount) {
      return Color.fromARGB(255, dangerIntensity, 0, 0); // Red color for danger
    } else if (suspiciousCount >= dangerCount && suspiciousCount >= safeCount) {
      return Color.fromARGB(255, suspiciousIntensity, suspiciousIntensity,
          0); // Yellow color for suspicious
    } else {
      return Color.fromARGB(255, 0, safeIntensity, 0); // Green color for safe
    }
  }

  void _renderDomeOnMap() {
    setState(() {
      _circles.clear();
    });

    //   Update the risk zone

    _updateDomeRiskZone(feedbackList);
  }

  @override
  void dispose() {
    feedbackApi.closeWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,

        mapType: _currentMapType,
        onTap: _onMapTap,
        markers: Set<Marker>.of(_markers), // Pass updated markers
        circles: Set<Circle>.of(_circles),
      ),
    );
  }
}
