import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:punca_ai/config/secrets.dart';
import 'dart:io';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Optimized for speed/cost
      apiKey: Secrets.geminiApiKey,
    );
  }

  Future<String?> analyzeImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return "Error: Image file not found";
      }

      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
            "You are an expert Math Tutor AI. "
            "First, check if this image is a math exam paper, worksheet, or handwritten math problem. "
            "If it is NOT related to math or education (e.g. a selfie, scenery, random object), return this JSON: "
            "{\"subject\": \"Not Relevant\", \"grade\": \"N/A\", \"confidence_builder\": \"Please upload a clear image of a math problem.\", \"weaknesses\": [], \"roadmap\": []}"
            "\n\n"
            "If it IS a math paper, analyze it and provide the output in this EXACT JSON format (no markdown code blocks):"
            "{"
            "  \"subject\": \"Math\","
            "  \"grade\": \"<Approximate Grade/Score like '65%' or 'B+'>\","
            "  \"topics_identified\": [\"<Topic 1>\", \"<Topic 2>\"],"
            "  \"weaknesses\": ["
            "    {\"topic\": \"<Weak Topic>\", \"reason\": \"<Brief reason why>\"}"
            "  ],"
            "  \"confidence_builder\": \"<A short, encouraging comment about a correct attempt>\","
            "  \"roadmap\": ["
            "    {\"title\": \"<Step 1>\", \"description\": \"<Short description>\", \"impact\": \"High\"}"
            "  ]"
            "}",
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      return "Error analyzing image: $e";
    }
  }
}
