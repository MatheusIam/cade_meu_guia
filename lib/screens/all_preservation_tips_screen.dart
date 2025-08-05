import 'package:flutter/material.dart';
import '../widgets/preservation_widget.dart';

/// Tela que mostra todas as dicas de preservação
class AllPreservationTipsScreen extends StatelessWidget {
  const AllPreservationTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dicas de Preservação'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: const PreservationWidget(showAllTips: true),
    );
  }
}
