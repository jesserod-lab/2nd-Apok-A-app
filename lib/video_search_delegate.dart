import 'package:flutter/material.dart';
import 'play.dart';

class VideoSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> videos;

  VideoSearchDelegate(this.videos);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Map<String, dynamic>> results = videos
        .where((video) =>
            video['title']!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: results[index]['thumbnail'] != null
              ? Image.network(results[index]['thumbnail']!)
              : null,
          title: Text(results[index]['title']!),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayPage(
                  videoUrl: results[index]['url']!,
                  videoTitle: results[index]['title']!,
                  videoDate: results[index]['date']!,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Map<String, dynamic>> suggestions = videos
        .where((video) =>
            video['title']!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: suggestions[index]['thumbnail'] != null
              ? Image.network(suggestions[index]['thumbnail']!)
              : null,
          title: Text(suggestions[index]['title']!),
          onTap: () {
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayPage(
                  videoUrl: suggestions[index]['url']!,
                  videoTitle: suggestions[index]['title']!,
                  videoDate: suggestions[index]['date']!,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
