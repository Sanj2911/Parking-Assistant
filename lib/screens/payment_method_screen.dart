import 'package:flutter/material.dart';

class PaymentMethod extends StatefulWidget {
  final int spotNumber; // Add this line

  const PaymentMethod({Key? key, required this.spotNumber}) : super(key: key); // Modify this line

  @override
  State<PaymentMethod> createState() => _PaymentMethodState();
}

class _PaymentMethodState extends State<PaymentMethod> {
  bool _saveCardDetails = false;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Visa/Master",
          style: TextStyle(color: Colors.white),
        ),
        leading: BackButton(color: Colors.white),
        backgroundColor: Colors.purple,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paying for Spot Number: ${widget.spotNumber}', // Display spot number
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildTextField("Card Number", TextInputType.number),
            Row(
              children: [
                Expanded(child: _buildTextField("Expiry", TextInputType.datetime)),
                SizedBox(width: 16),
                Expanded(child: _buildTextField("CVC", TextInputType.number, obscureText: true)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 10),
                Image.asset('assets/payCard.png', height: 40),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Approved by the Central Bank of Sri Lanka",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _saveCardDetails,
                  onChanged: (bool? value) {
                    setState(() {
                      _saveCardDetails = value!;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    "Save my card details for faster payments.\nI agree to Terms and Conditions",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            Spacer(),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Handle payment submission
              },
              child: Text('CONTINUE'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(size.width, 50),
                backgroundColor: Colors.grey,
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextInputType keyboardType, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          suffixIcon: obscureText ? Icon(Icons.visibility_off) : null,
        ),
      ),
    );
  }
}
