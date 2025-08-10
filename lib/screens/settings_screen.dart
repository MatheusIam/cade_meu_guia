import 'package:flutter/material.dart';
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
        title: const Text('Configurações'),
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
        ],
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
                  'Aparência',
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
                      title: const Text('Claro'),
                      subtitle: const Text('Sempre usar tema claro'),
                      value: ThemeMode.light,
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Escuro'),
                      subtitle: const Text('Sempre usar tema escuro'),
                      value: ThemeMode.dark,
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Sistema'),
                      subtitle: const Text('Seguir configuração do sistema'),
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
                        'Cores do tema',
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
                  'Favoritos',
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
                      title: const Text('Total de favoritos'),
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
                        title: const Text('Limpar todos os favoritos'),
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
                  'Estatísticas',
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
              'Total de pontos turísticos',
              stats['totalPoints'].toString(),
            ),
            const Divider(),
            _buildStatItem(
              context,
              Icons.check_circle,
              'Pontos visitados (avaliados)',
              ratingsProvider.visitedCount.toString(),
            ),
            const Divider(),
            _buildStatItem(
              context,
              Icons.star,
              'Avaliação média',
              '${stats['averageRating']}/5.0',
            ),
            const Divider(),
            _buildStatItem(
              context,
              Icons.photo_library,
              'Total de fotos',
              stats['totalPhotos'].toString(),
            ),
            const Divider(),
            _buildStatItem(
              context,
              Icons.thumb_up,
              'Melhor avaliado',
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
                  'Sobre o App',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('Nome do aplicativo'),
              subtitle: Text(AppConstants.appName),
            ),
            ListTile(
              leading: const Icon(Icons.numbers),
              title: const Text('Versão'),
              subtitle: Text(AppConstants.appVersion),
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('Foco'),
              subtitle: const Text('Pontos turísticos de Boa Vista - RR'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Desenvolvido com'),
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
        title: const Text('Limpar Favoritos'),
        content: const Text(
          'Tem certeza que deseja remover todos os pontos turísticos dos favoritos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<FavoritesProvider>(context, listen: false)
                  .clearAllFavorites();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todos os favoritos foram removidos'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Confirmar'),
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
