import 'dart:convert';
import 'package:http/http.dart' as http;
import 'language_remote_datasource.dart';

/// Implementação que busca o pacote de idioma de um endpoint HTTP.
/// ATENÇÃO: _baseUrl é exemplo; substitua pela URL real do backend.
class LanguageRemoteDataSourceImpl implements LanguageRemoteDataSource {
  final String _baseUrl = 'https://api.example.com/translations';

  @override
  Future<Map<String, dynamic>> fetchLanguagePack(String languageCode) async {
    final uri = Uri.parse('$_baseUrl/$languageCode.json');
    try {
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    } catch (e) {
      throw Exception('Falha ao buscar pacote de idioma: $e');
    }
  }
}
