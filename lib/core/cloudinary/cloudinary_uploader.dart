import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryConfig {
  const CloudinaryConfig._();

  static const cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;
}

class CloudinaryNotConfigured implements Exception {
  const CloudinaryNotConfigured();

  @override
  String toString() =>
      'Cloudinary is not configured. Pass CLOUDINARY_CLOUD_NAME and '
      'CLOUDINARY_UPLOAD_PRESET with --dart-define.';
}

class CloudinaryUploader {
  CloudinaryUploader({http.Client? client, ImagePicker? picker})
    : _client = client ?? http.Client(),
      _picker = picker ?? ImagePicker();

  final http.Client _client;
  final ImagePicker _picker;

  Future<XFile?> pick() => _picker.pickImage(source: ImageSource.gallery);

  /// Uploads [file] and returns the https URL.
  Future<String> upload(XFile file) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const CloudinaryNotConfigured();
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
      ),
    );
    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await _client.send(request);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw StateError('Image upload failed (${streamed.statusCode}).');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Image upload did not return a URL.');
    }
    return url;
  }
}
