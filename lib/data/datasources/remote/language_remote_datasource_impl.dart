import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'language_remote_datasource.dart';

/// Implementação mock que lê o pacote de idioma dos assets locais.
/// Substitua por uma chamada HTTP real quando houver backend.
class LanguageRemoteDataSourceImpl implements LanguageRemoteDataSource {
  @override
  Future<Map<String, dynamic>> fetchLanguagePack(String languageCode) async {
    final assetPath = 'assets/translations/$languageCode.json';
    try {
      final raw = await rootBundle.loadString(assetPath);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map;
    } catch (e) {
      throw Exception('Falha ao carregar pacote de idioma mock: $e');
    }
  }
}
