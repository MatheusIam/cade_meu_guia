import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/ratings_provider.dart';
import '../constants/app_constants.dart';
import '../providers/tour_points_provider.dart';

/// Tela de configurações e informações do app
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableHaptics = true;
  bool _autoSync = false;
  bool _reduceMotion = false;
  bool _experimentalMapPerf = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings_page'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel(context, Icons.palette, 'appearance'.tr()),
          _buildThemeSection(context),
          const SizedBox(height: 24),
          _sectionLabel(context, Icons.language, 'change_language'.tr()),
          _buildLanguageSection(context),
          const SizedBox(height: 24),
          _sectionLabel(context, Icons.favorite, 'favorites'.tr()),
          _buildFavoritesSection(context),
          const SizedBox(height: 24),
          _sectionLabel(context, Icons.analytics, 'statistics'.tr()),
          _buildStatisticsSection(context),
          const SizedBox(height: 24),
          _sectionLabel(context, Icons.tune, 'preferences'.tr()),
          _buildPreferencesSection(context),
          const SizedBox(height: 24),
          _sectionLabel(context, Icons.shield, 'privacy_security'.tr()),
          _buildPrivacySection(context),
          const SizedBox(height: 24),
          _sectionLabel(context, Icons.speed, 'performance'.tr()),
          _buildPerformanceSection(context),
          const SizedBox(height: 24),
          _sectionLabel(context, Icons.info, 'about_app'.tr()),
          _buildAboutSection(context),
          const SizedBox(height: 24),
          _sectionLabel(context, Icons.settings_backup_restore, 'backup_reset'.tr()),
          _buildDataSection(context),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'app_version'.tr() + ': ' + AppConstants.appVersion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    final current = context.locale.languageCode;
    return Card(
      child: Column(
        children: [
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: current,
            onChanged: (val) { if (val!=null) context.setLocale(const Locale('en')); },
          ),
          RadioListTile<String>(
            title: const Text('Português'),
            value: 'pt',
            groupValue: current,
            onChanged: (val) { if (val!=null) context.setLocale(const Locale('pt')); },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Card(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => Column(
          children: [
            RadioListTile<ThemeMode>(
              title: Text('light_theme'.tr()),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (v){ if(v!=null) themeProvider.setThemeMode(v); },
            ),
            RadioListTile<ThemeMode>(
              title: Text('dark_theme'.tr()),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (v){ if(v!=null) themeProvider.setThemeMode(v); },
            ),
            RadioListTile<ThemeMode>(
              title: Text('system_theme'.tr()),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (v){ if(v!=null) themeProvider.setThemeMode(v); },
            ),
            const Divider(height: 0),
            ListTile(
              title: Text('theme_colors'.tr(), style: Theme.of(context).textTheme.titleMedium),
              subtitle: Padding(
                padding: const EdgeInsets.only(top:8.0),
                child: _SeedColorSelector(
                  current: themeProvider.seedColor,
                  onSelect: (c)=> themeProvider.setSeedColor(c),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesSection(BuildContext context) {
    return Card(
      child: Consumer<FavoritesProvider>(
        builder: (context, fav, _) => Column(
          children: [
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: Text('total_favorites'.tr()),
              trailing: Text(fav.favoritesCount.toString(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ),
            if (fav.favoritesCount > 0)
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: Text('clear_all_favorites'.tr()),
                onTap: () => _showClearFavoritesDialog(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
  final stats = context.watch<TourPointsProvider>().getStatistics();
  final ratingsProvider = Provider.of<RatingsProvider>(context, listen: true);
    return Card(
      child: Column(
        children: [
          _buildStatItem(context, Icons.location_on, 'tour_points_total'.tr(), stats['totalPoints'].toString()),
          const Divider(height: 0),
          _buildStatItem(context, Icons.check_circle, 'visited_points'.tr(), ratingsProvider.visitedCount.toString()),
          const Divider(height: 0),
          _buildStatItem(context, Icons.star, 'average_rating'.tr(), '${stats['averageRating']}/5.0'),
          const Divider(height: 0),
          _buildStatItem(context, Icons.photo_library, 'total_photos'.tr(), stats['totalPhotos'].toString()),
          const Divider(height: 0),
          _buildStatItem(context, Icons.thumb_up, 'best_rated'.tr(), stats['highestRated'].name),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.apps),
            title: Text('app_name_label'.tr()),
            subtitle: Text(AppConstants.appName),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.numbers),
            title: Text('app_version'.tr()),
            subtitle: Text(AppConstants.appVersion),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.location_city),
            title: Text('focus'.tr()),
            subtitle: const Text('Pontos turísticos de Boa Vista - RR'),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text('developed_with'.tr()),
            subtitle: const Text('Flutter & Dart'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            value: _enableHaptics,
            onChanged: (v)=> setState(()=> _enableHaptics = v),
            secondary: const Icon(Icons.vibration),
            title: Text('pref_haptics'.tr()),
            subtitle: Text('pref_haptics_desc'.tr()),
          ),
          const Divider(height: 0),
          SwitchListTile(
            value: _autoSync,
            onChanged: (v)=> setState(()=> _autoSync = v),
            secondary: const Icon(Icons.sync),
            title: Text('pref_auto_sync'.tr()),
            subtitle: Text('pref_auto_sync_desc'.tr()),
          ),
          const Divider(height: 0),
          SwitchListTile(
            value: _reduceMotion,
            onChanged: (v)=> setState(()=> _reduceMotion = v),
            secondary: const Icon(Icons.motion_photos_off),
            title: Text('pref_reduce_motion'.tr()),
            subtitle: Text('pref_reduce_motion_desc'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text('privacy_policy'.tr()),
            subtitle: Text('privacy_policy_desc'.tr()),
            onTap: () {/* abrir url futura */},
          ),
          const Divider(height: 0),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            secondary: const Icon(Icons.location_on),
            title: Text('privacy_location'.tr()),
            subtitle: Text('privacy_location_desc'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            value: _experimentalMapPerf,
            onChanged: (v)=> setState(()=> _experimentalMapPerf = v),
            secondary: const Icon(Icons.rocket_launch_outlined),
            title: Text('perf_experimental_map'.tr()),
            subtitle: Text('perf_experimental_map_desc'.tr()),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.storage_rounded),
            title: Text('cache_size'.tr()),
            subtitle: const Text('~0.5 MB'),
            trailing: TextButton(
              onPressed: (){},
              child: Text('clear'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text('export_data'.tr()),
            subtitle: Text('export_data_desc'.tr()),
            onTap: (){},
          ),
          const Divider(height: 0),
            ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: Text('import_data'.tr()),
            subtitle: Text('import_data_desc'.tr()),
            onTap: (){},
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: Text('reset_app'.tr()),
            subtitle: Text('reset_app_desc'.tr()),
            onTap: ()=> _confirmReset(context),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context){
    showDialog(context: context, builder: (ctx)=> AlertDialog(
      title: Text('reset_app'.tr()),
      content: Text('reset_app_confirm'.tr()),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: Text('cancel'.tr())),
        FilledButton(onPressed: (){ Navigator.pop(ctx); /* TODO limpar dados */ }, child: Text('confirm'.tr())),
      ],
    ));
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label, String value){
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
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
