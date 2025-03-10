import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_method_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

class ReservationForm extends StatefulWidget {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('ParkingSpot');
  final User? _user = FirebaseAuth.instance.currentUser;

  final int spotNumber;

  ReservationForm({required this.spotNumber});

  @override
  _ReservationFormState createState() => _ReservationFormState();
}

class _ReservationFormState extends State<ReservationForm> {
  final _formKey = GlobalKey<FormState>();
  String contactNumber = '';
  String startTime = '';

  // Method to check if the spot is available at the given time
  Future<bool> isSpotAvailable(int spotNumber, String startTime) async {
    String reservationDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final querySnapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('spotNumber', isEqualTo: spotNumber)
        .where('reservationDate', isEqualTo: reservationDate)
        .where('startTime', isEqualTo: startTime)
        .get();

    return querySnapshot.docs.isEmpty; // Returns true if no reservation exists
  }

  // Method to save reservation details to Firestore
  void saveReservation() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Check if the spot is available at the given time
      bool available = await isSpotAvailable(widget.spotNumber, startTime);

      if (available) {
        // Get the current date and user ID
        String reservationDate =
            DateFormat('yyyy-MM-dd').format(DateTime.now());
        String? userId = FirebaseAuth.instance.currentUser?.uid;

        Reservation reservation = Reservation(
          contactNumber: contactNumber,
          spotNumber: widget.spotNumber,
          reservationDate: reservationDate,
          startTime: startTime,
          userId: userId,
        );

        // Save to Firestore
        FirebaseFirestore.instance
            .collection('reservations')
            .add(reservation.toMap())
            .then((_) {
          // Navigate to the payment screen after saving
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentMethod(
                spotNumber: widget.spotNumber,
              ),
            ),
          );
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save reservation: $error')),
          );
        });
      } else {
        // Show a message if the spot is already reserved
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('This spot is already reserved at $startTime')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservation Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'Enter your contact number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your contact number';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
                onSaved: (value) {
                  contactNumber = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Start Time',
                  hintText: 'HH:MM',
                  prefixIcon: Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the start time';
                  }
                  if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
                    return 'Please enter a valid time (HH:MM)';
                  }
                  return null;
                },
                onSaved: (value) {
                  startTime = value!;
                },
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      startTime = pickedTime.format(context);
                    });
                  }
                },
                readOnly: true,
                controller: TextEditingController(text: startTime),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveReservation,
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Reservation {
  String contactNumber;
  int spotNumber;
  String reservationDate;
  String startTime;
  String? userId;

  Reservation({
    required this.contactNumber,
    required this.spotNumber,
    required this.reservationDate,
    required this.startTime,
    required this.userId,
  });

  // Method to convert the Reservation object to a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'contactNumber': contactNumber,
      'spotNumber': spotNumber,
      'reservationDate': reservationDate,
      'startTime': startTime,
      'userId': userId,
    };
  }
}
