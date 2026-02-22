import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // ✅ Your Cloudinary details
  static const String cloudName = "drlyrj07t";
  static const String uploadPreset = "hwikigm";

  // Optional: keep uploads organized in Cloudinary Media Library
  static const String folder = "posters";

  static Future<Map<String, dynamic>> uploadImage(File file) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = uploadPreset
      ..fields["folder"] = folder
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Cloudinary upload failed: ${response.statusCode} ${response.body}");
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
