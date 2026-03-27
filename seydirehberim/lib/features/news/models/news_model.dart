class NewsModel {
  final String title;
  final String link;
  final String description;
  final String imageUrl;
  final String pubDate;

  NewsModel({
    required this.title,
    required this.link,
    required this.description,
    required this.imageUrl,
    required this.pubDate,
  });

  factory NewsModel.fromXmlMap(Map<String, dynamic> item) {
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
    
    // Description / Content
    String rawDesc = getValue(item['description'] ?? item['content:encoded'] ?? item['content\$encoded']);
    
    // Image Extraction Strategy:
    // 1. media:content or media$content
    // 2. enclosure
    // 3. media:thumbnail
    // 4. Regex from description
    
    String img = '';
    
    // Try media:content (GData usually maps media:content to media$content or similar)
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
    );
  }
}
