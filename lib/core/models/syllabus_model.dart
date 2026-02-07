class SyllabusChapter {
  final int id;
  final String title;

  /// Key is the subtopic number (e.g. 1 for "1.1", 2 for "1.2")
  final Map<int, String> subtopics;

  const SyllabusChapter({
    required this.id,
    required this.title,
    required this.subtopics,
  });
}
