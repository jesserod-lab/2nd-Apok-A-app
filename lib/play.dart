import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PlayPage extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String videoDate;

  const PlayPage({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    required this.videoDate,
  });

  @override
  PlayPageState createState() => PlayPageState();
}

class PlayPageState extends State<PlayPage> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  final Logger logger = Logger();
  List<Map<String, dynamic>> _videos = [];
  late String _currentVideoUrl;
  late String _currentVideoTitle;

  String? _currentVideoDocId;
  bool _isBuffering = true;
  bool _showControls = false;
  int _currentVideoLikes = 0;
  bool _liked = false;
  bool _saved = false;
  int _currentVideoViews = 0;
  late String _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentVideoUrl = widget.videoUrl;
    _currentVideoTitle = widget.videoTitle;

    _initializeUserId(); // Initialize user ID

    _controller = VideoPlayerController.networkUrl(Uri.parse(_currentVideoUrl))
      ..addListener(() {
        if (_controller.value.isInitialized && !_controller.value.isBuffering && _isBuffering) {
          setState(() {
            _isBuffering = false;
          });
        }
      });

    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
      _incrementViewCount(); 
    });

    _loadCurrentVideoData(); 
    _loadVideos();
    _checkIfVideoIsSaved();
  }

  Future<void> _initializeUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('user_id');
    if (storedUserId == null) {
      storedUserId = const Uuid().v4();
      await prefs.setString('user_id', storedUserId);
    }
    setState(() {
      _userId = storedUserId!;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.landscape) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    setState(() {});
  }

  Future<void> _loadVideos() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('uploads').get();
      List<Map<String, dynamic>> fetchedVideos = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'url': doc['contentUrl'],
          'thumbnail': doc['thumbnailUrl'],
          'title': doc['description'],
          'date': DateTime.now().toString(),
          'likes': doc['likes'],
          'views': doc['views'], 
        };
      }).toList();

      setState(() {
        _videos = fetchedVideos;
      });
    } catch (e) {
      logger.e('Error loading videos: $e');
    }
  }

  Future<void> _loadCurrentVideoData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('uploads')
          .where('contentUrl', isEqualTo: _currentVideoUrl)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        _currentVideoDocId = doc.id;
        setState(() {
          _currentVideoLikes = doc['likes'];
          _liked = (doc['likedBy'] as List).contains(_userId); 
          _currentVideoViews = doc['views'];
        });
      }
    } catch (e) {
      logger.e('Error loading video data: $e');
    }
  }

  Future<void> _incrementViewCount() async {
    try {
      if (_currentVideoDocId == null) return;
      DocumentReference docRef = FirebaseFirestore.instance.collection('uploads').doc(_currentVideoDocId);
      DocumentSnapshot doc = await docRef.get();

      if (!doc.exists) {
        logger.e('Document does not exist');
        return;
      }

      List viewedBy = doc['viewedBy'] ?? [];
      if (!viewedBy.contains(_userId)) {
        int views = doc['views'];
        views++;
        viewedBy.add(_userId);

        await docRef.update({'views': views, 'viewedBy': viewedBy});

        setState(() {
          _currentVideoViews = views;
        });
      }
    } catch (e) {
      logger.e('Error incrementing view count: $e');
    }
  }

  void _playVideo(String id, String url, String title, String date) {
    setState(() {
      _currentVideoDocId = id;
      _currentVideoUrl = url;
      _currentVideoTitle = title;

      _isBuffering = true;
      _controller = VideoPlayerController.networkUrl(Uri.parse(_currentVideoUrl))
        ..addListener(() {
          if (_controller.value.isInitialized && !_controller.value.isBuffering && _isBuffering) {
            setState(() {
              _isBuffering = false;
            });
          }
        });
      _initializeVideoPlayerFuture = _controller.initialize().then((_) {
        setState(() {});
        _controller.play();
        _incrementViewCount(); 
      });

      _loadCurrentVideoData(); 
      _checkIfVideoIsSaved();
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
        _showControls = false; 
      }
    });
  }

  void _setPlaybackSpeed(double speed) {
    _controller.setPlaybackSpeed(speed);
  }

  Future<void> _toggleLike() async {
    try {
      if (_currentVideoDocId == null) return;

      DocumentReference docRef = FirebaseFirestore.instance.collection('uploads').doc(_currentVideoDocId);
      DocumentSnapshot doc = await docRef.get();

      if (!doc.exists) {
        logger.e('Document does not exist');
        return;
      }

      List likedBy = doc['likedBy'];
      int likes = doc['likes'];

      if (_liked) {
        likedBy.remove(_userId); 
        likes--;
      } else {
        likedBy.add(_userId); 
        likes++;
      }

      await docRef.update({'likedBy': likedBy, 'likes': likes});

      setState(() {
        _liked = !_liked;
        _currentVideoLikes = likes;
      });
    } catch (e) {
      logger.e('Error toggling like: $e');
    }
  }

  Future<void> _toggleSave() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedVideos = prefs.getStringList('savedVideos') ?? [];

    if (_saved) {
      savedVideos.remove(_currentVideoUrl);
    } else {
      savedVideos.add(_currentVideoUrl);
    }

    await prefs.setStringList('savedVideos', savedVideos);

    setState(() {
      _saved = !_saved;
    });
  }

  Future<void> _checkIfVideoIsSaved() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedVideos = prefs.getStringList('savedVideos') ?? [];

    setState(() {
      _saved = savedVideos.contains(_currentVideoUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    bool isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      appBar: isLandscape ? null : AppBar(
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Apokalupsis',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white, 
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _showControls = !_showControls;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                        if (_isBuffering)
                          Container(
                            color: Colors.black54,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        if (_showControls)
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              color: Colors.transparent,
                              child: Center(
                                child: Icon(
                                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                        if (_showControls && !_controller.value.isPlaying)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: PopupMenuButton<double>(
                              icon: Icon(Icons.settings, color: Colors.white.withOpacity(0.7)),
                              onSelected: (value) {
                                _setPlaybackSpeed(value);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 0.5,
                                  child: Text('0.5x'),
                                ),
                                const PopupMenuItem(
                                  value: 1.0,
                                  child: Text('1.0x'),
                                ),
                                const PopupMenuItem(
                                  value: 1.5,
                                  child: Text('1.5x'),
                                ),
                                const PopupMenuItem(
                                  value: 2.0,
                                  child: Text('2.0x'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    color: Colors.black54,
                    height: 200,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            ),
            if (!isLandscape) ...[
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentVideoTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(_liked ? Icons.thumb_up : Icons.thumb_up_off_alt),
                          onPressed: _toggleLike,
                        ),
                        Text('$_currentVideoLikes likes'),
                        IconButton(
                          icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
                          onPressed: _toggleSave,
                        ),
                      ],
                    ),
                    Text('$_currentVideoViews views'), 
                  ],
                ),
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _videos.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 100,
                          height: 56,
                          color: Colors.black26,
                          child: Image.network(_videos[index]['thumbnail']!, fit: BoxFit.cover),
                        ),
                        title: Text(_videos[index]['title']!),
                        onTap: () => _playVideo(
                          _videos[index]['id']!,
                          _videos[index]['url']!,
                          _videos[index]['title']!,
                          _videos[index]['date']!,
                        ),
                      ),
                      const SizedBox(height: 12), 
                    ],
                  );
                },
              ),
            ],
            if (isLandscape) ...[
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
