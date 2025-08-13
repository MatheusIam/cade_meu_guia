import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/ratings_provider.dart';
import '../constants/app_constants.dart';
import '../data/tour_points_data.dart';

/// Tela de configurações e informações do app
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings_page'.tr()),
        // herda do AppBarTheme para contraste adequado
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildThemeSection(context),
          const SizedBox(height: 24),
          _buildFavoritesSection(context),
          const SizedBox(height: 24),
          _buildStatisticsSection(context),
          const SizedBox(height: 24),
          _buildAboutSection(context),
          const SizedBox(height: 24),
          _buildLanguageSection(context),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    final current = context.locale.languageCode;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text('change_language'.tr(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: current,
              onChanged: (val) {
                if (val != null) context.setLocale(const Locale('en'));
              },
            ),
            RadioListTile<String>(
              title: const Text('Português'),
              value: 'pt',
              groupValue: current,
              onChanged: (val) {
                if (val != null) context.setLocale(const Locale('pt'));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'appearance'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text('light_theme'.tr()),
                      subtitle: const Text(''),
                      value: ThemeMode.light,
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('dark_theme'.tr()),
                      subtitle: const Text(''),
                      value: ThemeMode.dark,
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('system_theme'.tr()),
                      subtitle: const Text(''),
                      value: ThemeMode.system,
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'theme_colors'.tr(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SeedColorSelector(
                      current: themeProvider.seedColor,
                      onSelect: (c) => themeProvider.setSeedColor(c),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                    'favorites'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<FavoritesProvider>(
              builder: (context, favoritesProvider, child) {
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.favorite_border),
                      title: Text('total_favorites'.tr()),
                      trailing: Text(
                        favoritesProvider.favoritesCount.toString(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    if (favoritesProvider.favoritesCount > 0)
                      ListTile(
                        leading: const Icon(Icons.clear_all),
                        title: Text('clear_all_favorites'.tr()),
                        onTap: () => _showClearFavoritesDialog(context),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    final stats = TourPointsData.getStatistics();
  final ratingsProvider = Provider.of<RatingsProvider>(context, listen: true);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                    'statistics'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              context,
              Icons.location_on,
              'tour_points_total'.tr(),
              stats['totalPoints'].toString(),
            ),
            const Divider(),
            _buildStatItem(
              context,
              Icons.check_circle,
              'visited_points'.tr(),
              ratingsProvider.visitedCount.toString(),
            ),
            const Divider(),
            _buildStatItem(
              context,
              Icons.star,
              'average_rating'.tr(),
              '${stats['averageRating']}/5.0',
            ),
            const Divider(),
            _buildStatItem(
              context,
              Icons.photo_library,
              'total_photos'.tr(),
              stats['totalPhotos'].toString(),
            ),
            const Divider(),
            _buildStatItem(
              context,
              Icons.thumb_up,
              'best_rated'.tr(),
              stats['highestRated'].name,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                    'about_app'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.apps),
              title: Text('app_name_label'.tr()),
              subtitle: Text(AppConstants.appName),
            ),
            ListTile(
              leading: const Icon(Icons.numbers),
              title: Text('app_version'.tr()),
              subtitle: Text(AppConstants.appVersion),
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: Text('focus'.tr()),
              subtitle: const Text('Pontos turísticos de Boa Vista - RR'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text('developed_with'.tr()),
              subtitle: const Text('Flutter & Dart'),
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
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showClearFavoritesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text('clear_favorites_title'.tr()),
            content: Text(
              'clear_favorites_message'.tr(),
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Provider.of<FavoritesProvider>(context, listen: false)
                  .clearAllFavorites();
              Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('all_favorites_removed'.tr()),
                      duration: const Duration(seconds: 2),
                    ),
                  );
            },
                child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }
}

class _SeedColorSelector extends StatelessWidget {
  final Color current;
  final ValueChanged<Color> onSelect;
  const _SeedColorSelector({required this.current, required this.onSelect});

  static const List<Color> _palette = [
    Colors.orange,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.red,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final color in _palette)
          _ColorChip(
            color: color,
            selected: color.value == current.value,
            onTap: () => onSelect(color),
          ),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorChip({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: selected ? Theme.of(context).colorScheme.onPrimary : Colors.grey.shade400, width: selected ? 3 : 1);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: border,
          boxShadow: [
            if (selected)
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: selected
            ? Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary)
            : null,
      ),
    );
  }
}
