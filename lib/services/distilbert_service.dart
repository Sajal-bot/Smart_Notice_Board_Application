import 'dart:convert';
import 'package:http/http.dart' as http;

class DistilBertService {
  static const String _baseUrl =
      "https://taha2222141-apiweb.hf.space/predict";

  static Future<String> getPriority(String text) async {
    try {
      print("==================================================");
      print("NOTICE TEXT: $text");
      print("API URL: $_baseUrl");

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("RAW RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("DECODED RESPONSE: $data");

        final raw = (data["priority"] ?? "Low").toString().toLowerCase();
        print("RAW PRIORITY FIELD: $raw");

        if (raw.contains("high")) {
          print("FINAL LABEL: High");
          return "High";
        }
        if (raw.contains("medium")) {
          print("FINAL LABEL: Medium");
          return "Medium";
        }
        if (raw.contains("low")) {
          print("FINAL LABEL: Low");
          return "Low";
        }

        print("FINAL LABEL: Low (fallback - unexpected priority field)");
        return "Low";
      } else {
        print("FINAL LABEL: Low (fallback - non 200 response)");
        return "Low";
      }
    } catch (e) {
      print("⚠️ Error calling DistilBERT API: $e");
      print("FINAL LABEL: Low (fallback - exception)");
      return "Low";
    }
  }
}