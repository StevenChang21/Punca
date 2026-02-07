import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:punca_ai/config/secrets.dart';
import 'package:punca_ai/core/constants/kssm_syllabus.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Standard 2026 model
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
          "      \"syllabus_refs\": [{\"form\": <int>, \"chapter_id\": <int>, \"subtopic_id\": <int e.g. 1 (for 2.1)>}],"
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
          debugPrint("Gemini 1.5 Flash overloaded, switching to Flash-Lite...");
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
        debugPrint("✅ LOG WRITTEN TO FILE: ${debugFile.absolute.path}");
      } catch (e) {
        debugPrint("❌ Failed to write log file: $e");
      }

      debugPrint("\n⬇️⬇️⬇️ START GEMINI RAW RESPONSE ⬇️⬇️⬇️");
      const int chunkSize = 800;
      for (int i = 0; i < responseText.length; i += chunkSize) {
        int end = (i + chunkSize < responseText.length)
            ? i + chunkSize
            : responseText.length;
        debugPrint(responseText.substring(i, end));
      }
      debugPrint("⬆️⬆️⬆️ END GEMINI RAW RESPONSE ⬆️⬆️⬆️\n");
      // ==================================

      return jsonDecode(responseText);
    } catch (e) {
      debugPrint("Error analyzing/parsing: $e");
      return null;
    }
  }

  /// Generates a targeted remediation drill for a specific weakness
  Future<RemediationDrill?> generateRemediation(Weakness weakness) async {
    try {
      final prompt =
          """
      ACT AS A MALAYSIAN KSSM MATH TUTOR.
      
      TASK: Generate a targeted "Micro-Remediation" for this specific student weakness.
      
      CRITICAL INSTRUCTIONS:
      1. METHOD: Strictly follow the Malaysian KSSM Syllabus methods. (e.g. use "Cross Method" for quadratics, NOT "FOIL").
      2. TONE: Explain like a friendly big brother. Use ANALOGIES or VISUAL EXAMPLES. Avoid textbook jargon.
      3. CONSISTENCY: The Analogy AND Example MUST match the student's specific gap. If the error is in Expansion, do NOT explain Factorisation.
      4. LENGTH: Keep it short and punchy.

      CONTEXT:
      Topic: ${weakness.topic}
      Student's Gap: ${weakness.reason}
      Mistake Example: ${weakness.instances.isNotEmpty ? weakness.instances.first.mistake : 'N/A'}
      Correction: ${weakness.instances.isNotEmpty ? weakness.instances.first.correction : 'N/A'}

      OUTPUT FORMAT (JSON ONLY):
      {
        "drill_title": "Short catchy title e.g. 'Fixing Algebra'",
        "mini_lesson": "STRIP TEXT. 1. Analogy (Max 1 sentence). 2. VISUAL EXAMPLE (Vertical steps) matching the Analogy exactly.\nExample output:\n'Think of the negative sign as a flipper.'\nExample:\n- (a + b)\n-> -a - b",
        "twin_question": "A NEW twin question (same concept, different numbers) for practice.",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correct_option_index": 0, // Integer 0-3
        "explanation": "Step-by-step solution using the KSSM method. Keep it simple."
      }
      """;

      final content = [Content.text(prompt)];
      // Use the model instance (ensure it's initialized)
      // Check if _model is initialized, if not, use a new one or handle error.
      // Assuming _model is late final and initialized in constructor.
      final response = await _model.generateContent(content);
      final text = response.text;

      if (text == null) return null;

      // Clean markdown if present
      final cleanText = text.replaceAll(RegExp(r'^```json\n|\n```$'), '');
      final json = jsonDecode(cleanText);

      return RemediationDrill.fromJson(json);
    } catch (e) {
      debugPrint("Error generating remediation: $e");
      return null;
    }
  }

  /// Generates a HARDER challenge drill based on the previous one
  Future<RemediationDrill?> generateChallengeDrill(
    Weakness weakness,
    RemediationDrill previousDrill,
    int level, // 1 or 2
  ) async {
    try {
      final prompt =
          """
      ACT AS A MALAYSIAN KSSM MATH TUTOR.
      
      TASK: Generate a "LEVEL UP" Challenge Question (Level $level/2) for this student.
      
      PREVIOUS QUESTION: "${previousDrill.twinQuestion}"
      CONCEPT: "${previousDrill.miniLesson}"
      
      INSTRUCTION:
      1. Create a NEW question testing the SAME weakness but HARDER.
      2. LEVEL 1: Change the numbers to be trickier (e.g. involve negatives or larger factors or fractions).
      3. LEVEL 2: Change the CONTEXT or add a small twist (e.g. "Try solving this backwards" or "Word problem style").
      4. RETAIN the "Mini Lesson". You can reuse the previous one or refine it slightly for the new context.
      5. Strict KSSM methods apply.

      OUTPUT FORMAT (JSON ONLY):
      {
        "drill_title": "Level Up Challenge!",
        "mini_lesson": "The Mini Lesson text (Analogy + Visual Steps).",
        "twin_question": "The new HARDER question.",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correct_option_index": 0, // Integer 0-3
        "explanation": "Step-by-step KSSM solution."
      }
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text;

      if (text == null) return null;

      final cleanText = text.replaceAll(RegExp(r'^```json\n|\n```$'), '');
      final json = jsonDecode(cleanText);

      return RemediationDrill.fromJson(json);
    } catch (e) {
      debugPrint("Error generating challenge drill: $e");
      return null;
    }
  }
}
