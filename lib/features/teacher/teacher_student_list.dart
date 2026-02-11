import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/teacher/student_detail_screen.dart';

class TeacherStudentList extends StatelessWidget {
  const TeacherStudentList({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data: Full Class Roster
    final students = [
      {
        "name": "Alex Johnson",
        "issue": "Failed Linear Equations I",
        "score": "42%",
        "grade": "F",
        "color": Colors.red,
      },
      {
        "name": "Alice Wong",
        "issue": "Excellent Progress",
        "score": "95%",
        "grade": "A+",
        "color": Colors.green,
      },
      {
        "name": "Brandon Tan",
        "issue": "Struggling with Geometry",
        "score": "58%",
        "grade": "D",
        "color": Colors.orange,
      },
      {
        "name": "Chloe Lim",
        "issue": "Consistent Performance",
        "score": "78%",
        "grade": "B",
        "color": Colors.blue,
      },
      {
        "name": "Daniel Kumar",
        "issue": "Missed Homework",
        "score": "65%",
        "grade": "C",
        "color": Colors.yellow[700],
      },
      {
        "name": "Elena Rodriguez",
        "issue": "Top of Class",
        "score": "98%",
        "grade": "A+",
        "color": Colors.green[800],
      },
      {
        "name": "Farid Azman",
        "issue": "Improving",
        "score": "72%",
        "grade": "B-",
        "color": Colors.blue[300],
      },
      {
        "name": "Grace Lee",
        "issue": "Needs Extra Help (Algebra)",
        "score": "45%",
        "grade": "F",
        "color": Colors.redAccent,
      },
      {
        "name": "Henry Cavill",
        "issue": "Solid Understanding",
        "score": "88%",
        "grade": "A",
        "color": Colors.green,
      },
      {
        "name": "Isabella Chen",
        "issue": "Average",
        "score": "60%",
        "grade": "C-",
        "color": Colors.yellow[800],
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: students.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = students[index];
        final color = student['color'] as Color;
        // Ensure student map has String keys and values for Detail Screen,
        // converting specific types if needed or just passing mostly strings.
        // StudentDetailScreen expects Map<String, String>.

        final studentDataForDetail = {
          "name": student['name'].toString(),
          "issue": student['issue'].toString(),
          "score": student['score'].toString(),
        };

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentDetailScreen(student: studentDataForDetail),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 24,
              child: Text(
                student["grade"].toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              student["name"].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                student["issue"].toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student["score"].toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
