import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/tour_point.dart';
import '../providers/favorites_provider.dart';
import '../providers/ratings_provider.dart';
import 'manage_tour_point_screen.dart';
import '../widgets/widgets.dart';
import '../widgets/rating_form_dialog.dart';
import '../data/tour_points_data.dart';

/// Tela de detalhes do ponto turístico
class TourPointScreen extends StatefulWidget {
  final TourPoint tourPoint;

  const TourPointScreen({super.key, required this.tourPoint});

  @override
  State<TourPointScreen> createState() => _TourPointScreenState();
}

class _TourPointScreenState extends State<TourPointScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFavorite() async {
    HapticFeedback.lightImpact();
    final favoritesProvider = context.read<FavoritesProvider>();
    await favoritesProvider.toggleFavorite(widget.tourPoint);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            favoritesProvider.isFavorite(widget.tourPoint.id)
                ? 'added_to_favorites'.tr() 
                : 'removed_from_favorites_msg'.tr()
          ),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => _toggleFavorite(),
          ),
        ),
      );
    }
  }

  void _shareLocation() {
    HapticFeedback.selectionClick();
    // Implementar funcionalidade de compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('share_location'.tr()),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openDirections() {
    HapticFeedback.selectionClick();
    // Implementar abertura de direções no app de mapas
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('opening_directions'.tr()),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showImageGallery() {
    if (widget.tourPoint.images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('no_images_available'.tr()),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: widget.tourPoint.images.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'image_counter'.tr(namedArgs:{'index': (_currentImageIndex + 1).toString(), 'total': widget.tourPoint.images.length.toString()}),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('close'.tr()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TourPoint> _getNearbyPoints() {
    return TourPointsData.getNearbyTourPoints(widget.tourPoint.location, 5.0)
        .where((point) => point.id != widget.tourPoint.id)
        .take(3)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: Theme.of(context).brightness == Brightness.light
                  ? Theme.of(context).appBarTheme.backgroundColor
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.tourPoint.name,
                  style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: GestureDetector(
                  onTap: _showImageGallery,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.black.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: widget.tourPoint.images.isNotEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'tap_to_view_gallery'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Icon(
                              Icons.location_on,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              actions: [
                Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    final isFavorite = favoritesProvider.isFavorite(widget.tourPoint.id);
                    return IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : null,
                      ),
                      onPressed: _toggleFavorite,
                      tooltip: 'favorite'.tr(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareLocation,
                  tooltip: 'share'.tr(),
                ),
                if (TourPointsData.isCustomPoint(widget.tourPoint.id))
                  IconButton(
                    icon: const Icon(Icons.edit_location_alt),
                    tooltip: 'edit_point'.tr(),
                    onPressed: () async {
                      final updated = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ManageTourPointScreen(existing: widget.tourPoint),
                        ),
                      );
                      if (updated is TourPoint) {
                        setState(() {
                          // Atualizar referência local
                          // widget.tourPoint é final; criar nova tela idealmente, simplificação aqui ignorada.
                        });
                      }
                    },
                  ),
                // Botão de avaliar removido do AppBar conforme solicitação
              ],
            ),
          ];
        },
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: false,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                Tab(icon: const Icon(Icons.info), text: 'details'.tr()),
                Tab(icon: const Icon(Icons.map), text: 'map'.tr()),
                Tab(icon: const Icon(Icons.eco), text: 'preserve'.tr()),
                Tab(icon: const Icon(Icons.explore), text: 'nearby'.tr()),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(),
                  _buildMapTab(),
                  _buildPreservationTab(),
                  _buildNearbyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationHeader(
            title: widget.tourPoint.title,
            description: widget.tourPoint.description,
          ),
          const SizedBox(height: 12),
          Consumer<RatingsProvider>(
            builder: (context, ratingsProvider, _) {
              final visited = ratingsProvider.isTourPointVisited(widget.tourPoint.id);
              if (!visited) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  label: Text('visitado'.tr()),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ExtraInfoSection(
            rating: widget.tourPoint.rating.toStringAsFixed(2),
            photoCount: widget.tourPoint.photoCount.toString(),
            activityType: widget.tourPoint.activityType,
          ),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 24),
          _buildAdditionalInfo(),
          const SizedBox(height: 24),
          _buildDetailedInfoSection(),
          const SizedBox(height: 24),
          _buildChildPointsSection(),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MapWidget(
        location: widget.tourPoint.location,
        zoom: 16.0,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildPreservationTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          PreservationWidget(
            activityType: widget.tourPoint.activityType,
          ),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'be_conscious_tourist'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'preservation'.tr() + ' - ' + widget.tourPoint.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildImpactStats(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showReportDialog(),
                          icon: const Icon(Icons.report_problem),
                          label: Text('report_problem'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _sharePreservationTips(),
                          icon: const Icon(Icons.share),
                          label: Text('share_tips'.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyTab() {
    final nearbyPoints = _getNearbyPoints();
    
    return nearbyPoints.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'nearby_none'.tr(),
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: nearbyPoints.length,
            itemBuilder: (context, index) {
              final point = nearbyPoints[index];
              final distance = const Distance().as(
                LengthUnit.Kilometer,
                widget.tourPoint.location,
                point.location,
              );
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
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
                  title: Text(point.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(point.title),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TourPointScreen(tourPoint: point),
                      ),
                    );
                  },
                ),
              );
            },
          );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openDirections,
                icon: const Icon(Icons.directions),
                label: Text('directions'.tr()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareLocation,
                icon: const Icon(Icons.share),
                label: Text('share'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _showRatingDialog,
          icon: const Icon(Icons.star_rate),
          label: Text('rate_this_place'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'additional_info'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.star,
                  'rating'.tr(),
                  '${widget.tourPoint.rating}/5.0',
                  onTap: _showRatingDialog,
                  tappable: true,
                ),
                const Divider(),
                _buildInfoRow(
                  Icons.photo_library,
                  'photos_available'.tr(),
                  widget.tourPoint.photoCount.toString(),
                ),
                const Divider(),
                _buildInfoRow(
                  Icons.category,
                  'activity_type'.tr(),
                  widget.tourPoint.activityType,
                ),
                const Divider(),
                _buildInfoRow(
                  Icons.location_on,
                  'coordinates'.tr(),
                  '${widget.tourPoint.location.latitude.toStringAsFixed(4)}, ${widget.tourPoint.location.longitude.toStringAsFixed(4)}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,{VoidCallback? onTap,bool tappable=false}) {
    final row = Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (tappable)
                    Padding(
                      padding: const EdgeInsets.only(left:4.0),
                      child: Icon(
                        Icons.touch_app,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha:0.8),
                      ),
                    ),
                ],
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration: tappable ? TextDecoration.underline : null,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
            ],
          ),
        ),
        if (tappable)
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      ],
    );
    if (!tappable) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }

  Widget _buildImpactStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'conscious_tourism_positive'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🌱', 'preservation'.tr(), 'environmental'.tr()),
              _buildStatItem('🏛️', 'heritage'.tr(), 'cultural'.tr()),
              _buildStatItem('🤝', 'local_economy'.tr(), 'social'.tr()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String icon, String label, String subtitle) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.report_problem, color: Colors.orange),
            const SizedBox(width: 8),
            Text('report_problem'.tr()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'report_problem_question'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('problem_types'.tr()),
            const SizedBox(height: 8),
      ...['problem_list_litter'.tr(), 'problem_list_damage'.tr(), 'problem_list_vandalism'.tr(), 'problem_list_access'.tr(), 'problem_list_other'.tr()]
        .map((problem) => ListTile(
            leading: const Icon(Icons.circle, size: 8),
            title: Text(problem),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('problem_reported'.tr()),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: Text('report'.tr()),
          ),
        ],
      ),
    );
  }

  void _sharePreservationTips() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('preservation_tips_shared'.tr()),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'view_tips'.tr(),
          onPressed: () {
            // Navegar para aba de preservação se não estiver nela
            if (_tabController.index != 2) {
              _tabController.animateTo(2);
            }
          },
        ),
      ),
    );
  }

  void _showRatingDialog() {
    final ratingsProvider = context.read<RatingsProvider>();
    final existingRating = ratingsProvider.getUserRatingForTourPoint(
      widget.tourPoint.id, 
      'current_user'
    );

    showDialog(
      context: context,
      builder: (context) => RatingFormDialog(
        tourPoint: widget.tourPoint,
        existingRating: existingRating,
        onRatingSubmitted: (rating) async {
          await ratingsProvider.addRating(rating);
        },
      ),
    );
  }

  Widget _buildDetailedInfoSection() {
    final hasAny = widget.tourPoint.history.isNotEmpty || widget.tourPoint.significance.isNotEmpty || widget.tourPoint.purpose.isNotEmpty;
    if (!hasAny) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'more_about'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.tourPoint.history.isNotEmpty)
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.history_edu),
              title: Text('history'.tr()),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(widget.tourPoint.history),
                ),
              ],
            ),
          ),
        if (widget.tourPoint.significance.isNotEmpty)
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text('significance'.tr()),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(widget.tourPoint.significance),
                ),
              ],
            ),
          ),
        if (widget.tourPoint.purpose.isNotEmpty)
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text('purpose'.tr()),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(widget.tourPoint.purpose),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChildPointsSection() {
    final children = TourPointsData.getChildPoints(widget.tourPoint.id);
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'points_in_this_area'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          itemBuilder: (context, index) {
            final child = children[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.place_outlined, color: Colors.white),
                ),
                title: Text(child.name),
                subtitle: Text(child.title),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TourPointScreen(tourPoint: child),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
