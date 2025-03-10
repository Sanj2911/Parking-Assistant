import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park/screens/user_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register.dart';
import 'package:email_validator/email_validator.dart';

class MyLogin extends StatefulWidget {
  const MyLogin({Key? key}) : super(key: key);

  @override
  _MyLoginState createState() => _MyLoginState();
}

class _MyLoginState extends State<MyLogin> {
  bool isChecked = false;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('email') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      isChecked =
          emailController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  void _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (isChecked) {
      await prefs.setString('email', emailController.text);
      await prefs.setString('password', passwordController.text);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  bool _validateInputs() {
    final email = emailController.text;
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill in both email and password.');
      return false;
    }

    if (!EmailValidator.validate(email)) {
      _showErrorDialog('Please enter a valid email address.');
      return false;
    }

    if (password.length < 6) { // Minimum password length
      _showErrorDialog('Password should be at least 6 characters long.');
      return false;
    }

    return true;
  }

void _login() async {
  if (!_validateInputs()) return;

  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );

    // Save credentials if "Remember Me" is checked
    _saveCredentials();

    // Navigate to UserDashboard on successful login
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => UserDashboard()));
  } on FirebaseAuthException catch (e) {
    String errorMessage = '';

    print('Firebase Auth Exception: ${e.code}'); // Debugging line

    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'Email not registered. Please sign up first.';
        break;
      case 'wrong-password':
        errorMessage = 'Check credentials. Please ensure your email and password are correct.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is badly formatted.';
        break;
      default:
        errorMessage = 'An unexpected error occurred. Please try again.';
        break;
    }

    // Show error dialog
    _showErrorDialog(errorMessage);
  } catch (e) {
    print('Unexpected Exception: $e'); // Debugging line
    // Catch any other unexpected exceptions
    _showErrorDialog('An unexpected error occurred. Please try again.');
  }
}

  void _forgotPassword() async {
    final email = emailController.text;
    if (email.isEmpty) {
      // Show error if no email is provided
      _showErrorDialog('Please enter your email address.');
      return;
    }

    if (!EmailValidator.validate(email)) {
      _showErrorDialog('Please enter a valid email address.');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Password Reset'),
          content: Text('Password reset email sent. Check your inbox.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Handle errors related to password reset
      String errorMessage = e.message ?? 'An unexpected error occurred.';
      _showErrorDialog(errorMessage);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
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
                'Welcome\nBack',
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
                  _buildTextField('Email', emailController, false),
                  SizedBox(height: 30),
                  _buildTextField('Password', passwordController, true),
                  SizedBox(height: 40),
                  _buildRememberMeCheckbox(),
                  _buildSignInButton(),
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

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Text('Remember Me', style: TextStyle(color: Colors.black)),
        Checkbox(
          value: isChecked,
          onChanged: (value) {
            setState(() {
              isChecked = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Sign in',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
        ),
        CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xff4c505b),
          child: IconButton(
            color: Colors.white,
            onPressed: _login,
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyRegister()),
            );
          },
          child: Text(
            'Sign Up',
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: Color(0xff4c505b),
              fontSize: 18,
            ),
          ),
        ),
        TextButton(
          onPressed: _forgotPassword,
          child: Text(
            'Forgot Password',
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
