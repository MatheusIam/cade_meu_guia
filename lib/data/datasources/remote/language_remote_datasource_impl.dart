import 'language_remote_datasource.dart';

/// Implementação mock/placeholder da fonte de dados remota de idiomas.
class LanguageRemoteDataSourceImpl implements LanguageRemoteDataSource {
  @override
  Future<Map<String, dynamic>> fetchLanguagePack(String languageCode) async {
    // TODO: Implementar chamada HTTP real.
    // Exemplo (futuro):
    // final response = await http.get(Uri.parse('https://api.seuservico.com/languages/$languageCode'));
    // if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    // throw Exception('Falha ao carregar pacote de idioma');
    // Por enquanto, lança não implementado.
    // ignore: avoid_print
    print("Futura implementação: buscando pacote de idioma para '$languageCode'...");
    throw UnimplementedError('Busca remota de pacote de idioma ainda não implementada.');
  }
}
