import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'info_item.dart';

class ExtraInfoSection extends StatelessWidget {
  final String rating;
  final String photoCount;
  final String activityType;

  const ExtraInfoSection({
    super.key,
    required this.rating,
    required this.photoCount,
    required this.activityType,
  });

  @override
  Widget build(BuildContext context) {
    final activityIcon = _iconForActivity(activityType);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InfoItem(
              icon: Icons.star_rate,
              value: rating,
              label: 'rating'.tr(),
            ),
            InfoItem(
              icon: Icons.photo_library,
              value: photoCount,
              label: 'photos'.tr(),
            ),
            InfoItem(
              icon: activityIcon,
              value: _translateActivity(activityType),
              label: 'activity'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForActivity(String value) {
    switch (value) {
      case 'Caminhada':
      case 'hiking':
        return Icons.directions_walk;
      case 'Contemplação':
      case 'contemplation':
        return Icons.visibility;
      case 'Aventura':
      case 'adventure':
        return Icons.landscape;
      case 'Cultural':
      case 'cultural':
        return Icons.museum;
      default:
        return Icons.place;
    }
  }

  String _translateActivity(String value) {
    switch (value) {
      case 'Caminhada':
      case 'hiking':
        return 'hiking'.tr();
      case 'Contemplação':
      case 'contemplation':
        return 'contemplation'.tr();
      case 'Aventura':
      case 'adventure':
        return 'adventure'.tr();
      case 'Cultural':
      case 'cultural':
        return 'cultural'.tr();
    }
    return value;
  }
}
