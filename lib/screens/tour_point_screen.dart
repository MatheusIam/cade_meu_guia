import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/tour_point.dart';
import '../widgets/widgets.dart';

/// Widget que representa a tela principal do ponto turístico.
class TourPointScreen extends StatelessWidget {
  final TourPoint? tourPoint;

  const TourPointScreen({super.key, this.tourPoint});

  // Dados padrão da Orla Taumanã
  static const TourPoint _defaultTourPoint = TourPoint(
    id: '1',
    name: 'Orla Taumanã',
    title: 'Cartão-postal de Boa Vista',
    description: 'A Orla Taumanã é um dos principais pontos turísticos de Boa Vista, capital de Roraima. Localizada às margens do Rio Branco, oferece uma vista espetacular e é ideal para caminhadas, contemplação do pôr do sol e atividades de lazer.',
    location: LatLng(2.8235, -60.6758),
    rating: 4.7,
    photoCount: 850,
    activityType: 'Caminhada',
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTourPoint = tourPoint ?? _defaultTourPoint;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(currentTourPoint.name),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.auto_mode),
            onPressed: () => themeProvider.setSystemTheme(),
            tooltip: 'Set System Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Permite a rolagem da tela em dispositivos menores.
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção de título e descrição do local.
              LocationHeader(
                title: currentTourPoint.title,
                description: currentTourPoint.description,
              ),
              const SizedBox(height: 24),

              // Seção do mapa.
              MapWidget(
                location: currentTourPoint.location,
                zoom: 15.0,
                width: 300,
                height: 300,
              ),
              const SizedBox(height: 24),

              // Seção de informações adicionais e ações.
              ExtraInfoSection(
                rating: currentTourPoint.rating.toString(),
                photoCount: currentTourPoint.photoCount.toString(),
                activityType: currentTourPoint.activityType,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
