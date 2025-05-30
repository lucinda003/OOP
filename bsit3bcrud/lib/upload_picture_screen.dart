import 'dart:io'; // For File class
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // For kIsWeb
import 'package:flutter/material.dart'; // For Flutter widgets
import 'package:image_picker/image_picker.dart'; // For ImagePicker and XFile classes
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';

class UploadPictureScreen extends StatefulWidget {
  const UploadPictureScreen({super.key});

  @override
  State<UploadPictureScreen> createState() => UploadPictureScreenState();
}

class UploadPictureScreenState extends State<UploadPictureScreen> {
  File? _image;
  Uint8List? _webImageBytes; // For web image bytes
  final ImagePicker _picker = ImagePicker();
  final Logger logger = Logger();

  // Method to pick image from gallery or camera
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, // Choose gallery or ImageSource.camera
    );
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _image = null;
        });
      } else {
        setState(() {
          _image = File(pickedFile.path);
          _webImageBytes = null;
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    if (kIsWeb && _webImageBytes != null) {
      // Web: upload bytes
      logger.d('Attempting web image upload');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:3000/upload'), // Updated to use localhost
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _webImageBytes!,
          filename: 'upload.png',
        ),
      );

      try {
        logger.d('Sending web upload request');
        var response = await request.send();
        logger.d(
          'Received web upload response with status: ${response.statusCode}',
        );

        if (!mounted) return;

        if (response.statusCode == 200 || response.statusCode == 201) {
          logger.d('Web upload successful (status ${response.statusCode})');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')),
          );
          // Read and decode the response body
          final responseBody = await response.stream.bytesToString();
          final uploadedImageData = jsonDecode(responseBody);
          logger.d('Uploaded image data from server: $uploadedImageData');

          // Navigate to FeedScreen with uploaded image data
          Navigator.pushReplacementNamed(
            // ignore: use_build_context_synchronously
            context,
            '/feed',
            arguments: uploadedImageData,
          );
        } else {
          logger.d('Web upload failed (status ${response.statusCode})');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image.')),
          );
        }
      } catch (e) {
        logger.e('Web upload exception: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Web upload error: ${e.toString()}')),
        );
      }
    } else if (_image != null) {
      // Mobile/Desktop: upload file
      logger.d('Attempting mobile/desktop image upload');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:3000/upload'), // Updated to use localhost
      );
      request.files.add(
        await http.MultipartFile.fromPath('image', _image!.path),
      );

      try {
        logger.d('Sending mobile/desktop upload request');
        var response = await request.send();
        logger.d(
          'Received mobile/desktop upload response with status: ${response.statusCode}',
        );

        if (!mounted) return;

        if (response.statusCode == 200 || response.statusCode == 201) {
          logger.d(
            'Mobile/desktop upload successful (status ${response.statusCode})',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')),
          );
          // Read and decode the response body
          final responseBody = await response.stream.bytesToString();
          final uploadedImageData = jsonDecode(responseBody);
          logger.d('Uploaded image data from server: $uploadedImageData');

          // Navigate to FeedScreen with uploaded image data
          Navigator.pushReplacementNamed(
            // ignore: use_build_context_synchronously
            context,
            '/feed',
            arguments: uploadedImageData,
          );
        } else {
          logger.d(
            'Mobile/desktop upload failed (status ${response.statusCode})',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image.')),
          );
        }
      } catch (e) {
        logger.e('Mobile/desktop upload exception: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mobile/desktop upload error: ${e.toString()}'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No image selected.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Random Picture")),
      body: SingleChildScrollView(
        // Wrap the body in a SingleChildScrollView
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (kIsWeb)
                _webImageBytes != null
                    ? Image.memory(
                      _webImageBytes!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    )
                    : const Text("No image selected")
              else
                _image != null
                    ? Image.file(
                      _image!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    )
                    : const Text("No image selected"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text("Pick an Image"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadImage,
                child: const Text("Upload to Feed"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
