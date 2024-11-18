import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_view/photo_view.dart'; // 

class DisplayDevotionalsPage extends StatefulWidget {
  final String description;
  final String thumbnailUrl;
  final String contentUrl;

  const DisplayDevotionalsPage({
    super.key,
    required this.description,
    required this.thumbnailUrl,
    required this.contentUrl,
  });

  @override
  DisplayDevotionalsPageState createState() => DisplayDevotionalsPageState();
}

class DisplayDevotionalsPageState extends State<DisplayDevotionalsPage>
    with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  String? devotionalImageUrl;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isImageLoaded = false;
  int _currentDevotionalLikes = 0;
  bool _liked = false;
  bool _saved = false;
  String? _currentDevotionalDocId;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _loadCurrentDevotionalLikes();
    _checkIfSaved();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDevotionalImage();
  }

  Future<void> _loadDevotionalImage() async {
    try {
      setState(() {
        devotionalImageUrl = widget.contentUrl;
      });
      await precacheImage(NetworkImage(widget.contentUrl), context);
      setState(() {
        _isImageLoaded = true;
      });
      _controller.forward();
      logger.d('Devotional image URL: $devotionalImageUrl');
    } catch (e) {
      logger.e('Error loading devotional image: $e');
    }
  }

  Future<void> _loadCurrentDevotionalLikes() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('devotionals')
          .where('contentUrl', isEqualTo: widget.contentUrl)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        _currentDevotionalDocId = doc.id;
        setState(() {
          _currentDevotionalLikes = doc['likes'];
          _liked = (doc['likedBy'] as List).contains('user_id'); 
        });
      }
    } catch (e) {
      logger.e('Error loading devotional likes: $e');
    }
  }

  Future<void> _toggleLike() async {
    try {
      if (_currentDevotionalDocId == null) return;

      DocumentReference docRef = FirebaseFirestore.instance.collection('devotionals').doc(_currentDevotionalDocId);
      DocumentSnapshot doc = await docRef.get();

      List likedBy = doc['likedBy'];
      int likes = doc['likes'];

      if (_liked) {
        likedBy.remove('user_id'); 
        likes--;
      } else {
        likedBy.add('user_id'); 
        likes++;
      }

      await docRef.update({'likedBy': likedBy, 'likes': likes});

      setState(() {
        _liked = !_liked;
        _currentDevotionalLikes = likes;
      });
    } catch (e) {
      logger.e('Error toggling like: $e');
    }
  }

  Future<void> _checkIfSaved() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> favoriteDevotionals = prefs.getStringList('favoriteDevotionals') ?? [];

    setState(() {
      _saved = favoriteDevotionals.contains(widget.contentUrl);
    });
  }

  Future<void> _toggleSave() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> favoriteDevotionals = prefs.getStringList('favoriteDevotionals') ?? [];

    if (_saved) {
      favoriteDevotionals.remove(widget.contentUrl);
    } else {
      favoriteDevotionals.add(widget.contentUrl);
    }

    await prefs.setStringList('favoriteDevotionals', favoriteDevotionals);

    setState(() {
      _saved = !_saved;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    double maxHeight;
    double maxWidth = double.infinity;

    if (mediaQuery.size.width > 600) {
      
      maxHeight = mediaQuery.size.height * 4.0;
    } else {
      
      maxHeight = mediaQuery.size.height * 0.8;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Devotional Details"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isImageLoaded)
                SlideTransition(
                  position: _offsetAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight,
                      maxWidth: maxWidth,
                    ),
                    child: PhotoView(
                      imageProvider: NetworkImage(devotionalImageUrl!),
                      backgroundDecoration: BoxDecoration(
                        color: Theme.of(context).canvasColor,
                      ),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2,
                    ),
                  ),
                )
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              const SizedBox(height: 16.0),
              Text(
                widget.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_liked ? Icons.thumb_up : Icons.thumb_up_off_alt),
                    onPressed: _toggleLike,
                  ),
                  Text('$_currentDevotionalLikes likes'),
                  IconButton(
                    icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_outline),
                    onPressed: _toggleSave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
