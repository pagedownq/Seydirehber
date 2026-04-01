class ProfanityFilter {
  static const List<String> _badWords = [
    'amk', 'aq', 'amın', 'amına', 'oç', 'sik', 'sikerim', 'sikti', 'sikis', 'sikiş',
    'göt', 'götü', 'götlek', 'yarrak', 'yarrak', 'yarak', 'taşşak', 'tassak', 'orospu',
    'pezevenk', 'gavat', 'piç', 'pic', 'ibne', 'yavsak', 'yavşak', 'it', 'it oğlu it',
    'köpek', 'itsoy', 'kahpe', 'puşt', 'pust', 'kerhane', 'ananın', 'ananı', 'sülaleni','oe','aq'
  ];

  static bool hasProfanity(String text) {
    final lowerText = text.toLowerCase();
    
    // Kelime kelime kontrol (Boşluklara göre ayır)
    final words = lowerText.split(RegExp(r'\s+'));
    for (var word in words) {
      if (_badWords.contains(_cleanWord(word))) return true;
    }

    // İçerik olarak kontrol (Örn: "selamamk")
    for (var badWord in _badWords) {
      if (lowerText.contains(badWord)) {
        // Eğer kötü kelime bir başka normal kelimenin içindeyse (örn: "şakşak") engelleme.
        // Ancak bu basit filtreleme için "amk" gibi kısa kelimelerde sorun çıkarabilir.
        // Bu yüzden şimdilik basit tutalım ama çok kısa kelimeleri (aq gibi) sadece tam kelime olarak kontrol edelim.
        if (badWord.length > 3) return true;
      }
    }

    return false;
  }

  static String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[^a-zA-ZğüşıöçĞÜŞİÖÇ]'), '');
  }
}
