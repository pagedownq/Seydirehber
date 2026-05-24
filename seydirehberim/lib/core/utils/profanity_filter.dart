class ProfanityFilter {
  static const List<String> _badWords = [
    'amk', 'aq', 'amın', 'amına', 'oç', 'sik', 'sikerim', 'sikti', 'sikis', 'sikiş',
    'göt', 'götü', 'götlek', 'yarrak', 'yarak', 'taşşak', 'tassak', 'orospu',
    'pezevenk', 'gavat', 'piç', 'pic', 'ibne', 'yavsak', 'yavşak', 'it', 'it oğlu it',
    'itsoy', 'kahpe', 'puşt', 'pust', 'kerhane', 'ananın', 'ananı', 'sülaleni', 'oe',
    'siktir', 'sktir', 'sktr', 'sg', 'amq', 'amg', 'amcık', 'amcik', 'am', 'yarak',
    'yarrak', 'yarram', 'yaram', 'taşak', 'tasak', 'dallama', 'dangalak', 'denyo', 'kavat',
    'kaltak', 'kevaşe', 'motor', 'kaşar', 'kasar', 'sürtük', 'surtuk', 'fahişe', 'fahise',
    'dalyarak', 'dalyarrak', 'sığıntı', 'siginti', 'sığır', 'sigir', 'manyak', 'salak', 'aptal',
    'gerizekalı', 'gerizekali', 'beyinsiz', 'embesil', 'özürlü', 'ozurlu', 'mal', 'mal değneği',
    'veled', 'velet', 'sokuk', 'sokuk', 'sürtük', 'dingil', 'dümbük', 'dumbuk', 'hıyar', 'hiyar',
    'lavuk', 'ibine', 'sıçtığım', 'sictigim', 'sıçayım', 'sicayim', 'sıç', 'sic', 'bitch', 'fuck',
    'shit', 'asshole', 'motherfucker', 'or çocuğu', 'or cocugu', 'orospu çocuğu', 'orospu cocugu',
    'zibidi', 'zibidi', 'zina', 'kaltak', 'şıllık', 'sillik', 'çük', 'cuk', 'pip', 'pipi'
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

  /// Verilen metni kontrol eder ve kötü kelimeleri sansürler.
  static String censor(String text) {
    if (text.isEmpty) return text;
    
    String result = text;
    
    for (final word in _badWords) {
      // Sadece kelime olarak eşleşenleri bulmak için regex
      final regex = RegExp(r'\b' + word + r'\b', caseSensitive: false, unicode: true);
      result = result.replaceAllMapped(regex, (match) {
        return '*' * match.group(0)!.length;
      });
    }

    return result;
  }

  /// Verilen metin içindeki argo/küfür kelimelerin listesini döndürür.
  static List<String> findProfanity(String text) {
    if (text.isEmpty) return [];
    
    final Set<String> foundWords = {};
    
    for (final word in _badWords) {
      // Her harfin kendisinden bir veya daha fazla kez tekrar etmesine izin ver (örn: y+a+r+r+a+k+)
      final repeatedCharPattern = word.split('').map((c) => RegExp.escape(c) + '+').join('');
      
      String pattern;
      if (word.length <= 3) {
        // Kısa kelimelerde kelimenin tam sınırlarını koruyoruz (\b kelime başı ve sonu)
        // Yoksa "tamam" kelimesi içindeki "am" kısmını da yakalar.
        pattern = r'\b' + repeatedCharPattern + r'\b';
      } else {
        // Uzun kelimelerde kelime sınırıyla başlaması yeterli, sonuna gelen ekleri veya tekrarları da yakalasın
        // Örn: "yarrakkk", "salaklar"
        pattern = r'\b' + repeatedCharPattern;
      }

      final regex = RegExp(pattern, caseSensitive: false, unicode: true);
      if (regex.hasMatch(text)) {
        foundWords.add(word);
      }
    }
    
    return foundWords.toList();
  }
}
