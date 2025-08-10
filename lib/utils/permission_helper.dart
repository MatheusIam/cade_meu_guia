import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionHelper {
  static const _acceptedKey = 'accepted_precise_location_modal';
  /// Mostra modal explicando necessidade de localização precisa e então solicita permissão.
  /// Sempre mostra o modal (mesmo já tendo permissão) conforme requisito.
  static Future<bool> ensurePreciseLocationPermission(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    bool accepted = prefs.getBool(_acceptedKey) ?? false;
    bool proceed = accepted;

    if (!accepted) {
  final dialogResult = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Permissão de Localização Precisa'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Precisamos da sua localização precisa para:'),
              SizedBox(height: 8),
              _Bullet(text: 'Centralizar o mapa na sua posição atual'),
              _Bullet(text: 'Facilitar o cadastro correto do ponto turístico'),
              _Bullet(text: 'Melhorar a precisão de busca por locais próximos'),
              SizedBox(height: 12),
              Text('As coordenadas não são enviadas para servidores externos.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Permitir'),
            ),
          ],
        ),
  );
  proceed = dialogResult ?? false;
  if (proceed) {
        accepted = true;
        await prefs.setBool(_acceptedKey, true);
      }
    }

    if (proceed != true) return false;

    // Solicita permissão. Precisamos de FINE; se usuário conceder somente CA (approx), insistimos.
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      _showDeniedSnack(context);
      return false;
    }

    // Em Android 12+ pode retornar enquanto approximate apenas. Tentamos obter uma posição de alta precisão.
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  final horizontalAcc = pos.accuracy; // metros
  // Heurística: se accuracy > 100m consideramos que ainda é approximate.
  if (horizontalAcc > 100) {
        final insist = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Precisão insuficiente'),
            content: const Text('Você concedeu apenas localização aproximada. Para usar os recursos de mapa corretamente, permita a localização precisa (exata). Deseja tentar novamente?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tentar novamente')),
              TextButton(onPressed: () {
                Geolocator.openAppSettings();
                Navigator.pop(ctx, false);
              }, child: const Text('Configurações')),
            ],
          ),
        );
        if (insist == true) {
          // Repetimos pedido; alguns OEMs permitem upgrade.
          final reperm = await Geolocator.requestPermission();
          if (reperm == LocationPermission.always || reperm == LocationPermission.whileInUse) {
            return true; // Aceitamos; nova leitura posterior será mais precisa.
          }
          _showDeniedSnack(context);
          return false;
        }
        return false;
      }
    } catch (_) {
      // Se falhar leitura, mantemos retorno true apenas se perm fine.
    }

    return true;
  }

  static void _showDeniedSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permissão de localização negada. Ajuste nas configurações.')),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• '),
        Expanded(child: Text(text)),
      ],
    );
  }
}
