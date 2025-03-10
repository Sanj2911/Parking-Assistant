import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationHistoryScreen extends StatefulWidget {
  @override
  _ReservationHistoryScreenState createState() =>
      _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot>? _reservationStream;

  @override
  void initState() {
    super.initState();
    _fetchUserReservations();
  }

  // Fetch reservations for the logged-in user
  void _fetchUserReservations() {
    if (_user != null) {
      _reservationStream = _firestore
          .collection('reservations')
          .where('userId', isEqualTo: _user!.uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservation History'),
      ),
      body: _user == null
          ? Center(child: Text('Please log in to view reservations.'))
          : StreamBuilder<QuerySnapshot>(
              stream: _reservationStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error fetching reservations.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No reservations found.'));
                }

                // Display the reservations in a ListView
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final reservation = snapshot.data!.docs[index];
                    final spotNumber = reservation['spotNumber'];
                    final duration = reservation['duration'];
                    final startTime =
                        (reservation['startTime'] as Timestamp).toDate();
                    final endTime =
                        (reservation['endTime'] as Timestamp).toDate();

                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.directions_car),
                        title: Text('Spot Number: $spotNumber'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Duration: $duration hours'),
                            Text('Start Time: ${_formatDateTime(startTime)}'),
                            Text('End Time: ${_formatDateTime(endTime)}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // Format DateTime to a readable string
  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }
}
