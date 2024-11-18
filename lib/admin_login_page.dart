// admin_login_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_panel_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});  

  @override
  AdminLoginPageState createState() => AdminLoginPageState();  
}

class AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _passcodeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _errorMessage = '';

  Future<void> _login() async {
    String enteredPasscode = _passcodeController.text;

    
    DocumentSnapshot snapshot =
        await _firestore.collection('admin').doc('passcode').get();

    if (snapshot.exists) {
      String storedPasscode = snapshot['passcode'];

      if (enteredPasscode == storedPasscode) {
        if (!mounted) return;  
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminPanelPage()),  
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid Passcode!';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Passcode not found in database!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'), 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _passcodeController,
              decoration: InputDecoration(
                labelText: 'Enter Admin Passcode',
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),  
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),  
            ),
          ],
        ),
      ),
    );
  }
}
