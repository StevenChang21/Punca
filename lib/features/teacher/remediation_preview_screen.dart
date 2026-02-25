import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'package:punca_ai/core/models/assignment_model.dart';
import 'package:punca_ai/core/services/auth_service.dart';
import 'package:punca_ai/core/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

class RemediationPreviewScreen extends StatefulWidget {
  final Map<String, String> student;
  final String topic;
  final RemediationDrill initialDrill;
  final String? classroomId;

  const RemediationPreviewScreen({
    super.key,
    required this.student,
    required this.topic,
    required this.initialDrill,
    this.classroomId,
  });

  @override
  State<RemediationPreviewScreen> createState() =>
      _RemediationPreviewScreenState();
}

class _RemediationPreviewScreenState extends State<RemediationPreviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _lessonCtrl;
  late TextEditingController _questionCtrl;

  late List<TextEditingController> _optionCtrls;
  int _correctOptionIndex = 0;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialDrill.title);
    _lessonCtrl = TextEditingController(text: widget.initialDrill.miniLesson);
    _questionCtrl = TextEditingController(
      text: widget.initialDrill.twinQuestion,
    );

    // Setup options
    _optionCtrls = [];
    for (int i = 0; i < 4; i++) {
      String optText = i < widget.initialDrill.options.length
          ? widget.initialDrill.options[i]
          : '';
      _optionCtrls.add(TextEditingController(text: optText));

      // Attempt to match the correct option index
      if (optText.isNotEmpty && optText == widget.initialDrill.correctAnswer) {
        _correctOptionIndex = i;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _lessonCtrl.dispose();
    _questionCtrl.dispose();
    for (var ctrl in _optionCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _assignDrill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final finalOptions = _optionCtrls.map((c) => c.text.trim()).toList();
      final finalCorrectAnswer = finalOptions[_correctOptionIndex];

      final editedDrill = RemediationDrill(
        title: _titleCtrl.text.trim(),
        miniLesson: _lessonCtrl.text.trim(),
        twinQuestion: _questionCtrl.text.trim(),
        options: finalOptions,
        correctAnswer: finalCorrectAnswer,
        vocabularyBridge: widget.initialDrill.vocabularyBridge,
        weaknessId: widget.initialDrill.weaknessId,
      );

      final teacherId = AuthService().currentUser?.uid ?? 'unknown_teacher';

      // Keep only non-empty classroomIds
      final String? assignedClassroomId =
          (widget.classroomId != null && widget.classroomId!.isNotEmpty)
          ? widget.classroomId
          : null;

      final assignment = Assignment(
        id: const Uuid().v4(),
        studentId: widget.student['id']!,
        teacherId: teacherId,
        classroomId: assignedClassroomId,
        assignedDate: DateTime.now(),
        topic: widget.topic,
        weaknessId: widget.topic, // using topic as weakness identifier for now
        remediationDrill: editedDrill,
        status: 'pending',
      );

      await FirebaseService().createAssignment(assignment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully assigned to ${widget.student['name']}'),
          ),
        );
        Navigator.pop(context); // Go back to student detail
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error assigning drill: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Assignment"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Review & Edit AI Gen Content",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You can adjust the lesson text, question, and options before assigning to the student.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: "Drill Title",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Lesson
            TextFormField(
              controller: _lessonCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: "Mini Lesson (Markdown/LaTeX supported)",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Question
            TextFormField(
              controller: _questionCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Question text",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            const Text(
              "Multiple Choice Options",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _correctOptionIndex,
                      onChanged: (val) {
                        setState(() => _correctOptionIndex = val!);
                      },
                      activeColor: Colors.green,
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _optionCtrls[index],
                        decoration: InputDecoration(
                          labelText: "Option ${index + 1}",
                          border: const OutlineInputBorder(),
                          filled: _correctOptionIndex == index,
                          fillColor: _correctOptionIndex == index
                              ? Colors.green.withValues(alpha: 0.1)
                              : null,
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _assignDrill,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSaving
                      ? "Assigning..."
                      : "Assign to ${widget.student['name']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
