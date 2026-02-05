import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/roadmap_screen.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_math_fork/flutter_math.dart';

class AnalysisResultScreen extends StatelessWidget {
  final AssessmentResult result;

  const AnalysisResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analysis Result"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreCard(result.subject, result.grade),
            const SizedBox(height: 24),
            _buildConfidenceBuilder(result.confidenceBuilder),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Weakness Analysis",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (result.imageUrls.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(
                      Icons.collections,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      "View ${result.imageUrls.length > 1 ? 'Pages (${result.imageUrls.length})' : 'Page'}",
                    ),
                    onPressed: () => _showImages(context, result.imageUrls),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (result.weaknesses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "No specific weaknesses identified! Great job!",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...result.weaknesses.map((w) {
                return _buildWeaknessItem(context, w);
              }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Roadmap
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RoadmapScreen(roadmapData: result.remediationDrills),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "View Generated Roadmap",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForType(GapType type) {
    switch (type) {
      case GapType.foundation:
        return Colors.redAccent;
      case GapType.execution:
        return Colors.orangeAccent;
      case GapType.precision:
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  void _showImages(BuildContext context, List<String> paths) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Original Work (${paths.length} pages)",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 400,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: paths.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(paths[index])),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String subject, String grade) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  "Paper Analysis",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text(
            grade,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBuilder(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                "Confidence Check",
                style: TextStyle(
                  color: AppColors.accent.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }

  String _sanitizeLatex(String latex) {
    // Remove leading/trailing $ or $$ and trim whitespace
    return latex
        .replaceAll(RegExp(r'^\$+'), '')
        .replaceAll(RegExp(r'\$+$'), '')
        .trim();
  }

  Widget _buildVerticalMath(String rawInput) {
    String trimmed = rawInput.trim();

    // Check if it's a single pure latex block wrapped in $...$
    bool isWrapped = trimmed.startsWith(r'$') && trimmed.endsWith(r'$');
    bool hasInternalDollars = false;
    if (isWrapped) {
      // Check for extra $ inside the wrapper
      if (trimmed.length > 2) {
        hasInternalDollars = trimmed
            .substring(1, trimmed.length - 1)
            .contains(r'$');
      }
    } else {
      hasInternalDollars = trimmed.contains(r'$');
    }

    // DECISION:
    // 1. If it has internal dollars (e.g. "Text $math$ text") -> Mixed Mode
    // 2. If it is NOT wrapped and has NO dollars -> Pure Math (Implicit)
    // 3. If it IS wrapped and has NO internal dollars -> Pure Math (Explicit)

    if (hasInternalDollars || (!isWrapped && trimmed.contains(r'$'))) {
      return _buildMixedMathText(trimmed);
    }

    // --- PURE MATH MODE (Existing Logic) ---
    final cleanLatex = _sanitizeLatex(trimmed);

    // Naive split by '=' to stack steps vertically
    final parts = cleanLatex.split('=');
    if (parts.length <= 1) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(
          cleanLatex,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          onErrorFallback: (err) => Text(
            cleanLatex,
            style: const TextStyle(color: Colors.red),
          ), // Fallback if parse fails
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.asMap().entries.map((entry) {
        final index = entry.key;
        final part = entry.value.trim();
        if (part.isEmpty) return const SizedBox.shrink();

        final prefix = index == 0 ? '' : '= ';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              prefix + part,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              onErrorFallback: (err) => Text(
                prefix + part,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMixedMathText(String content) {
    // 1. Replace safe arrow placeholder with LaTeX arrow
    // Use spaces around it to ensure LaTeX parser sees it clearly
    String processed = content.replaceAll('->', r' \rightarrow ');

    // 2. Robust line splitting (handles \n, \r\n, etc.)
    List<String> lines = const LineSplitter().convert(processed);
    List<Widget> lineWidgets = [];

    for (String line in lines) {
      if (line.trim().isEmpty) continue;

      List<String> parts = line.split(r'$');
      List<Widget> rowChildren = [];

      for (int i = 0; i < parts.length; i++) {
        String part = parts[i].trim();
        if (part.isEmpty) continue;

        // Logic: Same heuristics as before
        bool isMath =
            (i % 2 == 1) ||
            part.contains(r'\') ||
            part.contains(RegExp(r'[=+\^]'));

        if (isMath) {
          // MATH PART
          rowChildren.add(
            Math.tex(
              part,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              onErrorFallback: (err) => Text(
                part,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          );
        } else {
          // TEXT PART
          rowChildren.add(
            Text(
              part,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          );
        }
        // Spacing between parts
        rowChildren.add(const SizedBox(width: 4));
      }

      // 3. Wrap each line row in a horizontal scroll view
      lineWidgets.add(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );

      // Vertical spacing between lines
      lineWidgets.add(const SizedBox(height: 8));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lineWidgets,
    );
  }

  // Used for Preview Cards - Keeps everything in a single line row
  Widget _buildHorizontalMixedMath(String content) {
    List<String> parts = content.split(r'$');
    List<Widget> widgets = [];

    for (int i = 0; i < parts.length; i++) {
      String part = parts[i].trim();
      if (part.isEmpty) continue;

      // Logic: If odd index OR contains backslash OR contains math symbols
      bool isMath =
          (i % 2 == 1) ||
          part.contains(r'\') ||
          part.contains(RegExp(r'[=+\^]'));

      if (isMath) {
        // Math
        widgets.add(
          Math.tex(
            part,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            onErrorFallback: (err) => Text(
              part,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        );
      } else {
        // Text
        widgets.add(Text(part, style: const TextStyle(fontSize: 12)));
      }
      widgets.add(const SizedBox(width: 4));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Using Flexible/Expanded in a Row can be tricky if mainAxisSize is min.
        // For horizontal scroll row, we usually don't need Flexible, just let it scroll in parent.
        for (var w in widgets) w,
      ],
    );
  }

  Widget _buildWeaknessItem(BuildContext context, Weakness w) {
    final color = _getColorForType(w.gapType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            w.topic,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (w.priority >= 8)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "CRITICAL",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (w.instances.isNotEmpty ||
              w.mistakeExample.isNotEmpty ||
              w.correctionExample.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => _showExpandedMath(context, w),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fullscreen,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          w.instances.length > 1
                              ? "View All ${w.instances.length} Instances"
                              : "View Details",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (w.mistakeExample.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Your Step",
                            style: TextStyle(fontSize: 10, color: Colors.red),
                          ),
                          const SizedBox(height: 2),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildHorizontalMixedMath(w.mistakeExample),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (w.mistakeExample.isNotEmpty &&
                    w.correctionExample.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                if (w.correctionExample.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Correct Step",
                            style: TextStyle(fontSize: 10, color: Colors.green),
                          ),
                          const SizedBox(height: 2),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildHorizontalMixedMath(
                              w.correctionExample,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (w.syllabusRefs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: w.syllabusRefs.map((ref) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    "Form ${ref.form} • Ch ${ref.chapterId}${ref.subtopicId != null ? ' • ${ref.subtopicId}' : ''}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text(
                "See Explanation",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              children: [
                Text(
                  w.reason,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (w.action.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.rocket_launch,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Action to fix this weakness",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          w.action,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExpandedMath(BuildContext context, Weakness w) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.topic,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (w.instances.length > 1)
                          Text(
                            "${w.instances.length} occurrences found",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: w.instances.isNotEmpty ? w.instances.length : 1,
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Divider(thickness: 4, color: AppColors.background),
                  ),
                  itemBuilder: (context, index) {
                    final mistake = w.instances.isNotEmpty
                        ? w.instances[index].mistake
                        : w.mistakeExample;
                    final correction = w.instances.isNotEmpty
                        ? w.instances[index].correction
                        : w.correctionExample;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (w.instances.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 12),
                            child: Row(
                              children: [
                                if (w.instances.length > 1) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Instance ${index + 1}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  "Page ${w.instances[index].pageNumber} • Question ${w.instances[index].questionId}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          "Your Step",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2),
                            ),
                          ),
                          child: _buildMixedMathText(mistake),
                        ),
                        const SizedBox(height: 24),
                        const Center(
                          child: Icon(
                            Icons.arrow_downward,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Correct Step",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.2),
                            ),
                          ),
                          child: _buildMixedMathText(correction),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
