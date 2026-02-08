import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:punca_ai/config/app_theme.dart';

class MathText extends StatelessWidget {
  final String content;
  final TextStyle? textStyle;
  final bool isCentered;

  const MathText({
    super.key,
    required this.content,
    this.textStyle,
    this.isCentered = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Basic sanitization
    String processed = content.replaceAll(r'\\', r'\');

    // 2. Split by newlines (handle both \n and \\n)
    List<String> lines = processed.split(RegExp(r'\n|\\\\n'));

    return Column(
      crossAxisAlignment: isCentered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: lines.map((line) {
        String lineContent = line.trim();
        if (lineContent.isEmpty) return const SizedBox.shrink();

        // 3. Handle arrows universally per line
        lineContent = lineContent.replaceAll('->', r' \to ');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Math.tex(
            lineContent,
            textStyle:
                textStyle ??
                const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            mathStyle: MathStyle.display,
            onErrorFallback: (err) => Text(
              lineContent,
              style: (textStyle ?? const TextStyle()).copyWith(
                color: Colors.red,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MixedMathText extends StatelessWidget {
  final String content;
  final TextStyle? textStyle;

  const MixedMathText({super.key, required this.content, this.textStyle});

  @override
  Widget build(BuildContext context) {
    // Regex for matching $...$ delimiters
    final RegExp exp = RegExp(r'\$([^$]+)\$');

    // Normalize content
    final String sanitizedContent = content
        .replaceAll(r'\\n', ' ')
        .replaceAll('\n', ' ');

    return LayoutBuilder(
      builder: (context, constraints) {
        List<Widget> spans = [];

        sanitizedContent.splitMapJoin(
          exp,
          onMatch: (m) {
            final mathContent = m.group(1) ?? '';
            final processedMath = mathContent.replaceAll(
              r'\to',
              r'\rightarrow',
            );

            // Wrap math in a scrollable container to prevent overflow
            spans.add(
              Container(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Math.tex(
                    processedMath,
                    textStyle:
                        textStyle ??
                        const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                    mathStyle: MathStyle.text,
                    onErrorFallback: (err) => Text(
                      '\$$mathContent\$',
                      style: (textStyle ?? const TextStyle()).copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
            );
            return '';
          },
          onNonMatch: (text) {
            if (text.isNotEmpty) {
              // Parse bold markdown **text**
              final RegExp boldExp = RegExp(r'\*\*(.*?)\*\*');
              text.splitMapJoin(
                boldExp,
                onMatch: (m) {
                  final boldText = m.group(1) ?? '';
                  spans.add(
                    Text(
                      boldText,
                      style:
                          (textStyle ??
                                  const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ))
                              .copyWith(fontWeight: FontWeight.bold),
                    ),
                  );
                  return '';
                },
                onNonMatch: (n) {
                  if (n.isNotEmpty) {
                    spans.add(
                      Text(
                        n,
                        style:
                            textStyle ??
                            const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    );
                  }
                  return '';
                },
              );
            }
            return '';
          },
        );

        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: spans,
        );
      },
    );
  }
}

class HorizontalMathText extends StatelessWidget {
  final String content;

  const HorizontalMathText({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: MathText(
        content: content,
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }
}
