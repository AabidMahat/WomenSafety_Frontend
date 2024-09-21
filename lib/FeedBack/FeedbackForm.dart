import 'dart:ui'; // For BackdropFilter
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mega_project/api/FeedbackApi.dart';

class FeedbackForm extends StatefulWidget {
  final LatLng position;
  FeedbackForm({required this.position});

  @override
  _FeedbackFormState createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  FeedbackApi feedbackApi = FeedbackApi();
  String? category;
  TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), // Translucent white
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glass effect
          child: Card(
            color: Colors.white.withOpacity(0.9), // Semi-translucent card background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 10,
            shadowColor: Colors.black.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Header
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.deepPurple, size: 28),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Provide Feedback for Location",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Feedback Type Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Feedback Type",
                      labelStyle: TextStyle(
                        color: Colors.deepPurple.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.3),
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurple.shade700),
                    items: ["Dangerous", "Suspicious", "Safe"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        category = newValue;
                      });
                    },
                  ),
                  SizedBox(height: 24),

                  // Comments Field
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: "Additional Comments",
                      labelStyle: TextStyle(
                        color: Colors.deepPurple.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.3),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 24),

                  // Submit Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade600,
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 10,
                        shadowColor: Colors.deepPurpleAccent.withOpacity(0.4),
                      ),
                      onPressed: () {
                        feedbackApi.createFeedback(widget.position, commentController.text, category!);
                      },
                      icon: Icon(Icons.send, color: Colors.white),
                      label: Text(
                        "Submit Feedback",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
