import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:punca_ai/config/app_theme.dart';

class MathText extends StatelessWidget {
  final String content;
  final TextStyle? textStyle;

  const MathText({super.key, required this.content, this.textStyle});

  @override
  Widget build(BuildContext context) {
    // 1. Replace safe arrow placeholder with LaTeX arrow
    // Use spaces around it to ensure LaTeX parser sees it clearly
    String processed = content.replaceAll('->', ' → ');

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

        // Logic: Only treat as math if inside $ delimiters or contains backslash
        bool isMath = (i % 2 == 1) || part.contains(r'\');

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
              style:
                  textStyle ??
                  const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
              softWrap: false,
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
}

class HorizontalMathText extends StatelessWidget {
  final String content;

  const HorizontalMathText({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    List<String> parts = content.split(r'$');
    List<Widget> widgets = [];

    for (int i = 0; i < parts.length; i++) {
      String part = parts[i].trim();
      if (part.isEmpty) continue;

      // Logic: Only treat as math if inside $ delimiters
      bool isMath = (i % 2 == 1) || part.contains(r'\');

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
}
