import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mega_project/Inputs.dart';

void main() {
  runApp(MaterialApp(
    home: MedicalMap(),
  ));
}

class MedicalMap extends StatefulWidget {
  const MedicalMap({super.key});

  @override
  State<MedicalMap> createState() => _MedicalMapState();
}

class _MedicalMapState extends State<MedicalMap> {
  var start = TextEditingController();
  var end = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Medical Map",
          style: TextStyle(
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 1,
              fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 20,
            ),
            InputWidget(controller: start, hint: "Enter starting point"),
            SizedBox(
              height: 15,
            ),
            InputWidget(controller: end, hint: "Enter ending point"),
            SizedBox(
              height: 15,
            ),
            ElevatedButton(
              onPressed: () async {
                if (start.text.isEmpty || end.text.isEmpty) {
                  // Show a message if either field is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter both start and end locations')),
                  );
                  return;
                }

                try {
                  List<Location> startLocation = await locationFromAddress("1600 Amphitheatre Parkway, Mountain View, CA");
                  List<Location> endLocation = await locationFromAddress("1 Infinite Loop, Cupertino, CA");

                  if (startLocation.isNotEmpty && endLocation.isNotEmpty) {
                    print(startLocation);
                    print(endLocation);
                  } else {
                    // Show a message if location not found
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not find location for one of the addresses')),
                    );
                  }
                } catch (e) {
                  // Handle errors such as invalid addresses
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error finding locations: $e')),
                  );
                }
              },
              child: Text('Press'),
            ),
          ],
        ),
      ),
    );
  }
}
