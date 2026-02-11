import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';

class MasteryGrid extends StatelessWidget {
  final Map<String, double> masteryData;

  const MasteryGrid({super.key, required this.masteryData});

  @override
  Widget build(BuildContext context) {
    if (masteryData.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No data yet. Complete assessments to see your mastery!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Sort by mastery (lowest first? or alphabetical? plan didn't specify, let's do Alphabetical for grid)
    final sortedKeys = masteryData.keys.toList()..sort();

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 columns
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5, // rectangular cards
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final topic = sortedKeys[index];
          final mastery = masteryData[topic]!;
          return _buildMasteryCard(topic, mastery);
        }, childCount: sortedKeys.length),
      ),
    );
  }

  Widget _buildMasteryCard(String topic, double mastery) {
    // Determine color based on mastery
    Color batteryColor;
    if (mastery >= 0.8) {
      batteryColor = Colors.greenAccent[700]!;
    } else if (mastery >= 0.5) {
      batteryColor = Colors.orangeAccent;
    } else {
      batteryColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            topic,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.battery_charging_full,
                    size: 16,
                    color: Colors.grey,
                  ),
                  Text(
                    "${(mastery * 100).toInt()}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: batteryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: mastery,
                  backgroundColor: Colors.grey[200],
                  color: batteryColor,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
