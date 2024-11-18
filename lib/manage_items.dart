import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ManageItemsPage extends StatefulWidget {
  const ManageItemsPage({super.key});

  @override
  ManageItemsPageState createState() => ManageItemsPageState();
}

class ManageItemsPageState extends State<ManageItemsPage> {
  final List<Map<String, dynamic>> _items = [];
  final Set<String> _selectedItems = <String>{};
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    List<Map<String, dynamic>> items = [];

    
    QuerySnapshot devotionalsSnapshot = await FirebaseFirestore.instance.collection('devotionals').get();
    items.addAll(devotionalsSnapshot.docs.map((doc) => {
          'id': doc.id,
          'type': 'devotional',
          'thumbnailUrl': doc['thumbnailUrl'],
          'contentUrl': doc['contentUrl'],
          'description': doc['description']
        }));

    
    QuerySnapshot uploadsSnapshot = await FirebaseFirestore.instance.collection('uploads').get();
    items.addAll(uploadsSnapshot.docs.map((doc) => {
          'id': doc.id,
          'type': 'upload',
          'thumbnailUrl': doc['thumbnailUrl'],
          'contentUrl': doc['contentUrl'],
          'description': doc['description']
        }));

    
    QuerySnapshot eventsSnapshot = await FirebaseFirestore.instance.collection('upcoming_events').get();
    items.addAll(eventsSnapshot.docs.map((doc) => {
          'id': doc.id,
          'type': 'event',
          'thumbnailUrl': doc['thumbnailUrl'],
          'contentUrl': doc['contentUrl'],
          'description': doc['description']
        }));

    if (mounted) {
      setState(() {
        _items.addAll(items);
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
      } else {
        _selectedItems.add(id);
      }
    });
  }

  Future<void> _deleteSelectedItems() async {
    setState(() {
      _isDeleting = true;
    });

    for (String id in _selectedItems) {
      Map<String, dynamic> item = _items.firstWhere((item) => item['id'] == id);
      String collection = item['type'] == 'devotional'
          ? 'devotionals'
          : item['type'] == 'upload'
              ? 'uploads'
              : 'upcoming_events';

      try {
        
        await FirebaseFirestore.instance.collection(collection).doc(id).delete();

        
        await FirebaseStorage.instance.refFromURL(item['thumbnailUrl']).delete();
        await FirebaseStorage.instance.refFromURL(item['contentUrl']).delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $e')),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _items.removeWhere((item) => _selectedItems.contains(item['id']));
        _selectedItems.clear();
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Items deleted successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Items'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        leading: Checkbox(
                          value: _selectedItems.contains(item['id']),
                          onChanged: (bool? value) {
                            _toggleSelection(item['id']);
                          },
                        ),
                        title: Row(
                          children: [
                            Image.network(
                              item['thumbnailUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item['description'])),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                _selectedItems.add(item['id']);
                                await _deleteSelectedItems();
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectedItems.isEmpty || _isDeleting ? null : _deleteSelectedItems,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                        )
                      : const Text('Delete Selected Items'),
                ),
              ],
            ),
    );
  }
}
