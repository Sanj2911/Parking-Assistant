import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:park/login.dart';
import 'package:park/screens/user_dashboard.dart';
import 'package:park/main.dart';
import 'package:park/screens/reservation_history.dart';

class CustomNavigationDrawer extends StatefulWidget {
  final User? user;

  const CustomNavigationDrawer({Key? key, required this.user})
      : super(key: key);

  @override
  _CustomNavigationDrawerState createState() => _CustomNavigationDrawerState();
}

class _CustomNavigationDrawerState extends State<CustomNavigationDrawer> {
  String _displayName = 'No name found';
  String _email = 'No email found';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (widget.user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _displayName = data?['name'] ?? 'No name found';
          _email = widget.user!.email ?? 'No email found';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(_displayName),
            accountEmail: Text(_email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _displayName.isNotEmpty ? _displayName[0] : 'JD',
                style: TextStyle(fontSize: 24.0),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserDashboard()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Reservation History'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ReservationHistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MainDashboard()),
                  (Route<dynamic> route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
