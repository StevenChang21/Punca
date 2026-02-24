import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    // 2. Split by newlines (handle \n, \r\n, and literal \n)
    List<String> lines = processed.split(RegExp(r'\r\n|\n|\\n'));

    return Column(
      crossAxisAlignment: isCentered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: lines.map((line) {
        String lineContent = line.trim();
        if (lineContent.isEmpty) return const SizedBox.shrink();

        // 3. Render directly (library handles headers/spacing if valid TeX)

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
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
    // 0. Check for [SVG]...[/SVG] markers first
    final svgPattern = RegExp(r'\[SVG\](.*?)\[/SVG\]', dotAll: true);
    if (svgPattern.hasMatch(content)) {
      return _buildWithSvg(context, svgPattern);
    }

    // 1. Basic sanitization of newlines
    String processed = content.replaceAll(r'\\', r'\');
    // Split by \n, \r\n, or literal \n
    List<String> lines = processed.split(RegExp(r'\r\n|\n|\\n'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: _buildLine(context, line),
        );
      }).toList(),
    );
  }

  /// Splits content into text and SVG segments, rendering each appropriately.
  Widget _buildWithSvg(BuildContext context, RegExp svgPattern) {
    final List<Widget> widgets = [];
    int lastEnd = 0;

    for (final match in svgPattern.allMatches(content)) {
      // Text before this SVG
      if (match.start > lastEnd) {
        final textBefore = content.substring(lastEnd, match.start);
        widgets.add(_buildTextSegment(context, textBefore));
      }

      // SVG segment
      final svgString = match.group(1) ?? '';
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SvgPicture.string(
                svgString,
                fit: BoxFit.contain,
                width: 250,
              ),
            ),
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Text after last SVG
    if (lastEnd < content.length) {
      final textAfter = content.substring(lastEnd);
      widgets.add(_buildTextSegment(context, textAfter));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Renders a text segment through the existing line-by-line pipeline.
  Widget _buildTextSegment(BuildContext context, String text) {
    String processed = text.replaceAll(r'\\', r'\');
    List<String> lines = processed.split(RegExp(r'\r\n|\n|\\n'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: _buildLine(context, line),
        );
      }).toList(),
    );
  }

  Widget _buildLine(BuildContext context, String line) {
    // Regex for matching $...$ delimiters
    final RegExp exp = RegExp(r'\$([^$]+)\$');

    // Check if line contains explicit delimiters
    if (exp.hasMatch(line)) {
      return LayoutBuilder(
        builder: (context, constraints) {
          List<Widget> spans = [];

          line.splitMapJoin(
            exp,
            onMatch: (m) {
              final mathContent = m.group(1) ?? '';
              // Removed manual sanitization as per user request.
              // Letting the library handle pure LaTeX.

              // Wrap math in a scrollable container to prevent overflow
              spans.add(
                Container(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Math.tex(
                      mathContent,
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
              if (text.isEmpty) return '';

              // Handle **bold** markdown
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

    // No explicit $...$ delimiters — check for bare LaTeX commands
    final hasBareLaTeX = RegExp(
      r'\\(frac|sqrt|text|times|div|cdot|pm|mp|leq|geq|neq|approx|alpha|beta|theta|pi|sum|int|lim|log|sin|cos|tan|begin|end|left|right|over)|[\^_][\{0-9a-zA-Z]',
    ).hasMatch(line);

    if (hasBareLaTeX) {
      // Treat entire line as math
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(
          line,
          textStyle: textStyle ?? const TextStyle(fontSize: 16),
        ),
      );
    }

    // No explicit $...$ delimiters — handle **bold** and render as text
    return _buildTextWithBold(line);
  }

  /// Handles **bold** markdown and renders as text using Wrap for inline layout.
  Widget _buildTextWithBold(String text) {
    final RegExp boldExp = RegExp(r'\*\*(.*?)\*\*');
    if (!boldExp.hasMatch(text)) {
      return Text(
        text,
        style:
            textStyle ??
            const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      );
    }

    final List<InlineSpan> spans = [];
    text.splitMapJoin(
      boldExp,
      onMatch: (m) {
        spans.add(
          TextSpan(
            text: m.group(1) ?? '',
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
            TextSpan(
              text: n,
              style:
                  textStyle ??
                  const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
          );
        }
        return '';
      },
    );

    return RichText(text: TextSpan(children: spans));
  }
}

class HorizontalMathText extends StatelessWidget {
  final String content;

  const HorizontalMathText({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: MixedMathText(
        content: content,
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }
}
