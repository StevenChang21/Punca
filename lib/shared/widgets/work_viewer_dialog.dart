import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Reusable dialog to display student work (images or PDFs).
/// Handles local file paths, network image URLs, and network PDF URLs.
void showWorkViewerDialog(BuildContext context, List<String> paths) {
  final bool hasPdf = paths.any((p) => p.toLowerCase().contains('.pdf'));

  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: hasPdf ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Original Work (${paths.length} ${hasPdf ? 'file' : 'pages'})",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: hasPdf
                ? _PdfViewerWidget(path: paths.first)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: paths.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImageWidget(paths[index]),
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

Widget _buildImageWidget(String path) {
  if (path.startsWith('http')) {
    return Image.network(
      path,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stack) => const SizedBox(
        height: 200,
        child: Center(child: Text('Failed to load image')),
      ),
    );
  }
  return Image.file(File(path), fit: BoxFit.contain);
}

/// Stateful widget to handle PDF loading (especially downloading network PDFs)
class _PdfViewerWidget extends StatefulWidget {
  final String path;
  const _PdfViewerWidget({required this.path});

  @override
  State<_PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<_PdfViewerWidget> {
  String? _localPath;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    if (!widget.path.startsWith('http')) {
      // Already a local file
      setState(() {
        _localPath = widget.path;
        _loading = false;
      });
      return;
    }

    // Download network PDF to temp
    try {
      final response = await http.get(Uri.parse(widget.path));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp_student_work.pdf');
      await file.writeAsBytes(response.bodyBytes);
      if (mounted) {
        setState(() {
          _localPath = file.path;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load PDF: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: true,
      pageFling: true,
    );
  }
}
