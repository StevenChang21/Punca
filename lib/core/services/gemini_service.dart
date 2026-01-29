import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:punca_ai/config/secrets.dart';
import 'package:punca_ai/core/constants/kssm_syllabus.dart';
import 'dart:io';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Standard 2026 model
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
            "You are an expert Math Tutor AI specialized in the Malaysian KSSM Syllabus. "
            "First, check if this image is a math exam paper, worksheet, or handwritten math problem. "
            "If it is NOT related to math or education (e.g. a selfie, scenery, random object), return this JSON: "
            "{\"subject\": \"Not Relevant\", \"grade\": \"N/A\", \"confidence_builder\": \"Please upload a clear image of a math problem.\", \"weaknesses\": [], \"roadmap\": []}"
            "\n\n"
            "If it IS a math paper, analyze it using the following syllabus as context:\n"
            "${KssmSyllabus.mathSyllabus}\n\n"
            "Identify mistakes and categorize them into 3 specific Newman's Analysis buckets:\n"
            "1. 'foundation': Concept errors (didn't know which tool to use).\n"
            "2. 'execution': Process errors (right tool, used wrongly).\n"
            "3. 'precision': Careless errors (reading/encoding mistakes).\n\n"
            "Provide the output in this EXACT JSON format (no markdown code blocks):"
            "{"
            "  \"subject\": \"Math\","
            "  \"grade\": \"<Approximate Grade/Score like '65%' or 'B+'>\","
            "  \"topics_identified\": [\"<Topic 1>\", \"<Topic 2>\"],"
            "  \"weaknesses\": ["
            "    {"
            "      \"topic\": \"<Weak Topic>\","
            "      \"reason\": \"<Brief reason why>\","
            "      \"gap_type\": \"<Choose one: 'foundation', 'execution', 'precision'>\","
            "      \"action\": \"<Actionable advice referencing a specific KSSM Chapter if applicable>\","
            "      \"bounding_box\": [ymin, xmin, ymax, xmax]"
            "    }"
            "  ],"
            "  \"confidence_builder\": \"<A short, encouraging comment about a correct attempt>\","
            "  \"remediation_drills\": ["
            "    {"
            "      \"drill_title\": \"<Verb-driven title e.g. 'Drill: Fix inequality logic'>\","
            "      \"mini_lesson\": \"<1-2 sentences explaining the concept clearly>\","
            "      \"twin_question\": \"<A NEW question with same logic but different numbers/context>\","
            "      \"correct_answer\": \"<The short correct answer for verification>\","
            "      \"options\": [\"<Option A>\", \"<Option B>\", \"<Option C>\"]" // Optional, if MCQ is better
            "    }"
            "  ]"
            "}"
            "For bounding_box, use [ymin, xmin, ymax, xmax] integers on a 0-1000 scale. If specific location is hard to pinpoint, use null or []"
            "Task: For each drill, generate a 'Twin Question' (Isomorphic Problem). Verify if they understood the correction. Keep difficulty identical.",
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      try {
        final response = await _model.generateContent(content);
        return response.text;
      } catch (e) {
        if (e.toString().contains('503')) {
          // Fallback to Flash-Lite if Flash is overloaded
          print("Gemini 2.5 Flash overloaded, switching to Flash-Lite...");
          final fallbackModel = GenerativeModel(
            model: 'gemini-2.5-flash-lite',
            apiKey: Secrets.geminiApiKey,
          );
          final response = await fallbackModel.generateContent(content);
          return response.text;
        }
        rethrow;
      }
    } catch (e) {
      return "Error analyzing image: $e";
    }
  }
}
