import 'package:easy_localization/easy_localization.dart';
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
  Future<List<PreservationTip>>? _futureTips;
  Locale? _lastLocale; // para detectar mudança de idioma

  @override
  void initState() {
    super.initState();
    _futureTips = _initialLoad();
  }

  Future<List<PreservationTip>> _initialLoad() {
    if (widget.activityType != null && !widget.showAllTips) {
      return PreservationData.getTipsForActivity(widget.activityType!);
    } else {
      return PreservationData.getTipsByPriority();
    }
  }

  void _filterByType(PreservationType? type) {
    setState(() {
      _selectedType = type;
      if (type == null) {
        _futureTips = PreservationData.getTipsByPriority();
      } else {
        _futureTips = PreservationData.getTipsByType(type);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = context.locale; // easy_localization
    if (_lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      // Invalida cache e recarrega dados na mudança de idioma
      PreservationData.invalidate();
      _futureTips = _rebuildFutureForCurrentFilter();
    }
  }

  Future<List<PreservationTip>> _rebuildFutureForCurrentFilter() {
    if (widget.activityType != null && !widget.showAllTips) {
      return PreservationData.getTipsForActivity(widget.activityType!);
    }
    if (_selectedType != null) {
      return PreservationData.getTipsByType(_selectedType!);
    }
    return PreservationData.getTipsByPriority();
  }

  @override
  Widget build(BuildContext context) {
  final cardContent = Card(
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
                        'how_to_preserve'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.activityType != null
                            ? 'tips_for_activity'.tr(namedArgs: {'activity': widget.activityType!})
                            : 'preservation_sustainability_tips'.tr(),
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
                      PopupMenuItem<PreservationType?>(
                        value: null,
                        child: Text('all_tips'.tr()),
                      ),
                      PopupMenuItem<PreservationType>(
                        value: PreservationType.environmental,
                        child: Text('environmental_emoji'.tr()),
                      ),
                      PopupMenuItem<PreservationType>(
                        value: PreservationType.cultural,
                        child: Text('cultural_emoji'.tr()),
                      ),
                      PopupMenuItem<PreservationType>(
                        value: PreservationType.social,
                        child: Text('social_emoji'.tr()),
                      ),
                      PopupMenuItem<PreservationType>(
                        value: PreservationType.general,
                        child: Text('general_emoji'.tr()),
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
          FutureBuilder<List<PreservationTip>>(
              future: _futureTips,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('error_loading'.tr())),
                  );
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('no_tips_for_filter'.tr())),
                  );
                }
                // Em modo "todas as dicas" usamos Column simples (rolagem externa) para evitar overflow
                if (widget.showAllTips) {
                  return Column(
                    children: [
                      for (int i = 0; i < data.length; i++) ...[
                        _buildTipItem(data[i]),
                        if (i < data.length - 1) const Divider(height: 1),
                      ]
                    ],
                  );
                }
                // Caso compacto (embutido em outra tela) segue comportamento anterior (lista sem rolagem interna)
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) => _buildTipItem(data[index]),
                );
              }),
          if (!widget.showAllTips && widget.activityType != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _showAllTipsDialog(context),
                  icon: const Icon(Icons.visibility),
                  label: Text('see_all_tips'.tr()),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.showAllTips) {
      // Envolve em rolagem para evitar overflow em tela cheia
      return SingleChildScrollView(
        child: cardContent,
      );
    }
    return cardContent;
  }

  Widget _buildTipItem(PreservationTip tip) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getPriorityColor(tip.priority).withAlpha(25),
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
                  color: _getPriorityColor(tip.priority).withAlpha(25),
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        return 'essential'.tr();
      case 2:
        return 'important'.tr();
      case 3:
        return 'recommended'.tr();
      default:
        return 'general_cap'.tr();
    }
  }

  String _getTypeLabel(PreservationType type) {
    switch (type) {
      case PreservationType.environmental:
        return 'environmental'.tr();
      case PreservationType.cultural:
        return 'cultural'.tr();
      case PreservationType.social:
        return 'social'.tr();
      case PreservationType.general:
        return 'general'.tr();
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
