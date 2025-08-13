import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/tour_point.dart';
import '../data/tour_points_data.dart';
import '../widgets/widgets.dart';
import 'tour_point_screen.dart';
import '../providers/favorites_provider.dart';
import 'settings_screen.dart';
import 'add_tour_point_screen.dart';
import '../providers/ratings_provider.dart';

/// Tela inicial com mapa principal e navegação
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  int _selectedIndex = 0;
  List<TourPoint> _tourPoints = [];
  List<TourPoint> _filteredTourPoints = [];
  String _selectedCategory = 'Todos'; // manter valor interno PT para compat c/ dados; mapear para chaves na UI
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTourPoints();
  }

  void _loadTourPoints() {
    _tourPoints = TourPointsData.getAllTourPoints();
    _filteredTourPoints = _tourPoints;
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _searchTourPoints(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<TourPoint> filtered = _tourPoints;

    // Aplicar filtro de categoria (inclui pseudo-categoria Visitados)
    if (_selectedCategory != 'Todos') {
      if (_selectedCategory == 'Visitados') {
        final ratingsProvider = Provider.of<RatingsProvider>(context, listen: false);
        filtered = filtered.where((p) => ratingsProvider.isTourPointVisited(p.id)).toList();
      } else {
        filtered = filtered.where((point) => point.activityType == _selectedCategory).toList();
      }
    }

    // Aplicar filtro de busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((point) {
        return point.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               point.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               point.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               point.activityType.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    _filteredTourPoints = filtered;
  }

  IconData _iconForActivity(String type) {
    switch (type) {
      case 'Caminhada':
        return Icons.directions_walk;
      case 'Contemplação':
        return Icons.visibility;
      case 'Aventura':
        return Icons.landscape;
      case 'Cultural':
        return Icons.museum;
      default:
        return Icons.place;
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'Todos';
      _searchQuery = '';
      _filteredTourPoints = _tourPoints;
    });
  }

  String _getFilterSummary() {
    List<String> filters = [];
    
    if (_selectedCategory != 'Todos') {
      filters.add(_selectedCategory);
    }
    
    if (_searchQuery.isNotEmpty) {
      filters.add('"$_searchQuery"');
    }
    
    String summary = filters.join(' • ');
    return '${_filteredTourPoints.length} ponto(s) - $summary';
  }

  String _localizedCategory(String category) {
    switch (category) {
      case 'Todos': return 'all'.tr();
      case 'Caminhada': return 'hiking'.tr();
      case 'Contemplação': return 'contemplation'.tr();
      case 'Aventura': return 'adventure'.tr();
      case 'Cultural': return 'cultural'.tr();
      case 'Visitados': return 'visited'.tr();
    }
    return category;
  }

  void _onMarkerTapped(TourPoint tourPoint) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TourPointScreen(tourPoint: tourPoint),
      ),
    );
  }

  void _centerMapOnLocation(LatLng location) {
    _mapController.move(location, 15.0);
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Mapa - já estamos na tela principal
        break;
  case 1:
        _showFavoritesBottomSheet();
        break;
      case 2:
        _showSearchBottomSheet();
        break;
    }
  }

  void _showFavoritesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(icon: const Icon(Icons.favorite), text: 'favorites'.tr()),
                          Tab(icon: const Icon(Icons.eco), text: 'preservation'.tr()),
                        ],
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildFavoritesTab(scrollController),
                            _buildPreservationOverviewTab(scrollController),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesTab(ScrollController scrollController) {
    // Usa Consumer para reagir a mudanças nos favoritos
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isLoaded = favoritesProvider.isLoaded;
        final favoritePoints = favoritesProvider.getFavoriteTourPoints();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'favorite_points'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (favoritePoints.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${favoritePoints.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  if (favoritePoints.length > 1)
                    IconButton(
                      tooltip: 'clear_all'.tr(),
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('clear_favorites_title'.tr()),
                            content: Text('clear_favorites_question_short'.tr()),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('clear'.tr())),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await favoritesProvider.clearAllFavorites();
                        }
                      },
                    ),
                ],
              ),
            ),
            if (!isLoaded)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (favoritePoints.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'none_favorite_yet'.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'add_favorite_hint'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: favoritePoints.length,
                  itemBuilder: (context, index) {
                    final point = favoritePoints[index];
                    final isFav = favoritesProvider.isFavorite(point.id);
                    return Dismissible(
                      key: ValueKey('fav-${point.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await favoritesProvider.removeFavorite(point.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${point.name} ${'removed_from_favorites'.tr()}'),
                            action: SnackBarAction(
                              label: 'Desfazer',
                              onPressed: () async {
                                await favoritesProvider.addFavorite(point.id);
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.location_on, color: Colors.white),
                          ),
                          title: Text(point.name),
                          subtitle: Text(point.title),
                          trailing: IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Theme.of(context).iconTheme.color,
                            ),
                            onPressed: () async {
                              await favoritesProvider.toggleFavorite(point);
                            },
                            tooltip: isFav ? 'remove_from_favorites'.tr() : 'add_to_favorites'.tr(),
                          ),
                          onTap: () {
                            Navigator.pop(context); // Fecha o bottom sheet
                            _onMarkerTapped(point);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPreservationOverviewTab(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'sustainable_tourism'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'sustainable_tourism_desc'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          PreservationWidget(showAllTips: false),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.eco,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'together_preservation'.tr(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'together_preservation_desc'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildPreservationStat('🌱', '15', 'tips'.tr()),
                            _buildPreservationStat('🏛️', '8', 'points'.tr()),
                            _buildPreservationStat('👥', '100+', 'tourists'.tr()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showPreservationDialog();
                  },
                  icon: const Icon(Icons.visibility),
                  label: Text('see_all_tips'.tr()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreservationStat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
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
        ),
      ],
    );
  }

  void _showPreservationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text('preservation_guide'.tr()),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            actions: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: PreservationWidget(showAllTips: true),
          ),
        ),
      ),
    );
  }

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'explore_points'.tr(),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'search_points_hint'.tr(),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          _searchTourPoints(value);
                          setModalState(() {}); // Atualiza o modal
                        },
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'Todos', // valores internos
                            'Caminhada',
                            'Contemplação',
                            'Aventura',
                            'Cultural'
                          ].map((category) {
                            final isSelected = category == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(_localizedCategory(category)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  _filterByCategory(category);
                                  setModalState(() {}); // Atualiza o modal sem fechar
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'points_found'.tr(namedArgs: {'count': _filteredTourPoints.length.toString()}),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_selectedCategory != 'Todos' || _searchQuery.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                _clearFilters();
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.clear, size: 16),
                              label: Text('clear'.tr()),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredTourPoints.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'no_points_found'.tr(),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'try_adjust_filters'.tr(),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Consumer<FavoritesProvider>(
                          builder: (context, favoritesProvider, child) => ListView.builder(
                          controller: scrollController,
                          itemCount: _filteredTourPoints.length,
                          itemBuilder: (context, index) {
                            final point = _filteredTourPoints[index];
                            final isFav = favoritesProvider.isFavorite(point.id);
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: Text(
                                    point.rating.toStringAsFixed(2),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  point.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      point.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          _iconForActivity(point.activityType),
                                          size: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            point.activityType,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.photo_library,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'photos_count'.tr(namedArgs:{'count': point.photoCount.toString()}),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _CompactIconButton(
                                      icon: Icons.center_focus_strong,
                                      tooltip: 'center_on_map'.tr(),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _centerMapOnLocation(point.location);
                                      },
                                    ),
                                    _CompactIconButton(
                                      icon: Icons.info_outline,
                                      tooltip: 'view_details'.tr(),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _onMarkerTapped(point);
                                      },
                                    ),
                                    _CompactIconButton(
                                      icon: isFav ? Icons.favorite : Icons.favorite_border,
                                      color: isFav ? Colors.red : null,
                                      tooltip: isFav ? 'remove_from_favorites'.tr() : 'add_to_favorites'.tr(),
                                      onTap: () async {
                                        await favoritesProvider.toggleFavorite(point);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('app_name'.tr()),
            if (_selectedCategory != 'Todos' || _searchQuery.isNotEmpty)
              Text(
                _getFilterSummary(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
    // Usa AppBarTheme para melhor contraste no tema claro
    backgroundColor: Theme.of(context).brightness == Brightness.light
      ? Theme.of(context).appBarTheme.backgroundColor
      : Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'settings_page'.tr(),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            tooltip: 'add_point'.tr(),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddTourPointScreen(),
                ),
              );
              if (result != null) {
                // Recarrega lista incluindo novo ponto
                setState(() {
                  _tourPoints = TourPointsData.getAllTourPoints();
                  _applyFilters();
                });
              }
            },
          ),
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'toggle_theme'.tr(),
          ),
          PopupMenuButton<String>(
            onSelected: _filterByCategory,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Todos', child: Text('all'.tr())),
              PopupMenuItem(value: 'Caminhada', child: Text('hiking'.tr())),
              PopupMenuItem(value: 'Contemplação', child: Text('contemplation'.tr())),
              PopupMenuItem(value: 'Aventura', child: Text('adventure'.tr())),
              PopupMenuItem(value: 'Cultural', child: Text('cultural'.tr())),
              PopupMenuItem(value: 'Visitados', child: Text('visited'.tr())),
            ],
            icon: Icon(
              Icons.filter_list,
              color: _selectedCategory != 'Todos' 
                  ? Theme.of(context).colorScheme.secondary 
                  : null,
            ),
            tooltip: 'filter_by_category'.tr(),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(2.8235, -60.6758), // Boa Vista - RR
          initialZoom: 13.0,
          minZoom: 10.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'dev.meuapp.guia_turistico',
          ),
          MarkerLayer(
            markers: _filteredTourPoints.map((point) {
              return Marker(
                point: point.location,
                width: 40.0,
                height: 40.0,
                child: GestureDetector(
                  onTap: () => _onMarkerTapped(point),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: 'map'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: 'favorites'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.explore),
                if (_selectedCategory != 'Todos' || _searchQuery.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
      label: 'explore'.tr(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(const LatLng(2.8235, -60.6758), 13.0);
        },
    tooltip: 'center_map'.tr(),
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

/// Botão de ícone compacto para uso em listas apertadas evitando overflow
class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _CompactIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Icon(
            icon,
            size: 20,
            color: color ?? Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }
}
