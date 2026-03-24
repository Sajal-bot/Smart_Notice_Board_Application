import 'dart:convert';
import 'package:http/http.dart' as http;

class DistilBertService {
  static const String _baseUrl =
      "https://taha2222141-apiweb.hf.space/predict"; // ✅ Your Hugging Face API endpoint

  static Future<String> getPriority(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Extract and normalize the priority
        final raw = (data["priority"] ?? "Low").toString().toLowerCase();

        if (raw.contains("high")) return "High";
        if (raw.contains("medium")) return "Medium";
        if (raw.contains("low")) return "Low";

        // fallback
        return "Low";
      } else {
        print("❌ API Error: ${response.statusCode} ${response.body}");
        return "Low";
      }
    } catch (e) {
      print("⚠️ Error calling DistilBERT API: $e");
      return "Low";
    }
  }
}
