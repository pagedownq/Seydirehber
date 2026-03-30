class NewsModel {
  final String title;
  final String link;
  final String description;
  final String imageUrl;
  final String pubDate;
  final String source;
  final DateTime? date;

  NewsModel({
    required this.title,
    required this.link,
    required this.description,
    required this.imageUrl,
    required this.pubDate,
    required this.source,
    required this.date,
  });

  factory NewsModel.fromXmlMap(Map<String, dynamic> item, String sourceName) {
    // Helper to get value from common RSS/JSON variants
    String getValue(dynamic field) {
      if (field == null) return '';
      if (field is String) return field;
      if (field is Map) {
        if (field.containsKey('\$t')) return field['\$t'].toString();
        if (field.containsKey('__cdata')) return field['__cdata'].toString();
        if (field.containsKey('__text')) return field['__text'].toString();
        if (field.containsKey('#text')) return field['#text'].toString();
        // Return first value if it's a map with one key
        if (field.length == 1) return field.values.first.toString();
      }
      return field.toString();
    }

    String title = getValue(item['title']);
    String link = getValue(item['link']);
    String pubDate = getValue(item['pubDate']);
    
    // Parse Date for sorting
    DateTime? date;
    if (pubDate.isNotEmpty) {
      try {
        // 1. Try ISO 8601
        date = DateTime.tryParse(pubDate);
        
        if (date == null) {
          // 2. Try RFC 822/2822 (e.g., Sun, 29 Mar 2026 19:12:19 +0000)
          // Clean up string
          var cleaned = pubDate;
          if (cleaned.contains(',')) {
            cleaned = cleaned.split(',')[1].trim();
          }

          // Format: "29 Mar 2026 19:12:19 +0000"
          final parts = cleaned.split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final day = int.tryParse(parts[0]) ?? 1;
            final monthStr = parts[1].toLowerCase();
            final year = int.tryParse(parts[2]) ?? 2024;
            final timeStr = parts[3];
            
            const months = {
              'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
              'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
            };
            
            final month = months[monthStr.substring(0, 3)] ?? 1;
            
            final timeParts = timeStr.split(':');
            final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
            final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
            final second = timeParts.length > 2 ? int.tryParse(timeParts[2]) ?? 0 : 0;

            date = DateTime(year, month, day, hour, minute, second);
          }
        }
      } catch (_) {
        // Fallback to null
      }
    }

    // Description / Content
    String rawDesc = getValue(item['description'] ?? item['content:encoded'] ?? item['content\$encoded']);
    
    // Image Extraction Strategy
    String img = '';
    
    // Try media:content 
    final mediaContent = item['media:content'] ?? item['media\$content'];
    if (mediaContent != null) {
      if (mediaContent is Map && mediaContent.containsKey('url')) {
        img = mediaContent['url'].toString();
      } else if (mediaContent is List && mediaContent.isNotEmpty) {
        final first = mediaContent.first;
        if (first is Map && first.containsKey('url')) {
          img = first['url'].toString();
        }
      }
    }

    // Try enclosure
    if (img.isEmpty && item['enclosure'] != null) {
      final enclosure = item['enclosure'];
      if (enclosure is Map && enclosure.containsKey('url')) {
        img = enclosure['url'].toString();
      }
    }

    // Try media:thumbnail
    if (img.isEmpty) {
      final thumb = item['media:thumbnail'] ?? item['media\$thumbnail'];
      if (thumb != null && thumb is Map && thumb.containsKey('url')) {
        img = thumb['url'].toString();
      }
    }

    // Fallback: Regex from description
    if (img.isEmpty && rawDesc.isNotEmpty) {
      final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
      final match = imgRegex.firstMatch(rawDesc);
      if (match != null) {
        img = match.group(1) ?? '';
      }
    }

    // Clean description from HTML
    String cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();
    if (cleanDesc.length > 200) {
      cleanDesc = '${cleanDesc.substring(0, 197)}...';
    }

    return NewsModel(
      title: title,
      link: link,
      description: cleanDesc,
      imageUrl: img,
      pubDate: pubDate,
      source: sourceName,
      date: date,
    );
  }
}
