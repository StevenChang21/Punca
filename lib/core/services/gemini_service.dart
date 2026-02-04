import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:punca_ai/config/secrets.dart';
import 'package:punca_ai/core/constants/kssm_syllabus.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview', // Standard 2026 model
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
          "If the content is NOT related to math or education (e.g. selfies, scenery), return this JSON: "
          "{\"subject\": \"Not Relevant\", \"grade\": \"N/A\", \"pages_processed\": [], \"total_questions_found\": 0, \"confidence_builder\": \"Please upload clear images of a math problem.\", \"weaknesses\": []}"
          "\n\n"
          "CRITICAL INSTRUCTION: MULTI-PAGE ANALYSIS REQUIRED\n"
          "You are receiving multiple images. You must analyze them sequentially as Page 1, Page 2, etc. until the last page.\n"
          "Step 1: Count the total number of distinct math questions across ALL images combined. IMPORTANT: Pay close attention to sub-questions (e.g. 1(a), 1(b), 2(i), 2(ii)). Treat each sub-question as a specific item to check.\n"
          "Step 2: Verify every single question found. If a question is wrong, it MUST have a corresponding 'weakness' entry.\n"
          "Step 3: Output 'pages_processed': [1, 2, ...] in the JSON to confirm you analyzed each page index.\n\n"
          "If it IS a math paper, analyze it using the following syllabus as context:\n"
          "${KssmSyllabus.getPrompt()}\n\n"
          "Identify mistakes and categorize them into 3 specific Newman's Analysis buckets:\n"
          "1. 'foundation': Concept errors (didn't know which tool to use).\n"
          "2. 'execution': Process errors (right tool, used wrongly).\n"
          "3. 'precision': Careless errors (reading/encoding mistakes).\n\n"
          "IMPORTANT: Group repeated similar mistakes into a SINGLE weakness entry. "
          "e.g. If the student makes 3 algebra expansion errors, create 1 'Weakness' with 3 'mistake_instances'.\n\n"
          "Provide the output in this EXACT JSON format (no markdown code blocks):"
          "{"
          "  \"subject\": \"Math\","
          "  \"grade\": \"<Approximate Grade/Score like '65%' or 'B+'>\","
          "  \"pages_processed\": [<list of integers for pages analyzed, e.g. 1, 2, 3>],"
          "  \"total_questions_found\": <integer count of questions identified>,"
          "  \"topics_identified\": [\"<Topic 1>\", \"<Topic 2>\"],"
          "  \"weaknesses\": ["
          "    {"
          "      \"topic\": \"<Topic Name. Use simple STUDENT-FRIENDLY terms. e.g. instead of 'Polynomial Factorisation', say 'Breaking expressions down'.>\",  "
          "      \"reason\": \"<Brief reason why>\","
          "      \"priority\": <int 1-10> (10=Critical, 5=Medium),"
          "      \"mistake_instances\": ["
          "        {"
          "           \"mistake\": \"<LaTeX MATH ONLY. Context: 'Source=Deviation'. e.g. '(b-2)^2 = 2b-4'>\", "
          "           \"correction\": \"<LaTeX MATH ONLY. Step: 'Source=Inter=Result'. e.g. '(b-2)^2=(b-2)(b-2)=b^2-4b+4'>\","
          "           \"page_number\": <int, 1-based index of the page this appears on>,"
          "           \"question_id\": \"<String identifier e.g. '1(a)', 'Q3', '4b'>\""
          "        }"
          "      ],"
          "      \"gap_type\": \"<Choose one: 'foundation', 'execution', 'precision'>\","
          "      \"action\": \"<MANDATORY: Cite KSSM Chapter FIRST (e.g. 'Review Ch 2.1'). Concisely explain fix. NO jargon like 'FOIL'. Use 'expansion' or 'cross method'. Max 15 words. e.g. 'Review Ch 5.3. Expand brackets carefully.'>\","
          "      \"syllabus_refs\": [{\"form\": <int>, \"chapter_id\": <int>, \"subtopic_id\": \"<String e.g. '2.1'>\"}],"
          "      \"bounding_box\": [ymin, xmin, ymax, xmax] (Optional, referencing the first page found)"
          "    }"
          "  ],"
          "  \"confidence_builder\": \"<A short, encouraging comment about a correct attempt>\""
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

      print(
        "=== RAW GEMINI RESPONSE ===\n$responseText\n===========================",
      );

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
