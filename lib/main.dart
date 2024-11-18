import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_login_page.dart';
import 'play.dart';
import 'display_devotionals.dart';
import 'display_upcoming_events.dart';
import 'video_search_delegate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

const Color neonGreen = Color.fromARGB(255, 3, 199, 78);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with TickerProviderStateMixin {
  bool _isDarkMode = true;
  late AnimationController _controller;
  late Animation<Offset> _darkModeOffsetAnimation;
  late Animation<Offset> _lightModeOffsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000), 
      vsync: this,
    );
    _setAnimations();
  }

  void _setAnimations() {
    
    _darkModeOffsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    
    _lightModeOffsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  
  void _toggleTheme() {
    setState(() {
      
      _controller.reset();
      _controller.duration = const Duration(milliseconds: 1000); 
      _isDarkMode = !_isDarkMode;
      _setAnimations();
      _controller.forward();
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Stack(
        children: [
          
          SlideTransition(
            position: _isDarkMode ? _darkModeOffsetAnimation : _lightModeOffsetAnimation,
            child: Container(
              color: Colors.black,
            ),
          ),
          
          SlideTransition(
            position: _isDarkMode ? _lightModeOffsetAnimation : _darkModeOffsetAnimation,
            child: Container(
              color: Colors.white,
            ),
          ),
          
          MainScreen(
            onToggleTheme: _toggleTheme,
            isDarkMode: _isDarkMode,
          ),
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainScreen({super.key, required this.onToggleTheme, required this.isDarkMode});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _devotionals = [];
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndLoadData();
  }

  Future<void> _initializeFirebaseAndLoadData() async {
    await Firebase.initializeApp();
    _loadVideos();
    _loadDevotionals();
    _loadEvents();
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
        };
      }).toList();
      setState(() {
        _videos = fetchedVideos;
      });
    } catch (e) {
      Logger().e('Error loading videos: $e');
    }
  }

  Future<void> _loadDevotionals() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('devotionals').get();
      List<Map<String, dynamic>> fetchedDevotionals = querySnapshot.docs.map((doc) {
        return {
          'thumbnail': doc['thumbnailUrl'],
          'description': doc['description'],
          'contentUrl': doc['contentUrl'],
        };
      }).toList();
      setState(() {
        _devotionals = fetchedDevotionals;
      });
    } catch (e) {
      Logger().e('Error loading devotionals: $e');
    }
  }

  Future<void> _loadEvents() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('upcoming_events').get();
      List<Map<String, dynamic>> fetchedEvents = querySnapshot.docs.map((doc) {
        return {
          'thumbnail': doc['thumbnailUrl'],
          'description': doc['description'],
          'contentUrl': doc['contentUrl'],
        };
      }).toList();
      setState(() {
        _events = fetchedEvents;
      });
    } catch (e) {
      Logger().e('Error loading events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      HomePage(onToggleTheme: widget.onToggleTheme, isDarkMode: widget.isDarkMode, videos: _videos, devotionals: _devotionals, events: _events),
      VideosPage(videos: _videos),
      const DevotionalsPage(),
      const EventsPage(),
    ];

    void onItemTapped(int index) {
      setState(() {
        selectedIndex = index;
      });
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 85, 
        flexibleSpace: Stack(
          children: [
            Positioned.fill(
              child: widget.isDarkMode
                  ? Image.asset(
                      'assets/images/resized_banner_logo.png',
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/resized_banner_logo_2.png',
                      fit: BoxFit.cover,
                    ),
            ),
            Positioned(
              left: 16.0,
              top: 37.0,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(4.0),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.menu, color: Color.fromARGB(255, 250, 251, 250)),
                  onSelected: (String result) {
                    if (result == 'Admin') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminLoginPage(),
                        ),
                      );
                    } else if (result == 'Contact Us') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactImagePage(), // Update to new page
                        ),
                      );
                    } else if (result == 'Giving') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GivingPage(), // Add navigation to GivingPage
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Admin',
                      child: Text('Admin'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Contact Us',
                      child: Text('Contact Us'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Giving',
                      child: Text('Giving'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: pages[selectedIndex],

      
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Devotion',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'Tribe',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true, 
        onTap: onItemTapped,
      ),
      
    );
  }
}


class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final List<Map<String, dynamic>> videos;
  final List<Map<String, dynamic>> devotionals;
  final List<Map<String, dynamic>> events;

  const HomePage({super.key, required this.onToggleTheme, required this.isDarkMode, required this.videos, required this.devotionals, required this.events});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double thumbnailHeight;

    
    if (screenWidth < 600) { 
      thumbnailHeight = 180.0;
    } else { 
      thumbnailHeight = 380.0; 
    }

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          
          Section(
            title: 'Latest Videos',
            items: widget.videos,
            thumbnailHeight: thumbnailHeight,
            thumbnailWidth: screenWidth - 17, 
            isDarkMode: widget.isDarkMode,
            onTap: (index) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayPage(
                    videoUrl: widget.videos[index]['url']!,
                    videoTitle: widget.videos[index]['title']!,
                    videoDate: widget.videos[index]['date']!,
                  ),
                ),
              );
            },
            toggleTheme: widget.onToggleTheme,
            titleFontSize: 18.0, 
          ),
          Section(
            title: 'Devotionals',
            items: widget.devotionals,
            thumbnailHeight: thumbnailHeight,
            thumbnailWidth: screenWidth - 17, 
            isDarkMode: widget.isDarkMode,
            onTap: (index) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DisplayDevotionalsPage(
                    description: widget.devotionals[index]['description']!,
                    thumbnailUrl: widget.devotionals[index]['thumbnail']!,
                    contentUrl: widget.devotionals[index]['contentUrl']!,
                  ),
                ),
              );
            },
            titleFontSize: 18.0, 
          ),
          Section(
            title: 'Upcoming Events',
            items: widget.events,
            thumbnailHeight: thumbnailHeight,
            thumbnailWidth: screenWidth - 17, 
            isDarkMode: widget.isDarkMode,
            onTap: (index) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DisplayUpcomingEventsPage(
                    description: widget.events[index]['description']!,
                    thumbnailUrl: widget.events[index]['thumbnail']!,
                    contentUrl: widget.events[index]['contentUrl']!,
                  ),
                ),
              );
            },
            titleFontSize: 18.0, 
          ),
          
        ],
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final double thumbnailHeight;
  final double thumbnailWidth;
  final Function(int) onTap;
  final bool isDarkMode;
  final VoidCallback? toggleTheme;
  final double titleFontSize; 

  const Section({
    super.key,
    required this.title,
    required this.items,
    required this.thumbnailHeight,
    required this.thumbnailWidth,
    required this.onTap,
    required this.isDarkMode,
    this.toggleTheme,
    required this.titleFontSize, 
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              
              Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              if (toggleTheme != null)
                Switch(
                  value: isDarkMode,
                  onChanged: (value) => toggleTheme!(),
                  activeColor: neonGreen,
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[400],
                ),
            ],
          ),
        ),
        SizedBox(
          height: thumbnailHeight + 16, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => onTap(index),
                child: Container(
                  margin: EdgeInsets.only(left: index == 0 ? 8.0 : 8.0, right: 8.0),
                  width: thumbnailWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    boxShadow: isDarkMode
                        ? []
                        : [
                     //       BoxShadow(
                     //         color: const Color.fromARGB(255, 70, 62, 62).withOpacity(0.6),
                     //         offset: const Offset(0, 4),
                     //         blurRadius: 1.0,
                     //         spreadRadius: 0.0,
                     //       ),
                          ],
                    borderRadius: BorderRadius.circular(12.0), 
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0), 
                    child: item is Map<String, dynamic> && item['thumbnail'] != null
                        ? CachedNetworkImage(
                            imageUrl: item['thumbnail']!,
                            height: thumbnailHeight,
                            width: thumbnailWidth,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                item is String ? item : item['description'],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              item is String ? item : item['description'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


class VideosPage extends StatelessWidget {
  final List<Map<String, dynamic>> videos;
  const VideosPage({super.key, required this.videos});
//-----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Updated length to 2 for tabs
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Flexible(
                child: TabBar(
                  labelPadding: EdgeInsets.symmetric(horizontal: 6.0),
                  tabs: [
                    Tab(text: "Videos"),
                    Tab(text: "Saved videos"),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: VideoSearchDelegate(videos),
                  );
                },
              ),
            ],
          ),
          toolbarHeight: 48, 
        ),
        body: const TabBarView(
          children: [
            VideoSection(title: "Videos"),
            VideoSection(title: "Saved videos"),
          ],
        ),
      ),
    );
  }
}

class VideoSection extends StatefulWidget {
  final String title;

  const VideoSection({super.key, required this.title});

  @override
  State<VideoSection> createState() => VideoSectionState();
}

class VideoSectionState extends State<VideoSection> {
  final Logger logger = Logger();
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _savedVideos = [];

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndLoadData();
  }

  Future<void> _initializeFirebaseAndLoadData() async {
    await Firebase.initializeApp();
    _loadVideos();
    _loadSavedVideos();
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
        };
      }).toList();
      setState(() {
        _videos = fetchedVideos;
      });
    } catch (e) {
      logger.e('Error loading videos: $e');
    }
  }

  Future<void> _loadSavedVideos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> savedVideoUrls = prefs.getStringList('savedVideos') ?? [];

    List<Map<String, dynamic>> savedVideos = [];

    for (String url in savedVideoUrls) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('uploads')
          .where('contentUrl', isEqualTo: url)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        savedVideos.add({
          'id': doc.id,
          'url': doc['contentUrl'],
          'thumbnail': doc['thumbnailUrl'],
          'title': doc['description'],
          'date': DateTime.now().toString(),
        });
      }
    }

    setState(() {
      _savedVideos = savedVideos;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double thumbnailHeight;

  
    if (screenWidth < 600) { 
      thumbnailHeight = 200.0;
    } else { 
      thumbnailHeight = 380.0; 
    }

    List<Map<String, dynamic>> displayedVideos = widget.title == "Saved videos" ? _savedVideos : _videos;

    return SingleChildScrollView(
      child: Column(
        children: [
          if (displayedVideos.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedVideos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayPage(
                          videoUrl: displayedVideos[index]['url']!,
                          videoTitle: displayedVideos[index]['title']!,
                          videoDate: displayedVideos[index]['date']!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: Column(
                      children: [
                        Container(
                          height: thumbnailHeight,
                          width: screenWidth,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                             borderRadius: BorderRadius.circular(12.0), 
                            
                          ),
                          child: ClipRRect(
                            
                            borderRadius: BorderRadius.circular(12.0), 
                            child: displayedVideos[index]['thumbnail'] != null
                                ? CachedNetworkImage(
                                    imageUrl: displayedVideos[index]['thumbnail']!,
                                    fit: BoxFit.cover,
                                   
                                  )
                                : Center(
                                    child: Text(
                                      displayedVideos[index]['title']!,
                                      style: const TextStyle(fontSize: 20, color: Colors.white),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          displayedVideos[index]['title']!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}


class DevotionalsPage extends StatelessWidget {
  const DevotionalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: "Devotions"),
              Tab(text: "Favorites"),
            ],
          ),
            toolbarHeight: 3,
        ),
        body: const TabBarView(
          children: [
            DevotionalSection(sectionTitle: "Devotions"),
            DevotionalSection(sectionTitle: "Favorites"),
          ],
        ),
      ),
    );
  }
}

class DevotionalSection extends StatefulWidget {
  final String sectionTitle;

  const DevotionalSection({super.key, required this.sectionTitle});

  @override
  DevotionalSectionState createState() => DevotionalSectionState();
}

class DevotionalSectionState extends State<DevotionalSection> {
  final Logger logger = Logger();
  List<Map<String, dynamic>> _devotionals = [];
  List<Map<String, dynamic>> _favoriteDevotionals = [];

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndLoadData();
  }

  Future<void> _initializeFirebaseAndLoadData() async {
    await Firebase.initializeApp();
    _loadDevotionals();
    _loadFavoriteDevotionals();
  }

  Future<void> _loadDevotionals() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('devotionals').get();

      List<Map<String, dynamic>> fetchedDevotionals = querySnapshot.docs.map((doc) {
        return {
          'thumbnail': doc['thumbnailUrl'],
          'description': doc['description'],
          'contentUrl': doc['contentUrl'],
        };
      }).toList();

      setState(() {
        _devotionals = fetchedDevotionals;
      });
    } catch (e) {
      logger.e('Error loading devotionals: $e');
    }
  }

  Future<void> _loadFavoriteDevotionals() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> favoriteContentUrls = prefs.getStringList('favoriteDevotionals') ?? [];

    List<Map<String, dynamic>> favoriteDevotionals = [];

    for (String contentUrl in favoriteContentUrls) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('devotionals')
          .where('contentUrl', isEqualTo: contentUrl)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        favoriteDevotionals.add({
          'thumbnail': doc['thumbnailUrl'],
          'description': doc['description'],
          'contentUrl': doc['contentUrl'],
        });
      }
    }

    setState(() {
      _favoriteDevotionals = favoriteDevotionals;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double thumbnailHeight = MediaQuery.of(context).orientation == Orientation.landscape ? 225.0 : 150.0; // Adjusted height for landscape
    const double thumbnailWidth = 150.0;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    List<Map<String, dynamic>> displayedDevotionals =
        widget.sectionTitle == "Favorites" ? _favoriteDevotionals : _devotionals;

    return SingleChildScrollView(
      child: Column(
        children: [
          if (displayedDevotionals.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedDevotionals.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DisplayDevotionalsPage(
                          description: displayedDevotionals[index]['description']!,
                          thumbnailUrl: displayedDevotionals[index]['thumbnail']!,
                          contentUrl: displayedDevotionals[index]['contentUrl']!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        Container(
                          height: isLandscape ? thumbnailHeight * 1.5 : thumbnailHeight, 
                          width: thumbnailWidth,
                          color: Colors.grey,
                          child: displayedDevotionals[index]['thumbnail'] != null
                              ? Image.network(
                                  displayedDevotionals[index]['thumbnail']!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.black54,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Icon(Icons.picture_as_pdf, size: 50, color: Colors.white),
                                ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayedDevotionals[index]['description']!,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}



class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Center(
        child: isLandscape
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/tribe.png',
                      fit: BoxFit.cover,
                      width: screenWidth,
                    ),
                  ],
                ),
              )
            : Center(
                child: Image.asset(
                  'assets/images/tribe.png',
                  fit: BoxFit.cover,
                  width: screenWidth, 
                ),
              ),
      ),
    );
  }
}


class GivingPage extends StatelessWidget {
  const GivingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giving'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: isLandscape
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/giving_1.png',
                      fit: BoxFit.cover,
                      width: screenWidth, 
                    ),
                  ],
                ),
              )
            : Center(
                child: Image.asset(
                  'assets/images/giving_1.png',
                  fit: BoxFit.cover,
                  width: screenWidth, 
                ),
              ),
      ),
    );
  }
}



class ContactImagePage extends StatelessWidget {
  const ContactImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact us'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: isLandscape
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/contact.png',
                      fit: BoxFit.cover,
                      width: screenWidth, 
                    ),
                  ],
                ),
              )
            : Center(
                child: Image.asset(
                  'assets/images/contact.png',
                  fit: BoxFit.cover,
                  width: screenWidth, 
                ),
              ),
      ),
    );
  }
}

