import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.color_lens),
              title: Text('Change Theme'),
              onTap: () {
                // Implement theme change logic
              },
            ),
            ListTile(
              leading: Icon(Icons.language),
              title: Text('Change Language'),
              onTap: () {
                // Implement language change logic
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                // Implement logout logic
              },
            ),
          ],
        ),
      ),
    );
  }
}
