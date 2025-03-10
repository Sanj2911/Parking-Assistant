import 'package:flutter/material.dart';
import 'package:park/screens/hanlde_user.dart';
import 'package:park/screens/parking_spot_management.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Manage Parking Spots'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ParkingManagementScreen()),
              ); // Navigate to manage parking spots screen
            },
          ),
         
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Handle User Accounts'),
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserListView()),
              );

            },
          ),
        ],
      ),
    );
  }
}
