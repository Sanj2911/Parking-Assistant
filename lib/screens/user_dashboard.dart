import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/custom_navigation_drawer.dart';
import 'payment_method_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int? selectedSpot; // Holds the currently selected spot
  int totalSpots = 0; // Total number of parking spots initialized to 0
  int availableSpots = 0; // Available spots, initialized to 0
  List<bool> spotsOccupied = []; // Track occupancy status
  List<bool> spotsReserved = []; // Track reservation status

  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('ParkingSpot');
  final User? _user = FirebaseAuth.instance.currentUser; // Get the current user
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

  @override
  void initState() {
    super.initState();
    // Initialize availableSpots based on the initial data from Firebase
    _fetchTotalSpots();
  }

  // Fetch the total number of spots from Firebase Realtime Database
  void _fetchTotalSpots() async {
    _databaseReference.get().then((snapshot) {
      if (snapshot.exists) {
        // Get the number of spots by counting the children under "ParkingSpot"
        int count = snapshot.children.length;

        setState(() {
          totalSpots = count;
          availableSpots = totalSpots;
          spotsOccupied = List.filled(totalSpots, false);
          spotsReserved = List.filled(totalSpots, false);
        });

        // After setting totalSpots, fetch the initial data and set listeners
        _fetchInitialData();
        _listenForUpdates();
        _checkReservationTimes();
      }
    });
  }

  // Fetch initial data for all spots
  void _fetchInitialData() async {
    // Fetch data from Firebase Realtime Database
    for (int i = 0; i < totalSpots; i++) {
      _databaseReference.child('spot_${i + 1}').get().then((snapshot) {
        final data = snapshot.value as Map<dynamic, dynamic>?;

        final bool occupied = data?['occupied'] as bool? ?? false;

        setState(() {
          spotsOccupied[i] = occupied;
        });
      });
    }

    // Fetch reserved spots from Firestore
    QuerySnapshot snapshot = await _firestore.collection('reservations').get();

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      int spotNumber = data['spotNumber'] ?? 0;
      DateTime endTime = (data['endTime'] as Timestamp).toDate();

      // If the reservation end time is still in the future, mark it as reserved
      if (endTime.isAfter(DateTime.now())) {
        setState(() {
          spotsReserved[spotNumber - 1] = true;
        });
      }
    }

    _updateAvailableSpots();
  }

  // Listen for real-time updates for all spots
  void _listenForUpdates() {
    for (int i = 0; i < totalSpots; i++) {
      _databaseReference.child('spot_${i + 1}').onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        final bool occupied = data?['occupied'] as bool? ?? false;

        setState(() {
          spotsOccupied[i] = occupied;
          _updateAvailableSpots();
        });
      });
    }
  }

  // Update the count of available spots
  void _updateAvailableSpots() {
    setState(() {
      availableSpots = spotsOccupied
          .asMap()
          .entries
          .where((entry) => !entry.value && !spotsReserved[entry.key])
          .length;
    });
  }

  // Periodically check reservation times to release spots
  void _checkReservationTimes() async {
    QuerySnapshot snapshot = await _firestore.collection('reservations').get();

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      int spotNumber = data['spotNumber'] ?? 0;
      DateTime endTime = (data['endTime'] as Timestamp).toDate();

      // If the current time is after the end time, release the spot
      if (endTime.isBefore(DateTime.now())) {
        await _firestore.collection('reservations').doc(doc.id).delete();
        setState(() {
          spotsReserved[spotNumber - 1] = false;
        });
        _updateAvailableSpots();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Dashboard'),
      ),
      drawer: CustomNavigationDrawer(user: _user!),
      body: totalSpots == 0
          ? Center(
              child:
                  CircularProgressIndicator()) // Loading indicator while fetching totalSpots
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildSectionTitle(
                        context, 'Real-time Parking Availability'),
                    _buildParkingAvailabilitySection(context),
                    SizedBox(height: 20),
                    _buildSectionTitle(context, 'Reserve a Spot'),
                    _buildReservationSection(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;
    final headlineSmall = textTheme.headlineSmall;

    return Text(
      title,
      style: headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ) ??
          TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            fontSize: 18,
          ),
    );
  }

  Widget _buildParkingAvailabilitySection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              'Available Spots: $availableSpots',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 1.5,
              children: List.generate(totalSpots, (index) {
                bool isSelected = selectedSpot == index + 1;
                bool isOccupied = spotsOccupied[index];
                bool isReserved = spotsReserved[index];
                Color spotColor;
                String spotText;

                if (isOccupied || isReserved) {
                  spotColor = Colors.red; // Occupied and Reserved spots color
                  spotText = isOccupied ? 'Occupied' : 'Reserved';
                } else if (isSelected) {
                  spotColor = Colors.blue; // Selected spot color
                  spotText = 'Selected';
                } else {
                  spotColor = Colors.green; // Available spot color
                  spotText = '${index + 1}';
                }

                return GestureDetector(
                  onTap: (isOccupied || isReserved)
                      ? null
                      : () {
                          setState(() {
                            // Toggle selection: If already selected, unselect it; otherwise, select it
                            selectedSpot =
                                selectedSpot == index + 1 ? null : index + 1;
                          });
                        },
                  child: Card(
                    color: spotColor, // Use the determined color
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        spotText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationSection(BuildContext context) {
    void reserveSpot() {
      if (selectedSpot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a spot number')),
        );
        return;
      }

      _showReservationBottomSheet(context);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              'Reserve a Parking Spot',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: reserveSpot,
              child: Text('Reserve'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReservationBottomSheet(BuildContext context) {
    String? selectedTime; // Holds the selected reserve time

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Reserve Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                hint: Text("Select Time"),
                value: selectedTime,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedTime = newValue;
                  });
                },
                items: <String>['30 Minutes', '1 Hour', '2 Hours']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (selectedTime != null) {
                    DateTime startTime = DateTime.now();
                    DateTime endTime = startTime.add(
                      selectedTime == '30 Minutes'
                          ? Duration(minutes: 30)
                          : selectedTime == '1 Hour'
                              ? Duration(hours: 1)
                              : Duration(hours: 2),
                    );

                    // Save to Firestore with selected reservation time and end time
                    _firestore.collection('reservations').add({
                      'userId': _user?.uid,
                      'spotNumber': selectedSpot,
                      'startTime': Timestamp.fromDate(startTime),
                      'duration': selectedTime,
                      'endTime': Timestamp.fromDate(endTime), // Store end time
                    }).then((_) {
                      Navigator.pop(context); // Close the bottom sheet
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Spot reserved for $selectedTime')),
                      );
                      setState(() {
                        spotsReserved[selectedSpot! - 1] =
                            true; // Mark spot as reserved
                        selectedSpot = null; // Clear selected spot
                      });
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Failed to reserve spot: $error')),
                      );
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Please select a reservation time')),
                    );
                  }
                },
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Blue colored button
                  minimumSize: Size(double.infinity, 36),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
