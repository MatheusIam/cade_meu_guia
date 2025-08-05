import 'package:flutter/material.dart';
import '../models/preservation_tip.dart';
import '../data/preservation_data.dart';
import '../screens/all_preservation_tips_screen.dart';

class PreservationWidget extends StatefulWidget {
  final String? activityType;
  final bool showAllTips;

  const PreservationWidget({
    super.key,
    this.activityType,
    this.showAllTips = false,
  });

  @override
  State<PreservationWidget> createState() => _PreservationWidgetState();
}

class _PreservationWidgetState extends State<PreservationWidget> {
  PreservationType? _selectedType;
  List<PreservationTip> _displayedTips = [];

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  void _loadTips() {
    if (widget.activityType != null && !widget.showAllTips) {
      _displayedTips = PreservationData.getTipsForActivity(widget.activityType!);
    } else {
      _displayedTips = PreservationData.getTipsByPriority();
    }
  }

  void _filterByType(PreservationType? type) {
    setState(() {
      _selectedType = type;
      if (type == null) {
        _displayedTips = PreservationData.getTipsByPriority();
      } else {
        _displayedTips = PreservationData.getTipsByType(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.eco,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como Preservar',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.activityType != null 
                            ? 'Dicas para ${widget.activityType}'
                            : 'Dicas de preservação e sustentabilidade',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showAllTips)
                  PopupMenuButton<PreservationType?>(
                    onSelected: _filterByType,
                    icon: Icon(
                      Icons.filter_list,
                      color: _selectedType != null 
                          ? Theme.of(context).colorScheme.primary 
                          : null,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem<PreservationType?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      const PopupMenuItem<PreservationType>(
                        value: PreservationType.environmental,
                        child: Text('🌱 Ambiental'),
                      ),
                      const PopupMenuItem<PreservationType>(
                        value: PreservationType.cultural,
                        child: Text('🏛️ Cultural'),
                      ),
                      const PopupMenuItem<PreservationType>(
                        value: PreservationType.social,
                        child: Text('🤝 Social'),
                      ),
                      const PopupMenuItem<PreservationType>(
                        value: PreservationType.general,
                        child: Text('📋 Geral'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (widget.showAllTips && _selectedType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Chip(
                label: Text(_getTypeLabel(_selectedType!)),
                onDeleted: () => _filterByType(null),
                deleteIcon: const Icon(Icons.close, size: 18),
              ),
            ),
          const Divider(height: 1),
          if (_displayedTips.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Nenhuma dica encontrada para este filtro.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _displayedTips.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tip = _displayedTips[index];
                return _buildTipItem(tip);
              },
            ),
          if (!widget.showAllTips && widget.activityType != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _showAllTipsDialog(context),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Ver todas as dicas'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipItem(PreservationTip tip) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getPriorityColor(tip.priority).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getPriorityColor(tip.priority),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            tip.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(
        tip.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            tip.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(tip.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityLabel(tip.priority),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getPriorityColor(tip.priority),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getTypeLabel(tip.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'ESSENCIAL';
      case 2:
        return 'IMPORTANTE';
      case 3:
        return 'RECOMENDADO';
      default:
        return 'GERAL';
    }
  }

  String _getTypeLabel(PreservationType type) {
    switch (type) {
      case PreservationType.environmental:
        return 'Ambiental';
      case PreservationType.cultural:
        return 'Cultural';
      case PreservationType.social:
        return 'Social';
      case PreservationType.general:
        return 'Geral';
    }
  }

  void _showAllTipsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AllPreservationTipsScreen(),
      ),
    );
  }
}
