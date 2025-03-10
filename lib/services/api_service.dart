import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParkingService {
  final CollectionReference parkingCollection = FirebaseFirestore.instance.collection('parking_spots');

  Future<void> reserveSpot(String spotId) async {
    await parkingCollection.doc(spotId).update({
      'status': 'reserved',
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  // Add more methods as needed
}
