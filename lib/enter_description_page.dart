import 'package:flutter/material.dart'; 
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:image_picker/image_picker.dart';

class EnterDescriptionPage extends StatefulWidget {
  final bool isVideo;
  final bool isEvent;

  const EnterDescriptionPage({
    super.key,
    required this.isVideo,
    this.isEvent = false,
  });

  @override
  EnterDescriptionPageState createState() => EnterDescriptionPageState();
}

class EnterDescriptionPageState extends State<EnterDescriptionPage> {
  final Logger _logger = Logger('EnterDescriptionPage');
  final TextEditingController descriptionController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  File? _thumbnailFile;
  File? _contentFile;

  @override
  void initState() {
    super.initState();
    _setupLogging();
  }

  void _setupLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      _logger.log(record.level, '${record.time}: ${record.message}');
    });
    _logger.info('Logging setup complete');
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _thumbnailFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickContent() async {
    final picker = ImagePicker();
    final pickedFile = await (widget.isVideo
        ? picker.pickVideo(source: ImageSource.gallery)
        : picker.pickImage(source: ImageSource.gallery));

    if (pickedFile != null) {
      setState(() {
        _contentFile = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadContent(String description, File? thumbnailFile, File? contentFile) async {
    if (thumbnailFile == null || contentFile == null) {
      _logger.severe('Thumbnail or content file is missing.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thumbnail or content file is missing.')),
      );
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      _logger.info('Uploading content...');

      // Specify storage bucket
      FirebaseStorage storage = FirebaseStorage.instanceFor(
          bucket: 'gs://apokalupsis-lgn-63b31.appspot.com');

      // Determine paths based on type
      String thumbnailPath, contentPath, collection;
      if (widget.isEvent) {
        thumbnailPath = 'upcoming_events_thumbnails/${thumbnailFile.uri.pathSegments.last}';
        contentPath = 'upcoming_events_images/${contentFile.uri.pathSegments.last}';
        collection = 'upcoming_events';
      } else if (widget.isVideo) {
        thumbnailPath = 'thumbnails/${thumbnailFile.uri.pathSegments.last}';
        contentPath = 'sermons_videos/${contentFile.uri.pathSegments.last}';
        collection = 'uploads';
      } else {
        thumbnailPath = 'devotionals_thumbnail/${thumbnailFile.uri.pathSegments.last}';
        contentPath = 'devotionals_images/${contentFile.uri.pathSegments.last}';
        collection = 'devotionals';
      }

      // Upload Thumbnail
      Reference thumbnailRef = storage.ref().child(thumbnailPath);
      UploadTask thumbnailUploadTask = thumbnailRef.putFile(thumbnailFile);
      thumbnailUploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
        });
      });
      await thumbnailUploadTask;
      String thumbnailUrl = await thumbnailRef.getDownloadURL();

      // Upload Content
      Reference contentRef = storage.ref().child(contentPath);
      UploadTask contentUploadTask = contentRef.putFile(contentFile);
      contentUploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
        });
      });
      await contentUploadTask;
      String contentUrl = await contentRef.getDownloadURL();

      // Save metadata to Firestore
      await FirebaseFirestore.instance.collection(collection).add({
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'contentUrl': contentUrl,
        'isVideo': widget.isVideo,
        'likes': 0, 
        'likedBy': [], 
        'views': 0, 
        'viewedBy': [], 
      });

      _logger.info('Upload successful!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload successful!')),
        );
      }
    } catch (e) {
      _logger.severe('Upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Description'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              if (_thumbnailFile != null)
                Image.file(_thumbnailFile!),
              ElevatedButton(
                onPressed: _pickThumbnail,
                child: const Text('Pick Thumbnail (ensure to pick the best to maintain App beauty)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickContent,
                child: widget.isVideo ? const Text('Pick Video') : const Text('Pick Image'),
              ),
              const SizedBox(height: 20),
              if (_contentFile != null)
                widget.isVideo ? Text('Video selected: ${_contentFile!.path}') : Image.file(_contentFile!),
              const SizedBox(height: 20),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              if (_isUploading)
                Column(
                  children: [
                    const Text('Uploading...'),
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 20),
                  ],
                ),
              ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () {
                        if (_thumbnailFile == null || _contentFile == null) {
                          _logger.warning('Upload not initiated. Thumbnail or content file is missing.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select both thumbnail and content to upload.')),
                          );
                          return;
                        }
                        String description = descriptionController.text;
                        uploadContent(description, _thumbnailFile, _contentFile);
                      },
                child: const Text('Upload Content'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
