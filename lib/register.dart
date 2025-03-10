import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park/login.dart';

class MyRegister extends StatefulWidget {
  const MyRegister({Key? key}) : super(key: key);

  @override
  _MyRegisterState createState() => _MyRegisterState();
}

class _MyRegisterState extends State<MyRegister> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _register() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Save the user's name and email to Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'name': nameController.text,
        'email': emailController.text,
        // Add any additional fields you want to save here
      });

      print("User registered: ${userCredential.user?.uid}");
      
      // Navigate to the login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyLogin()),
      );
    } catch (e) {
      print("Registration error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/login.png'), fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 35, top: 130),
              child: Text(
                'Create\nAccount',
                style: TextStyle(color: Colors.white, fontSize: 33),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.5,
                left: 35,
                right: 35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField('Name', nameController, false),
                  SizedBox(height: 30),
                  _buildTextField('Email', emailController, false),
                  SizedBox(height: 30),
                  _buildTextField('Password', passwordController, true),
                  SizedBox(height: 40),
                  _buildSignUpButton(),
                  SizedBox(height: 40),
                  _buildFooterButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String hint, TextEditingController controller, bool obscureText) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.black),
      obscureText: obscureText,
      decoration: InputDecoration(
        fillColor: Colors.grey.shade100,
        filled: true,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Sign Up',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
        ),
        CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xff4c505b),
          child: IconButton(
            color: Colors.white,
            onPressed: _register,
            icon: Icon(Icons.arrow_forward),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: Color(0xff4c505b),
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Text('Login Screen'),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Text('Welcome to the Home Screen!'),
      ),
    );
  }
}
