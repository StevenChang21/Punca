import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:punca_ai/config/secrets.dart';
import 'package:punca_ai/core/constants/kssm_syllabus.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview', // Standard 2026 model
      apiKey: Secrets.geminiApiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
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
          "CRITICAL INSTRUCTION: GUIDED INVENTORY & ANALYSIS PROTOCOL\n"
          "You are receiving multiple images. Analyze them as a sequential set.\n"
          "Follow this exact 3-step thought process to ensure accuracy:\n\n"
          "STEP 1: INVENTORY & SCORECARD\n"
          "Scan ALL images from top to bottom. List every single Question ID found (e.g. 1(a), 1(b), 2).\n"
          "For EACH Question ID, determine its status:\n"
          " - 'Correct': Answer is right and steps are logical.\n"
          " - 'Incorrect': Wrong answer or major logic fail.\n"
          " - 'Partial': Minor slips OR Error Carried Forward (ECF).\n"
          " *ECF RULE*: If a student uses a wrong value from a previous part (e.g. 1a) but applies the correct method in the current part (e.g. 1b), mark it 'Partial' (ECF). Do NOT punish them twice.\n\n"
          "STEP 2: DETAILED ANALYSIS\n"
          "Iterate through your Inventory. Only generate 'weakness' entries for items marked 'Incorrect' or 'Partial' (excluding ECF).\n"
          "Compare the student's work against the KSSM Syllabus:\n"
          "${KssmSyllabus.getPrompt()}\n"
          " - Identify the specific mistake.\n"
          " - Classify the mistake into 'foundation', 'execution', or 'precision'.\n"
          "   1. 'foundation': Concept errors (didn't know which tool to use).\n"
          "   2. 'execution': Process errors (right tool, used wrongly).\n"
          "   3. 'precision': Careless errors (reading/encoding mistakes).\n\n"
          "STEP 3: CLUSTERING (The Consolidation Rule)\n"
          "Group your findings into the 'weaknesses' list using this strictly CONSOLIDATED approach:\n"
          " - SAME QUESTION RULE: Mistakes occurring in the SAME question part (e.g. both in Q15(b)) MUST be grouped into ONE weakness entry, unless they are from completely different math branches (e.g. Geometry vs Algebra).\n"
          " - BROAD TOPICS: Use broader topic names to group related mechanical errors. e.g. Instead of separate 'Factorisation' and 'Cancellation' groups, merge them under 'Algebraic Simplification'.\n"
          " - MERGE OVER SPLIT: If Q1 has a 'Sign Error' and Q2 has a 'Expansion Error', group them under 'Algebraic Accuracy'. Ideally, produce fewer, denser cards rather than many fragmented ones.\n\n"
          "Output 'pages_processed': [1, 2, ...] to confirm coverage.\n"
          "Provide the output in this EXACT JSON format (no markdown code blocks):"
          "{"
          "  \"subject\": \"Math\","
          "  \"grade\": \"<Approximate Grade/Score like '65%' or 'B+'>\","
          "  \"pages_processed\": [<list of integers for pages analyzed, e.g. 1, 2, 3>],"
          "  \"total_questions_found\": <integer count of questions identified>,"
          "  \"questions_inventory\": ["
          "     {\"id\": \"1(a)\", \"status\": \"Correct\"},"
          "     {\"id\": \"1(b)\", \"status\": \"Partial (ECF)\"}"
          "  ],"
          "  \"topics_identified\": [\"<Topic 1>\", \"<Topic 2>\"],"
          "  \"weaknesses\": ["
          "    {"
          "      \"topic\": \"<Topic Name. Use simple STUDENT-FRIENDLY terms. e.g. instead of 'Polynomial Factorisation', say 'Breaking expressions down'.>\",  "
          "      \"reason\": \"<Explain to the STUDENT directly (use 'You'). Keep it simple, short, and non-academic. e.g. 'You forgot to multiply the negative sign.' NOT 'The student failed to distribute...'>\",\n"
          "      \"priority\": <int 1-10> (10=Critical, 5=Medium),"
          "      \"mistake_instances\": ["
          "        {"
          "           \"mistake\": \"<FORMAT: '[Tag]: \\\\n [Previous Step] \\\\n -> [Student Error]'. 1. TAG: Max 5 words. Use words ONLY if difficult to explain with math. 2. PREVIOUS STEP: The valid line right before the error. IF it is the first line, use the RAW QUESTION EXPRESSION (e.g. '3+4(n-1)') as [Previous Step]. 3. STUDENT ERROR: The exact raw expression from the image. EXAMPLE: 'Expansion Error: \\\\n 2(x+3) \\\\n -> 2x+3'.>\", \n"
          "           \"correction\": \"<FORMAT: '[Previous Step] \\\\n -> [Correct Step]'. Show the derivation from the SAME prev step. EXAMPLE: '2(x+3) \\\\n -> 2x + 6'.>\",\n"
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
          "  \"confidence_builder\": \"<A short, encouraging comment about a correct attempt>\",\n"
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
          print("Gemini 1.5 Flash overloaded, switching to Flash-Lite...");
          final fallbackModel = GenerativeModel(
            model: 'gemini-2.0-flash-lite-preview-02-05', // Try latest lite
            apiKey: Secrets.geminiApiKey,
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
            ),
          );
          final response = await fallbackModel.generateContent(content);
          responseText = response.text;
        } else {
          rethrow;
        }
      }

      if (responseText == null) return null;

      // === FILE LOGGING (PERSISTENT & CONSOLE) ===
      try {
        final directory = await getApplicationDocumentsDirectory();
        final debugFile = File('${directory.path}/gemini_debug_log.json');
        final timestamp = DateTime.now().toIso8601String();
        final logEntry =
            "\n\n=== LOG START [$timestamp] ===\n$responseText\n=== LOG END ===\n";
        await debugFile.writeAsString(logEntry, mode: FileMode.append);
        print("✅ LOG WRITTEN TO FILE: ${debugFile.absolute.path}");
      } catch (e) {
        print("❌ Failed to write log file: $e");
      }

      print("\n⬇️⬇️⬇️ START GEMINI RAW RESPONSE ⬇️⬇️⬇️");
      const int chunkSize = 800;
      for (int i = 0; i < responseText.length; i += chunkSize) {
        int end = (i + chunkSize < responseText.length)
            ? i + chunkSize
            : responseText.length;
        print(responseText.substring(i, end));
      }
      print("⬆️⬆️⬆️ END GEMINI RAW RESPONSE ⬆️⬆️⬆️\n");
      // ==================================

      return jsonDecode(responseText);
    } catch (e) {
      print("Error analyzing/parsing: $e");
      return null;
    }
  }
}
