import 'package:uuid/uuid.dart';

enum AssessmentStatus { analyzing, completed, failed }

enum GapType {
  foundation, // Concept errors
  execution, // Process errors
  precision, // Careless errors
  general, // Default
}

class AssessmentResult {
  final String id;
  final String studentId;
  final String? paperId; // Optional firestore ID
  final List<String> imageUrls;
  final String subject;
  final String grade;
  final String confidenceBuilder;
  final List<Weakness> weaknesses;
  final List<RemediationDrill> remediationDrills;
  final AssessmentStatus status;
  final DateTime createdAt;

  AssessmentResult({
    this.id = '',
    required this.studentId,
    this.paperId,
    required this.imageUrls,
    required this.subject,
    required this.grade,
    required this.confidenceBuilder,
    required this.weaknesses,
    required this.remediationDrills,
    required this.status,
    required this.createdAt,
  });

  AssessmentResult copyWith({
    String? id,
    List<RemediationDrill>? remediationDrills,
  }) {
    return AssessmentResult(
      id: id ?? this.id,
      studentId: studentId,
      paperId: paperId,
      imageUrls: imageUrls,
      subject: subject,
      grade: grade,
      confidenceBuilder: confidenceBuilder,
      weaknesses: weaknesses,
      remediationDrills: remediationDrills ?? this.remediationDrills,
      status: status,
      createdAt: createdAt,
    );
  }

  // Factory to parse from Gemini JSON
  factory AssessmentResult.fromAnalysis({
    required String studentId,
    required List<String> imageUrls,
    required Map<String, dynamic> json,
  }) {
    return AssessmentResult(
      id: '',
      studentId: studentId,
      imageUrls: imageUrls,
      subject: json['subject'] ?? 'Unknown',
      grade: json['grade'] ?? 'Pending',
      confidenceBuilder: json['confidence_builder'] ?? '',
      weaknesses:
          ((json['weaknesses'] as List?)
                    ?.map(
                      (w) => w is Map<String, dynamic>
                          ? Weakness.fromJson(w)
                          : null,
                    )
                    .whereType<Weakness>()
                    .toList() ??
                [])
            ..sort((a, b) => b.priority.compareTo(a.priority)),
      remediationDrills: (json['remediation_drills'] as List? ?? [])
          .map((d) => RemediationDrill.fromJson(d))
          .toList(),
      status: AssessmentStatus.completed,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'imageUrls': imageUrls,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : null, // Legacy
      'subject': subject,
      'grade': grade,
      'confidenceBuilder': confidenceBuilder,
      'weaknesses': weaknesses.map((w) => w.toMap()).toList(),
      'remediationDrills': remediationDrills.map((d) => d.toMap()).toList(),
      'status': status.name, // Store enum as string
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MistakeInstance {
  final String mistake;
  final String correction;
  final int pageNumber;
  final String questionId;

  MistakeInstance({
    required this.mistake,
    required this.correction,
    this.pageNumber = 1,
    this.questionId = '',
  });

  factory MistakeInstance.fromJson(Map<String, dynamic> json) {
    return MistakeInstance(
      mistake: json['mistake'] ?? '',
      correction: json['correction'] ?? '',
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 1,
      questionId: json['question_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mistake': mistake,
      'correction': correction,
      'page_number': pageNumber,
      'question_id': questionId,
    };
  }
}

class Weakness {
  final String id;
  final String topic;
  final String reason;
  final GapType gapType;
  final String action;
  final List<int>? boundingBox;
  final List<SyllabusPointer> syllabusRefs;
  // New fields for enhanced UI
  final int priority;
  final String mistakeExample; // Kept for legacy/summary
  final String correctionExample; // Kept for legacy/summary
  final List<MistakeInstance> instances;

  Weakness({
    String? id,
    required this.topic,
    required this.reason,
    required this.gapType,
    required this.action,
    this.boundingBox,
    this.syllabusRefs = const [],
    this.priority = 5,
    this.mistakeExample = '',
    this.correctionExample = '',
    this.instances = const [],
  }) : id = id ?? const Uuid().v4();

  factory Weakness.fromJson(Map<String, dynamic> json) {
    // Parse instances if available
    var parsedInstances = <MistakeInstance>[];
    if (json['mistake_instances'] != null) {
      parsedInstances = (json['mistake_instances'] as List)
          .map((e) => MistakeInstance.fromJson(e))
          .toList();
    }

    // Fallback: If no instances but legacy fields exist, create one instance
    final legacyMistake = json['mistake_example']?.toString() ?? '';
    final legacyCorrection = json['correction_example']?.toString() ?? '';

    if (parsedInstances.isEmpty &&
        (legacyMistake.isNotEmpty || legacyCorrection.isNotEmpty)) {
      parsedInstances.add(
        MistakeInstance(mistake: legacyMistake, correction: legacyCorrection),
      );
    }

    // Ensure legacy fields are populated for UI compatibility
    var finalMistakeExample = legacyMistake;
    var finalCorrectionExample = legacyCorrection;

    if (finalMistakeExample.isEmpty && parsedInstances.isNotEmpty) {
      finalMistakeExample = parsedInstances.first.mistake;
      finalCorrectionExample = parsedInstances.first.correction;
    }

    return Weakness(
      id: json['id'], // Load ID if exists (for saved assessments)
      topic: json['topic'] ?? 'General',
      reason: json['reason'] ?? '',
      gapType: _parseGapType(json['gap_type']),
      action: json['action'] ?? '',
      boundingBox: (json['bounding_box'] as List?)?.cast<int>(),
      syllabusRefs:
          (json['syllabus_refs'] as List?)
              ?.map(
                (e) => e is Map<String, dynamic>
                    ? SyllabusPointer.fromJson(e)
                    : null,
              )
              .whereType<SyllabusPointer>()
              .toList() ??
          [],
      priority: (json['priority'] as num?)?.toInt() ?? 5,
      mistakeExample: finalMistakeExample,
      correctionExample: finalCorrectionExample,
      instances: parsedInstances,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'reason': reason,
      'gap_type': gapType.name,
      'action': action,
      'bounding_box': boundingBox,
      'syllabus_refs': syllabusRefs.map((e) => e.toMap()).toList(),
      'priority': priority,
      'mistake_example': mistakeExample,
      'correction_example': correctionExample,
      'mistake_instances': instances.map((e) => e.toMap()).toList(),
    };
  }

  static GapType _parseGapType(String? val) {
    return GapType.values.firstWhere(
      (e) => e.name == val?.toLowerCase(),
      orElse: () => GapType.general,
    );
  }
}

class SyllabusPointer {
  final int form;
  final int chapterId;
  final int? subtopicId; // e.g. 1 (representing 2.1)

  const SyllabusPointer({
    required this.form,
    required this.chapterId,
    this.subtopicId,
  });

  factory SyllabusPointer.fromJson(Map<String, dynamic> json) {
    return SyllabusPointer(
      form: (json['form'] as num?)?.toInt() ?? 0,
      chapterId: (json['chapter_id'] as num?)?.toInt() ?? 0,
      subtopicId: (json['subtopic_id'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'form': form, 'chapter_id': chapterId, 'subtopic_id': subtopicId};
  }
}

class RemediationDrill {
  final String title;
  final String miniLesson;
  final String twinQuestion;
  final String correctAnswer;
  final List<String> options;
  final List<VocabularyItem> vocabularyBridge;
  final String weaknessId; // Link to the weakness ID this drill solves

  RemediationDrill({
    required this.title,
    required this.miniLesson,
    required this.twinQuestion,
    required this.correctAnswer,
    required this.options,
    this.vocabularyBridge = const [],
    this.weaknessId = '',
  });

  factory RemediationDrill.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List? ?? []).cast<String>();
    String correctAnswer = json['correct_answer'] ?? '';

    // Prefer index if available for strictness
    if (json['correct_option_index'] != null) {
      final int idx = json['correct_option_index'];
      if (idx >= 0 && idx < options.length) {
        correctAnswer = options[idx];
      }
    }

    final vocabularyBridge = (json['vocabulary_bridge'] as List? ?? [])
        .map((e) => VocabularyItem.fromJson(e))
        .toList();

    return RemediationDrill(
      title: json['drill_title'] ?? 'Drill',
      miniLesson: json['mini_lesson'] ?? '',
      twinQuestion: json['twin_question'] ?? '',
      correctAnswer: correctAnswer,
      options: options,
      vocabularyBridge: vocabularyBridge,
      weaknessId: json['weakness_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'drill_title': title,
      'mini_lesson': miniLesson,
      'twin_question': twinQuestion,
      'correct_answer': correctAnswer,
      'options': options,
      'vocabulary_bridge': vocabularyBridge.map((e) => e.toMap()).toList(),
      'weakness_id': weaknessId, // Persist linkage
    };
  }

  // Helper to chunk mini-lesson for better readability
  List<String> get lessonChunks {
    if (miniLesson.isEmpty) return [];

    // Normalize: Replace all literal "\n" and other variants with actual newline char
    String processed = miniLesson
        .replaceAll(r'\\n', '\n') // Replace literal \n with newline
        .replaceAll(r'\n', '\n'); // Normalize just in case

    return processed
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class VocabularyItem {
  final String term;
  final String translation;
  final String context;

  VocabularyItem({
    required this.term,
    required this.translation,
    required this.context,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      term: json['term'] ?? '',
      translation: json['translation'] ?? '',
      context: json['context'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'term': term, 'translation': translation, 'context': context};
  }
}
