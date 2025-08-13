/// Contrato para buscar pacotes de idiomas de uma fonte remota.
abstract class LanguageRemoteDataSource {
  /// Busca um pacote de idioma em formato JSON para o [languageCode] especificado.
  /// Retorna um Map<String, dynamic> com as chaves de tradução.
  /// Lança uma exceção em caso de falha.
  Future<Map<String, dynamic>> fetchLanguagePack(String languageCode);
}
