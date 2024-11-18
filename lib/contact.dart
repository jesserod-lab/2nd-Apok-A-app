import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        backgroundColor: Colors.green,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Contact Us",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 20),
            Text(
              "Phone: +256 761 046 578 / +256701862042   ",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "Email: apokalupsistlegi@gmail.com.com",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "Masazi Complex, Opposite Nob View Ntinda",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              "Feel free to reach out to us with any questions or concerns. We're here to help!",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
