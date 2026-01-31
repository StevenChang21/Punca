enum AssessmentStatus { analyzing, completed, failed }

enum GapType {
  foundation, // Concept errors
  execution, // Process errors
  precision, // Careless errors
  general, // Default
}

class AssessmentResult {
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

  // Factory to parse from Gemini JSON
  factory AssessmentResult.fromAnalysis({
    required String studentId,
    required List<String> imageUrls,
    required Map<String, dynamic> json,
  }) {
    return AssessmentResult(
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
      createdAt: DateTime.now(),
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

class Weakness {
  final String topic;
  final String reason;
  final GapType gapType;
  final String action;
  final List<int>? boundingBox;
  final List<SyllabusPointer> syllabusRefs;
  // New fields for enhanced UI
  final int priority;
  final String mistakeExample;
  final String correctionExample;

  Weakness({
    required this.topic,
    required this.reason,
    required this.gapType,
    required this.action,
    this.boundingBox,
    this.syllabusRefs = const [],
    this.priority = 5,
    this.mistakeExample = '',
    this.correctionExample = '',
  });

  factory Weakness.fromJson(Map<String, dynamic> json) {
    return Weakness(
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
      mistakeExample: json['mistake_example']?.toString() ?? '',
      correctionExample: json['correction_example']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'reason': reason,
      'gap_type': gapType.name,
      'action': action,
      'bounding_box': boundingBox,
      'syllabus_refs': syllabusRefs.map((e) => e.toMap()).toList(),
      'priority': priority,
      'mistake_example': mistakeExample,
      'correction_example': correctionExample,
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
  final String? subtopicId; // e.g. "2.1"

  const SyllabusPointer({
    required this.form,
    required this.chapterId,
    this.subtopicId,
  });

  factory SyllabusPointer.fromJson(Map<String, dynamic> json) {
    return SyllabusPointer(
      form: json['form'] ?? 0,
      chapterId: json['chapter_id'] ?? 0,
      subtopicId: json['subtopic_id']?.toString(),
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

  RemediationDrill({
    required this.title,
    required this.miniLesson,
    required this.twinQuestion,
    required this.correctAnswer,
    required this.options,
  });

  factory RemediationDrill.fromJson(Map<String, dynamic> json) {
    return RemediationDrill(
      title: json['drill_title'] ?? 'Drill',
      miniLesson: json['mini_lesson'] ?? '',
      twinQuestion: json['twin_question'] ?? '',
      correctAnswer: json['correct_answer'] ?? '',
      options: (json['options'] as List? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'drill_title': title,
      'mini_lesson': miniLesson,
      'twin_question': twinQuestion,
      'correct_answer': correctAnswer,
      'options': options,
    };
  }
}
