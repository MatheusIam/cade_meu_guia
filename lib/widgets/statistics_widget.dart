import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/tour_points_data.dart';

class StatisticsWidget extends StatelessWidget {
  const StatisticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = TourPointsData.getStatistics();
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'tour_points_statistics'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.location_on,
                    'tour_points_total'.tr(),
                    stats['totalPoints'].toString(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.star,
                    'average_rating'.tr(),
                    stats['averageRating'].toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.photo_library,
                    'total_photos'.tr(),
                    stats['totalPhotos'].toString(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.thumb_up,
                    'best_rated'.tr(),
                    stats['highestRated'].name,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
