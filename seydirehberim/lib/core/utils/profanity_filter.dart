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

  static bool _isLetter(String char) {
    if (char.isEmpty) return false;
    return RegExp(r'[a-zA-ZğüşıöçĞÜŞİÖÇ]').hasMatch(char);
  }

  static bool _isWholeWordMatch(String text, int start, int end) {
    // Check preceding character
    if (start > 0) {
      final prevChar = text.substring(start - 1, start);
      if (_isLetter(prevChar)) return false;
    }
    // Check succeeding character
    if (end < text.length) {
      final nextChar = text.substring(end, end + 1);
      if (_isLetter(nextChar)) return false;
    }
    return true;
  }

  static bool hasProfanity(String text) {
    return findProfanity(text).isNotEmpty;
  }

  /// Verilen metni kontrol eder ve kötü kelimeleri sansürler.
  static String censor(String text) {
    if (text.isEmpty) return text;
    
    List<_ProfanityMatch> matchesToCensor = [];
    
    for (final word in _badWords) {
      final repeatedCharPattern = word.split('').map((c) => RegExp.escape(c) + '+').join('');
      final regex = RegExp(repeatedCharPattern, caseSensitive: false, unicode: true);
      
      for (final match in regex.allMatches(text)) {
        if (_isWholeWordMatch(text, match.start, match.end)) {
          matchesToCensor.add(_ProfanityMatch(match.start, match.end));
        }
      }
    }
    
    if (matchesToCensor.isEmpty) return text;
    
    // Sort matches: first by start ascending, then by end descending
    matchesToCensor.sort((a, b) {
      int cmp = a.start.compareTo(b.start);
      if (cmp != 0) return cmp;
      return b.end.compareTo(a.end);
    });
    
    // Merge overlapping or adjacent matches
    List<_ProfanityMatch> mergedMatches = [];
    for (final match in matchesToCensor) {
      if (mergedMatches.isEmpty) {
        mergedMatches.add(match);
      } else {
        final last = mergedMatches.last;
        if (match.start < last.end) {
          if (match.end > last.end) {
            mergedMatches[mergedMatches.length - 1] = _ProfanityMatch(last.start, match.end);
          }
        } else {
          mergedMatches.add(match);
        }
      }
    }
    
    // Replace from right to left
    String result = text;
    for (int i = mergedMatches.length - 1; i >= 0; i--) {
      final match = mergedMatches[i];
      final length = match.end - match.start;
      final replacement = '*' * length;
      result = result.replaceRange(match.start, match.end, replacement);
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
      
      final regex = RegExp(repeatedCharPattern, caseSensitive: false, unicode: true);
      for (final match in regex.allMatches(text)) {
        if (_isWholeWordMatch(text, match.start, match.end)) {
          foundWords.add(word);
          break;
        }
      }
    }
    
    return foundWords.toList();
  }
}

class _ProfanityMatch {
  final int start;
  final int end;
  _ProfanityMatch(this.start, this.end);
}
