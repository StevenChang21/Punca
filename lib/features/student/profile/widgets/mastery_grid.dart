import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';

class MasteryGrid extends StatelessWidget {
  final Map<String, double?> masteryData;

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

    final sortedKeys = masteryData.keys.toList()..sort();

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final topic = sortedKeys[index];
          final mastery = masteryData[topic];
          return _buildMasteryCard(topic, mastery);
        }, childCount: sortedKeys.length),
      ),
    );
  }

  Widget _buildMasteryCard(String topic, double? mastery) {
    // Determine color based on mastery
    Color statusColor;
    String statusText;
    double progressValue;
    IconData statusIcon;

    if (mastery == null) {
      statusColor = Colors.grey;
      statusText = "NA";
      progressValue = 0.0;
      statusIcon = Icons.circle_outlined;
    } else if (mastery >= 0.8) {
      statusColor = Colors.greenAccent[700]!;
      statusText = "${(mastery * 100).toInt()}%";
      progressValue = mastery;
      statusIcon = Icons.battery_charging_full;
    } else if (mastery >= 0.5) {
      statusColor = Colors.orangeAccent;
      statusText = "${(mastery * 100).toInt()}%";
      progressValue = mastery;
      statusIcon = Icons.battery_alert;
    } else {
      statusColor = Colors.redAccent;
      statusText = "${(mastery * 100).toInt()}%";
      progressValue = mastery;
      statusIcon = Icons.battery_0_bar;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14, // Slightly smaller to fit long names
              color: mastery == null ? Colors.grey : AppColors.textPrimary,
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
                  Icon(statusIcon, size: 16, color: statusColor),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.grey[100],
                  color: statusColor,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
