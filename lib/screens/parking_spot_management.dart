import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_navigation_drawer.dart';

class ParkingManagementScreen extends StatefulWidget {
  @override
  _ParkingManagementScreenState createState() =>
      _ParkingManagementScreenState();
}

class _ParkingManagementScreenState extends State<ParkingManagementScreen> {
  int? selectedSpot;
  int totalSpots = 0; // Initialize to 0 and fetch from Firebase
  int availableSpots = 0;
  Map<int, bool> spotStatus = {}; // Store occupied status for each spot
  Set<int> reservedSpots = {}; // Store reserved spots fetched from Firestore

  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('ParkingSpot');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    // Fetch total spots and their availability
    _fetchParkingSpotsData();

    // Listen for changes to the occupied status of each spot
    _databaseReference.onChildChanged.listen((event) {
      _fetchParkingSpotsData();
    });

    // Fetch reserved spots from Firestore
    _fetchReservedSpots();
  }

  // Function to fetch parking spots data and update total and available spots
  void _fetchParkingSpotsData() {
    _databaseReference.once().then((snapshot) {
      if (snapshot.snapshot.exists) {
        final spotsMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
        int occupiedCount = 0;

        Map<int, bool> newSpotStatus = {}; // Temporary map to store the status

        spotsMap.forEach((key, value) {
          final spotNumber =
              int.tryParse(key.split('_')[1]) ?? 0; // Extract spot number
          bool isOccupied = value['occupied'] as bool? ?? false;

          newSpotStatus[spotNumber] = isOccupied; // Store status for each spot

          if (isOccupied) {
            occupiedCount++;
          }
        });

        setState(() {
          spotStatus = newSpotStatus; // Update spot status map
          totalSpots = spotsMap.length;
          availableSpots = totalSpots - occupiedCount;
        });
      } else {
        setState(() {
          totalSpots = 0;
          availableSpots = 0;
          spotStatus = {}; // Clear spot status map
        });
      }
    });
  }

  // Function to fetch reserved spots from Firestore
  void _fetchReservedSpots() {
    _firestore.collection('reservations').snapshots().listen((snapshot) {
      final reservedSet = <int>{};

      snapshot.docs.forEach((doc) {
        final spotNumber = doc['spotNumber'] as int?;
        if (spotNumber != null) {
          reservedSet.add(spotNumber);
        }
      });

      setState(() {
        reservedSpots = reservedSet;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parking Management'),
      ),
      drawer: CustomNavigationDrawer(user: _user!),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSectionTitle(context, 'Manage Parking Spots'),
              _buildManagementOptions(context),
              SizedBox(height: 20),
              _buildSectionTitle(context, 'Real-time Parking Availability'),
              _buildParkingAvailabilitySection(context),
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

  Widget _buildManagementOptions(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Add Parking Spot'),
              onTap: () => _showAddSpotDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Parking Spot'),
              onTap: () => _showDeleteSpotDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.visibility),
              title: Text('View Real-Time Availability'),
              onTap: () {
                // Implement viewing logic here
              },
            ),
          ],
        ),
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
                final spotNumber = index + 1;
                final isOccupied = spotStatus[spotNumber] ?? false;
                final isReserved = reservedSpots.contains(spotNumber);

                Color spotColor;
                String spotText;

                if (isReserved) {
                  spotColor = Colors.orange; // Color for reserved spots
                  spotText = 'Reserved';
                } else if (isOccupied) {
                  spotColor = Colors.red;
                  spotText = 'Occupied';
                } else {
                  spotColor = Colors.green;
                  spotText = '$spotNumber';
                }

                return GestureDetector(
                  onTap: isReserved || isOccupied
                      ? null
                      : () {
                          setState(() {
                            selectedSpot = spotNumber;
                          });
                        },
                  child: Card(
                    color: spotColor,
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

  Future<void> _showAddSpotDialog(BuildContext context) async {
    int? spotNumber;

    await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Parking Spot'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "Enter spot number"),
            onChanged: (value) {
              spotNumber = int.tryParse(value);
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                if (spotNumber != null) {
                  // Update local state
                  setState(() {
                    totalSpots++;
                    availableSpots++;
                  });

                  // Create a new spot in the Firebase Realtime Database
                  final DatabaseReference spotRef = FirebaseDatabase.instance
                      .ref()
                      .child('ParkingSpot/spot_$spotNumber');

                  spotRef.set({
                    'occupied': false,
                  }).then((_) {
                    Navigator.of(context).pop();
                  }).catchError((error) {
                    // Handle any errors here
                    print('Error adding spot: $error');
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteSpotDialog(BuildContext context) async {
    int? spotNumber;

    await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Parking Spot'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "Enter spot number"),
            onChanged: (value) {
              spotNumber = int.tryParse(value);
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                if (spotNumber != null) {
                  // Reference to the spot to be deleted
                  final DatabaseReference spotRef = FirebaseDatabase.instance
                      .ref()
                      .child('ParkingSpot/spot_$spotNumber');

                  // Delete the spot from Firebase
                  spotRef.remove().then((_) {
                    setState(() {
                      totalSpots--;
                      availableSpots--;
                    });
                    Navigator.of(context).pop();
                  }).catchError((error) {
                    // Handle any errors here
                    print('Error deleting spot: $error');
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }
}
