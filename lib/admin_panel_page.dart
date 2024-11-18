import 'package:flutter/material.dart';
import 'enter_description_page.dart';
import 'manage_items.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    const Color customGold = Color(0xFFFFD700); 

    void navigateToEnterDescription(BuildContext context, bool isVideo, {bool isEvent = false}) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EnterDescriptionPage(isVideo: isVideo, isEvent: isEvent)),
      );
    }

    void navigateToManageItems(BuildContext context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ManageItemsPage()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.green, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => navigateToEnterDescription(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, 
              ),
              child: const Text(
                'Upload Devotionals',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => navigateToEnterDescription(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: customGold, 
              ),
              child: const Text(
                'Upload Sermons/Videos',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => navigateToEnterDescription(context, false, isEvent: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, 
              ),
              child: const Text(
                'Upload Upcoming Events',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => navigateToManageItems(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: customGold, 
              ),
              child: const Text(
                'Manage Items',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
