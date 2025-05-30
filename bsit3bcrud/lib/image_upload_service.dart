// lib/services/image_upload_service.dart

import 'package:http/http.dart' as http;
import 'dart:io'; // For File class
import 'package:logger/logger.dart'; // Import the logger package

// Create a logger instance
var logger = Logger();

Future<String?> uploadProfilePicture(File imageFile) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:3000/upload'), // Your API endpoint
  );

  var pic = await http.MultipartFile.fromPath(
    'profile_picture',
    imageFile.path,
  );
  request.files.add(pic);

  var response = await request.send();

  if (response.statusCode == 200) {
    var responseData = await response.stream.bytesToString();
    // Assuming the server returns the URL of the uploaded image
    return responseData; // This would be the image URL
  } else {
    // Use logger instead of print
    logger.e('Failed to upload profile picture'); // Log the error
    return null;
  }
}
