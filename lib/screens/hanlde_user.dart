import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Handle errors
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Check if data is null or empty
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No users found.'));
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userName = user['name'] ?? 'No Name';
            final userEmail = user['email'] ?? 'No Email';

            return ListTile(
              title: Text(userName),
              subtitle: Text(userEmail),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  // Add delete functionality here
                },
              ),
            );
          },
        );
      },
    );
  }
}
