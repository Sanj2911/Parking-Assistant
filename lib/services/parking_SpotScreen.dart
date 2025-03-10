import 'package:firebase_database/firebase_database.dart';

class ParkingSpotService {
  final DatabaseReference _sensorRef =
      FirebaseDatabase.instance.ref().child('Sensor');

  Stream<int> getSensorDataStream() {
    return _sensorRef.child('ultrasonic_distance').onValue.map((event) {
      final dataSnapshot = event.snapshot;
      return (dataSnapshot.value as int?) ?? 0;
    });
  }
}
