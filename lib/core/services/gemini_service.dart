import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:punca_ai/config/secrets.dart';
import 'package:punca_ai/core/constants/kssm_syllabus.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Standard 2026 model
      apiKey: Secrets.geminiApiKey,
    );
  }

  Future<Map<String, dynamic>?> analyzeImages(List<XFile> images) async {
    try {
      final List<Part> parts = [];

      parts.add(
        TextPart(
          "You are an expert Math Tutor AI specialized in the Malaysian KSSM Syllabus. "
          "Analyze these sequential pages of a student's work. "
          "First, check if these images contain a math exam paper, worksheet, or handwritten math problem. "
          "If the content is NOT related to math or education (e.g. selfis, scenery), return this JSON: "
          "{\"subject\": \"Not Relevant\", \"grade\": \"N/A\", \"confidence_builder\": \"Please upload clear images of a math problem.\", \"weaknesses\": [], \"roadmap\": []}"
          "\n\n"
          "If it IS a math paper, analyze it using the following syllabus as context:\n"
          "${KssmSyllabus.getPrompt()}\n\n"
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
          "      \"priority\": <int 1-10> (10=Critical, 5=Medium),"
          "      \"mistake_example\": \"<Exact math step that was wrong, e.g. '2b-4'>\","
          "      \"correction_example\": \"<Correct math step, e.g. 'b^2-4b+4'>\","
          "      \"gap_type\": \"<Choose one: 'foundation', 'execution', 'precision'>\","
          "      \"action\": \"<Actionable advice referencing a specific KSSM Chapter if applicable>\","
          "      \"syllabus_refs\": [{\"form\": <int>, \"chapter_id\": <int>, \"subtopic_id\": \"<String e.g. '2.1'>\"}],"
          "      \"bounding_box\": [ymin, xmin, ymax, xmax] (Optional, referencing the first page found)"
          "    }"
          "  ],"
          "  \"confidence_builder\": \"<A short, encouraging comment about a correct attempt>\","
          "  \"remediation_drills\": ["
          "    {"
          "      \"drill_title\": \"<Verb-driven title e.g. 'Drill: Fix inequality logic'>\","
          "      \"mini_lesson\": \"<1-2 sentences explaining the concept clearly>\","
          "      \"twin_question\": \"<A NEW question with same logic but different numbers/context>\","
          "      \"correct_answer\": \"<The short correct answer for verification>\","
          "      \"options\": [\"<Option A>\", \"<Option B>\", \"<Option C>\"]"
          "    }"
          "  ]"
          "}",
        ),
      );

      for (XFile file in images) {
        final bytes = await file.readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }

      if (parts.length == 1) {
        throw "No valid images found to analyze.";
      }

      final content = [Content.multi(parts)];
      String? responseText;

      try {
        final response = await _model.generateContent(content);
        responseText = response.text;
      } catch (e) {
        if (e.toString().contains('503')) {
          print("Gemini 2.5 Flash overloaded, switching to Flash-Lite...");
          final fallbackModel = GenerativeModel(
            model: 'gemini-2.5-flash-lite',
            apiKey: Secrets.geminiApiKey,
          );
          final response = await fallbackModel.generateContent(content);
          responseText = response.text;
        } else {
          rethrow;
        }
      }

      if (responseText == null) return null;

      // Clean and parse
      final cleanJson = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '');
      return jsonDecode(cleanJson);
    } catch (e) {
      print("Error analyzing/parsing: $e");
      return null;
    }
  }
}
