import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/services/auth_service.dart';
import 'package:punca_ai/features/student/profile/widgets/focus_area_card.dart';
import 'package:punca_ai/features/student/profile/widgets/mastery_grid.dart';
import 'package:punca_ai/features/teacher/teacher_scaffold.dart';
import 'package:punca_ai/core/services/firebase_service.dart'; // Added
import 'package:punca_ai/core/constants/kssm_syllabus.dart';
import 'dart:math';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _selectedSubject = "Math";
  final List<String> _availableSubjects = [
    "Math",
    "Science",
    "English",
    "History",
  ];
  Map<String, double?> _masteryData = {}; // Nullable for NA support
  bool _isLoading = false;
  bool _isDemoMode = true; // Default to Demo Mode

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isDemoMode) {
      await _loadMockData();
    } else {
      await _loadLiveData();
    }
  }

  Future<void> _loadLiveData() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Use FirebaseService to get REAL stats (which now supports ID-based robust matching)
      final data = await FirebaseService().getMasteryStats(
        user.uid,
        subject: _selectedSubject,
      );

      if (mounted) {
        setState(() {
          _masteryData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading live data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMockData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    Map<String, double?> data = {};

    if (_selectedSubject == "Math") {
      // Mock Math Data from Syllabus (Form 1 & 2)
      final random = Random();
      KssmSyllabus.structure.forEach((form, chapters) {
        if (form <= 2) {
          for (var chap in chapters) {
            final key =
                "F$form C${chap.id.toString().padLeft(2, '0')}: ${chap.title}";
            // Random mastery between 0% and 100%, biased towards 30-80%
            double? mastery;
            // Simulate that first few chapters are done
            if (form == 1 && chap.id <= 5) {
              mastery = 0.5 + (random.nextDouble() * 0.4); // 50-90%
            } else if (form == 1) {
              mastery = 0.2 + (random.nextDouble() * 0.4); // 20-60%
            } else {
              mastery = null; // Not started (NA)
            }
            data[key] = mastery;
          }
        }
      });
    } else {
      // Generic mock for other subjects
      data = {
        "Chapter 1: Basics": 0.85,
        "Chapter 2: Intermediate": 0.60,
        "Chapter 3: Advanced": null, // NA example
      };
    }

    if (mounted) {
      setState(() {
        _masteryData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header with Toggle
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Student Profile",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          AuthService().currentUser?.email ??
                              "student@example.com",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Demo Toggle
                Column(
                  children: [
                    Switch(
                      value: _isDemoMode,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _isDemoMode = val);
                        _loadData();
                      },
                    ),
                    Text(
                      _isDemoMode ? "DEMO" : "LIVE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _isDemoMode ? AppColors.primary : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Subject Filter Dropdown
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  hint: const Text("Select Subject"),
                  isExpanded: true,
                  items: _availableSubjects.map((String subject) {
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Text(
                        subject,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSubject = newValue;
                    });
                    _loadData(); // Reload data on change
                  },
                ),
              ),
            ),
          ),
        ),

        // Focus Area (Hide if loading or empty)
        if (!_isLoading && _masteryData.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                _selectedSubject != null ? "Focus Chapter" : "Your Focus Area",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

        // Pass only NON-NULL data for Focus Area Calculation
        if (!_isLoading && _masteryData.isNotEmpty)
          // We filter out nulls for the Focus Card to avoid errors
          FocusAreaCard(
            masteryData: {
              for (var k in _masteryData.keys)
                if (_masteryData[k] != null) k: _masteryData[k]!,
            },
          )
        else if (_isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: LinearProgressIndicator()),
            ),
          ),

        // Mastery Grid Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(
              _selectedSubject == "Math" ? "KSSM Roadmap" : "Topic Mastery",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        // Grid
        if (!_isLoading)
          MasteryGrid(masteryData: _masteryData)
        else
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Placeholder
        // Settings / Demo Buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherScaffold(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.school_outlined),
                  label: const Text("Demo: Switch to Teacher View"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    AuthService().signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Sign Out"),
                ),
                const SizedBox(height: 40), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }
}
