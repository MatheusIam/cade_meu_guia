import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cade Meu Guia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: TourPointScreen(),
      // debugShowCheckedModeBanner: false,
    );
  }
}

// Widget que representa a tela principal do ponto turístico.
class TourPointScreen extends StatelessWidget {
  const TourPointScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orla Taumanã'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        // Permite a rolagem da tela em dispositivos menores.
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção de título e descrição do local (placeholder).
              _buildLocationHeader(context),
              const SizedBox(height: 24),

              // Seção do mapa.
              _buildMapSection(),
              const SizedBox(height: 24),

              // Seção de informações adicionais e ações (placeholder).
              _buildExtraInfoSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // Constrói o cabeçalho com o nome e uma breve descrição do local.
  Widget _buildLocationHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cartão-postal de Boa Vista',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'A Orla Taumanã é um dos principais pontos turísticos de Boa Vista, capital de Roraima. Localizada às margens do Rio Branco, oferece uma vista espetacular e é ideal para caminhadas, contemplação do pôr do sol e atividades de lazer.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }

  // Constrói a seção que contém o mapa.
  Widget _buildMapSection() {
    return Center(
      child: Container(
        height: 300,
        width: 300,
        // O ClipRRect é usado para aplicar as bordas arredondadas ao seu filho (o mapa).
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: FlutterMap(
            options: const MapOptions(
              // Coordenadas iniciais do mapa (Orla Taumanã, Boa Vista - RR).
              initialCenter: LatLng(2.8235, -60.6758),
              initialZoom: 15.0,
            ),
            children: [
              // Camada de "tiles" que compõem a imagem do mapa.
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.meuapp.guia_turistico',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Constrói a seção de informações extras, como avaliações e fotos.
  Widget _buildExtraInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem(context, Icons.star_rate, '4.7', 'Avaliações'),
            _buildInfoItem(context, Icons.photo_library, '850', 'Fotos'),
            _buildInfoItem(
              context,
              Icons.directions_walk,
              'Caminhada',
              'Atividade',
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para criar um item de informação com ícone e texto.
  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
