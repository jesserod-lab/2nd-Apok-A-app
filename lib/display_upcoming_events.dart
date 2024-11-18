import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class DisplayUpcomingEventsPage extends StatefulWidget {
  final String description;
  final String thumbnailUrl;
  final String contentUrl;

  const DisplayUpcomingEventsPage({
    super.key,
    required this.description,
    required this.thumbnailUrl,
    required this.contentUrl,
  });

  @override
  DisplayUpcomingEventsPageState createState() => DisplayUpcomingEventsPageState();
}

class DisplayUpcomingEventsPageState extends State<DisplayUpcomingEventsPage> with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  String? eventImageUrl;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isImageLoaded = false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEventImage();
  }

  Future<void> _loadEventImage() async {
    try {
      setState(() {
        eventImageUrl = widget.contentUrl;
      });
      await precacheImage(NetworkImage(widget.contentUrl), context);
      setState(() {
        _isImageLoaded = true;
      });
      _controller.forward();
      logger.d('Event image URL: $eventImageUrl');
    } catch (e) {
      logger.e('Error loading event image: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
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
                  child: Image.network(
                    eventImageUrl!,
                    fit: BoxFit.cover,
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
            ],
          ),
        ),
      ),
    );
  }
}
