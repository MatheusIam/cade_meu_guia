import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../models/tour_point.dart';
import '../widgets/widgets.dart';
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
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pageController = PageController();
    _loadFavoriteStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadFavoriteStatus() {
    // Simular carregamento do status de favorito
    // Em uma aplicação real, isso viria de um banco de dados ou SharedPreferences
    setState(() {
      _isFavorite = false; // Por padrão, não é favorito
    });
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite 
            ? 'Adicionado aos favoritos' 
            : 'Removido dos favoritos'
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: _toggleFavorite,
        ),
      ),
    );
  }

  void _shareLocation() {
    HapticFeedback.selectionClick();
    // Implementar funcionalidade de compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Localização compartilhada!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openDirections() {
    HapticFeedback.selectionClick();
    // Implementar abertura de direções no app de mapas
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo direções...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showImageGallery() {
    if (widget.tourPoint.images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma imagem disponível'),
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
                      '${_currentImageIndex + 1} de ${widget.tourPoint.images.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fechar'),
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
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.tourPoint.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: widget.tourPoint.images.isNotEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 60,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Toque para ver galeria',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
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
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: 'Favoritar',
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareLocation,
                  tooltip: 'Compartilhar',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'directions':
                        _openDirections();
                        break;
                      case 'gallery':
                        _showImageGallery();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'directions',
                      child: Row(
                        children: [
                          Icon(Icons.directions),
                          SizedBox(width: 8),
                          Text('Direções'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'gallery',
                      child: Row(
                        children: [
                          Icon(Icons.photo_library),
                          SizedBox(width: 8),
                          Text('Galeria'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Detalhes'),
                Tab(icon: Icon(Icons.map), text: 'Mapa'),
                Tab(icon: Icon(Icons.eco), text: 'Preservação'),
                Tab(icon: Icon(Icons.explore), text: 'Próximos'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDirections,
        icon: const Icon(Icons.directions),
        label: const Text('Direções'),
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
          const SizedBox(height: 24),
          ExtraInfoSection(
            rating: widget.tourPoint.rating.toString(),
            photoCount: widget.tourPoint.photoCount.toString(),
            activityType: widget.tourPoint.activityType,
          ),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 24),
          _buildAdditionalInfo(),
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
                        'Seja um Turista Consciente',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'O turismo sustentável é responsabilidade de todos. Ao visitar ${widget.tourPoint.name}, você está contribuindo para a preservação deste patrimônio para as futuras gerações.',
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
                          label: const Text('Reportar Problema'),
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
                          label: const Text('Compartilhar Dicas'),
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
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum ponto próximo encontrado',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
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
                      point.rating.toString(),
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
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _openDirections,
            icon: const Icon(Icons.directions),
            label: const Text('Direções'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareLocation,
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
            ),
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
          'Informações Adicionais',
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
                  'Avaliação',
                  '${widget.tourPoint.rating}/5.0',
                ),
                const Divider(),
                _buildInfoRow(
                  Icons.photo_library,
                  'Fotos disponíveis',
                  widget.tourPoint.photoCount.toString(),
                ),
                const Divider(),
                _buildInfoRow(
                  Icons.category,
                  'Tipo de atividade',
                  widget.tourPoint.activityType,
                ),
                const Divider(),
                _buildInfoRow(
                  Icons.location_on,
                  'Coordenadas',
                  '${widget.tourPoint.location.latitude.toStringAsFixed(4)}, ${widget.tourPoint.location.longitude.toStringAsFixed(4)}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
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
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Impacto Positivo do Turismo Consciente',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🌱', 'Preservação', 'Ambiental'),
              _buildStatItem('🏛️', 'Patrimônio', 'Cultural'),
              _buildStatItem('🤝', 'Economia', 'Local'),
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
        title: const Row(
          children: [
            Icon(Icons.report_problem, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reportar Problema'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Encontrou algum problema neste local?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text('Tipos de problemas:'),
            const SizedBox(height: 8),
            ...['Lixo acumulado', 'Danos ao patrimônio', 'Vandalismo', 'Problemas de acesso', 'Outros']
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
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Problema reportado! Obrigado por ajudar na preservação.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  void _sharePreservationTips() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Dicas de preservação compartilhadas!'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Ver Dicas',
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
}
