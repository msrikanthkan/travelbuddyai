enum SupportedLanguage { telugu, hindi, tamil, kannada, english }

class Translation {
  final String id;
  final String englishPhrase;
  final String translatedPhrase;
  final SupportedLanguage language;
  final String pronunciation;

  Translation({
    required this.id,
    required this.englishPhrase,
    required this.translatedPhrase,
    required this.language,
    this.pronunciation = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'englishPhrase': englishPhrase,
    'translatedPhrase': translatedPhrase,
    'language': language.name,
    'pronunciation': pronunciation,
  };

  factory Translation.fromJson(Map<String, dynamic> json) => Translation(
    id: json['id'],
    englishPhrase: json['englishPhrase'],
    translatedPhrase: json['translatedPhrase'],
    language: SupportedLanguage.values.firstWhere(
      (e) => e.name == json['language'],
      orElse: () => SupportedLanguage.english,
    ),
    pronunciation: json['pronunciation'] ?? '',
  );
}

class TranslationCategory {
  final String name;
  final List<String> phrases;

  TranslationCategory({required this.name, required this.phrases});
}
