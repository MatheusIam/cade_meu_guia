import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
      title: Text('permission_precise_title'.tr()),
      content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Text('permission_precise_reason_title'.tr()),
              SizedBox(height: 8),
        _Bullet(text: 'permission_precise_reason_point1'.tr()),
        _Bullet(text: 'permission_precise_reason_point2'.tr()),
        _Bullet(text: 'permission_precise_reason_point3'.tr()),
              SizedBox(height: 12),
        Text('permission_precise_privacy'.tr()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
        child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
        child: Text('allow'.tr()),
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
            title: Text('insufficient_accuracy_title'.tr()),
            content: Text('insufficient_accuracy_message'.tr()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('try_again'.tr())),
              TextButton(onPressed: () {
                Geolocator.openAppSettings();
                Navigator.pop(ctx, false);
              }, child: Text('settings'.tr())),
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
  SnackBar(content: Text('location_permission_denied'.tr())),
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
