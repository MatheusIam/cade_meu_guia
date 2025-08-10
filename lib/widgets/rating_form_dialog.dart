import 'package:flutter/material.dart';
import '../models/tour_point.dart';
import '../models/tour_point_rating.dart';

/// Widget para formulário de avaliação de ponto turístico
class RatingFormDialog extends StatefulWidget {
  final TourPoint tourPoint;
  final TourPointRating? existingRating;
  final Function(TourPointRating) onRatingSubmitted;

  const RatingFormDialog({
    super.key,
    required this.tourPoint,
    this.existingRating,
    required this.onRatingSubmitted,
  });

  @override
  State<RatingFormDialog> createState() => _RatingFormDialogState();
}

class _RatingFormDialogState extends State<RatingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  double _overallRating = 3.0;
  double _accessibilityRating = 3.0;
  double _cleanlinessRating = 3.0;
  double _infrastructureRating = 3.0;
  double _safetyRating = 3.0;
  double _experienceRating = 3.0;
  bool _isRecommended = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRating != null) {
      _loadExistingRating();
    }
  }

  void _loadExistingRating() {
    final rating = widget.existingRating!;
    _overallRating = rating.overallRating;
    _accessibilityRating = rating.accessibilityRating;
    _cleanlinessRating = rating.cleanlinessRating;
    _infrastructureRating = rating.infrastructureRating;
    _safetyRating = rating.safetyRating;
    _experienceRating = rating.experienceRating;
    _isRecommended = rating.isRecommended;
  // Comentário removido
  }

  @override
  void dispose() {
  // Comentário removido, sem controller para dispose
    super.dispose();
  }

  void _submitRating() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final rating = TourPointRating(
        id: widget.existingRating?.id ?? 
            'rating_${widget.tourPoint.id}_${DateTime.now().millisecondsSinceEpoch}',
        tourPointId: widget.tourPoint.id,
        userId: 'current_user', // Em um app real, viria do sistema de autenticação
        overallRating: _overallRating,
        accessibilityRating: _accessibilityRating,
        cleanlinessRating: _cleanlinessRating,
        infrastructureRating: _infrastructureRating,
        safetyRating: _safetyRating,
        experienceRating: _experienceRating,
  comment: null, // Comentário removido
        dateCreated: DateTime.now(),
        isRecommended: _isRecommended,
      );

      widget.onRatingSubmitted(rating);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingRating != null 
                  ? 'Avaliação atualizada com sucesso!' 
                  : 'Avaliação enviada com sucesso!'
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar avaliação. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 500,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rate,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingRating != null 
                              ? 'Editar Avaliação' 
                              : 'Avaliar Local',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.tourPoint.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avaliação Geral
                      _buildRatingSection(
                        'Avaliação Geral',
                        Icons.star,
                        _overallRating,
                        (value) => setState(() => _overallRating = value),
                        'Como foi sua experiência geral neste local?',
                      ),
                      const SizedBox(height: 20),
                      
                      // Categorias específicas
                      _buildRatingSection(
                        'Acessibilidade',
                        Icons.accessible,
                        _accessibilityRating,
                        (value) => setState(() => _accessibilityRating = value),
                        'Facilidade de acesso e locomoção no local',
                      ),
                      const SizedBox(height: 16),
                      
                      _buildRatingSection(
                        'Limpeza',
                        Icons.cleaning_services,
                        _cleanlinessRating,
                        (value) => setState(() => _cleanlinessRating = value),
                        'Estado de conservação e limpeza do local',
                      ),
                      const SizedBox(height: 16),
                      
                      _buildRatingSection(
                        'Infraestrutura',
                        Icons.foundation,
                        _infrastructureRating,
                        (value) => setState(() => _infrastructureRating = value),
                        'Qualidade das instalações e facilidades',
                      ),
                      const SizedBox(height: 16),
                      
                      _buildRatingSection(
                        'Segurança',
                        Icons.security,
                        _safetyRating,
                        (value) => setState(() => _safetyRating = value),
                        'Sensação de segurança durante a visita',
                      ),
                      const SizedBox(height: 16),
                      
                      _buildRatingSection(
                        'Experiência',
                        Icons.mood,
                        _experienceRating,
                        (value) => setState(() => _experienceRating = value),
                        'Qualidade da experiência e atividades oferecidas',
                      ),
                      const SizedBox(height: 24),
                      
                      // Recomendação
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.thumb_up,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Você recomendaria este local?',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Switch(
                              value: _isRecommended,
                              onChanged: (value) => setState(() => _isRecommended = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Campo de comentário removido para simplificar a avaliação
                    ],
                  ),
                ),
              ),
            ),
            
            // Botões de ação
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.existingRating != null ? 'Atualizar' : 'Enviar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(
    String title,
    IconData icon,
    double currentRating,
    Function(double) onChanged,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: currentRating,
                min: 1.0,
                max: 5.0,
                divisions: 4,
                label: _getRatingLabel(currentRating),
                onChanged: onChanged,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRatingColor(currentRating),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    currentRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getRatingLabel(double rating) {
    if (rating <= 1.5) return 'Muito Ruim';
    if (rating <= 2.5) return 'Ruim';
    if (rating <= 3.5) return 'Regular';
    if (rating <= 4.5) return 'Bom';
    return 'Excelente';
  }

  Color _getRatingColor(double rating) {
    if (rating <= 1.5) return Colors.red.shade600;
    if (rating <= 2.5) return Colors.orange.shade600;
    if (rating <= 3.5) return Colors.amber.shade600;
    if (rating <= 4.5) return Colors.lightGreen.shade600;
    return Colors.green.shade600;
  }
}
