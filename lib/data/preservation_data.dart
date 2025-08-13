import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import '../models/preservation_tip.dart';

/// Serviço de dados das dicas de preservação.
/// Agora carrega de assets JSON baseados no locale e pode futuramente
/// ser estendido para buscar remotamente antes de cair no cache local.
class PreservationData {
  static List<PreservationTip>? _cache; // cache em memória
  static String? _loadedLocale; // locale do cache atual

  static String _fileForLocale(Locale locale) {
    final code = locale.languageCode.toLowerCase();
    switch (code) {
      case 'en':
        return 'assets/data/preservation_tips_en.json';
      case 'pt':
      default:
        return 'assets/data/preservation_tips_pt.json';
    }
  }

  /// Carrega (lazy) as dicas do JSON. Se já carregado para o locale atual, reutiliza cache.
  static Future<List<PreservationTip>> loadTips({Locale? locale}) async {
    locale ??= WidgetsBinding.instance.platformDispatcher.locale;
    if (_cache != null && _loadedLocale == locale.languageCode) return _cache!;
    final path = _fileForLocale(locale);
    final raw = await rootBundle.loadString(path);
    final List list = jsonDecode(raw) as List;
    _cache = list.map((e) => PreservationTip.fromJson(e)).toList();
    _loadedLocale = locale.languageCode;
    return _cache!;
  }

  /// Limpa cache (ex: ao trocar de idioma ou após sync remoto)
  static void invalidate() {
    _cache = null; _loadedLocale = null;
  }

  /// Retorna todas as dicas de preservação
  static Future<List<PreservationTip>> getAllTips() async {
    return List.unmodifiable(await loadTips());
  }

  /// Retorna dicas filtradas por tipo
  static Future<List<PreservationTip>> getTipsByType(PreservationType type) async {
    final tips = await loadTips();
    return tips.where((tip) => tip.type == type).toList();
  }

  /// Retorna dicas de alta prioridade
  static Future<List<PreservationTip>> getHighPriorityTips() async {
    final tips = await loadTips();
    return tips.where((tip) => tip.priority == 1).toList();
  }

  /// Retorna dicas ordenadas por prioridade
  static Future<List<PreservationTip>> getTipsByPriority() async {
    final tips = List<PreservationTip>.from(await loadTips());
    tips.sort((a, b) => a.priority.compareTo(b.priority));
    return tips;
  }

  /// Retorna dicas específicas para um tipo de atividade
  static Future<List<PreservationTip>> getTipsForActivity(String activityType) async {
    final tips = await loadTips();
    final lower = activityType.toLowerCase();
    bool match(PreservationTip t, List<int> ids) => ids.contains(int.tryParse(t.id));
    switch (lower) {
      case 'caminhada':
      case 'hiking':
        return tips.where((t) => match(t, [1,3,5,14])).toList();
      case 'contemplação':
      case 'contemplation':
        return tips.where((t) => match(t, [1,2,8,11])).toList();
      case 'aventura':
      case 'adventure':
        return tips.where((t) => match(t, [1,3,4,12])).toList();
      case 'cultural':
        return tips.where((t) => match(t, [6,7,8,9])).toList();
      default:
        return getHighPriorityTips();
    }
  }

  /// Retorna estatísticas das dicas
  static Future<Map<String, dynamic>> getTipsStatistics() async {
    final tips = await loadTips();
    Map<PreservationType, int> typeCount = {};
    Map<int, int> priorityCount = {};
    for (var tip in tips) {
      typeCount[tip.type] = (typeCount[tip.type] ?? 0) + 1;
      priorityCount[tip.priority] = (priorityCount[tip.priority] ?? 0) + 1;
    }
    return {
      'totalTips': tips.length,
      'typeCount': typeCount,
      'priorityCount': priorityCount,
      'highPriorityCount': priorityCount[1] ?? 0,
    };
  }
}

// (Opcional) Poderíamos expor um método para forçar recarregar a partir de um locale específico
// PreservationData.loadTips(locale: Locale('en'));
