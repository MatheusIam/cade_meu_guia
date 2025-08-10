import 'package:flutter/material.dart';
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
    IconData activityIcon;
    switch (activityType) {
      case 'Caminhada':
        activityIcon = Icons.directions_walk;
        break;
      case 'Contemplação':
        activityIcon = Icons.visibility;
        break;
      case 'Aventura':
        activityIcon = Icons.landscape;
        break;
      case 'Cultural':
        activityIcon = Icons.museum;
        break;
      default:
        activityIcon = Icons.place;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InfoItem(
              icon: Icons.star_rate,
              value: rating,
              label: 'Avaliações',
            ),
            InfoItem(
              icon: Icons.photo_library,
              value: photoCount,
              label: 'Fotos',
            ),
            InfoItem(
              icon: activityIcon,
              value: activityType,
              label: 'Atividade',
            ),
          ],
        ),
      ),
    );
  }
}
