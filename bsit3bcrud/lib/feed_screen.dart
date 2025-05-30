import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart' as api_service;
import 'package:logger/logger.dart';

class FeedScreen extends StatefulWidget {
  final Map<String, dynamic>? uploadedImageData;
  const FeedScreen({super.key, this.uploadedImageData});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> images = [];
  bool isLoading = true;
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    // Add uploaded image data if provided
    if (widget.uploadedImageData != null) {
      // Ensure the ID is treated as a string (UUID)
      if (widget.uploadedImageData!.containsKey('id')) {
        // Create a mutable map to ensure we can work with the ID
        final mutableImageData = Map<String, dynamic>.from(
          widget.uploadedImageData!,
        );
        mutableImageData['id'] = mutableImageData['id'].toString();
        images.add(mutableImageData);
        logger.d(
          'Added uploaded image to list with ID: ${mutableImageData['id']}',
        );
      } else {
        logger.w(
          'Uploaded image data missing ID field: ${widget.uploadedImageData}',
        );
      }
    }
    fetchImages(); // Fetch other images from the server
  }

  Future<void> fetchImages() async {
    final response = await http.get(
      Uri.parse('${api_service.ApiService.apiUrl}/images'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      logger.d('Raw images data from server: ${data.toString()}');

      // Log ID and type for each image
      for (var img in data) {
        if (img.containsKey('id')) {
          logger.d('Image ID: ${img['id']}, Type: ${img['id'].runtimeType}');
        } else {
          logger.d('Image data missing ID field: ${img.toString()}');
        }
      }

      setState(() {
        images = data;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteImage(dynamic imageId) async {
    // Find the image data in the local list
    final imageToDelete = images.firstWhere(
      (img) => img['id'].toString() == imageId.toString(),
      orElse: () => null,
    );

    if (imageToDelete == null) {
      logger.w(
        'Attempted to delete image with ID $imageId, but not found in local list.',
      );
      // Optionally show a message to the user
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image not found in list.')));
      return;
    }

    // Determine the ID to use for deletion (prefer string ID if available)
    final String idForDeletion =
        imageToDelete['id'] is String
            ? imageToDelete['id'] // Use string ID if it exists
            : imageId.toString(); // Otherwise, use the provided ID as string

    // Log the image ID we're trying to delete
    logger.d(
      'Attempting to delete image with ID: $idForDeletion (Original ID: $imageId, Type: ${imageId.runtimeType})',
    );

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete image $idForDeletion?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      logger.d('User confirmed deletion for ID: $idForDeletion');
      try {
        final bool success = await api_service.ApiService.deleteImage(
          idForDeletion,
        );
        if (success) {
          // Remove the image from the local list
          setState(() {
            images.removeWhere((img) => img['id'].toString() == idForDeletion);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete image $idForDeletion')),
            );
          }
        }
        // Always refetch images after a delete attempt to ensure sync
        fetchImages();
      } catch (e) {
        logger.e('Error deleting image: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting image: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : images.isEmpty
              ? const Center(child: Text('No images yet.'))
              : ListView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final img = images[index];
                  // Log the image data for debugging
                  logger.d('Image data: ${img.toString()}');
                  // Ensure imageId is handled correctly for deletion
                  final dynamic imageIdToDelete = img['id'];

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Image.network(img['url']),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => _deleteImage(
                                      imageIdToDelete.toString(),
                                    ), // Ensure ID is sent as string
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
