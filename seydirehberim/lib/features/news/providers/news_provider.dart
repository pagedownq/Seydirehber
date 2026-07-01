import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'dart:convert';
import '../models/news_model.dart';
import 'package:flutter/foundation.dart';

final newsProvider = FutureProvider<List<NewsModel>>((ref) async {
  const String rssUrl = 'https://seydisehirhaber.com/rss.xml';
  
  try {
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    };

    final response = await http.get(Uri.parse(rssUrl), headers: headers).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('RSS feed returned status code ${response.statusCode}');
    }

    final document = parser.parse(utf8.decode(response.bodyBytes));
    final items = document.querySelectorAll('item');
    final List<NewsModel> allNews = [];

    for (var item in items) {
      final title = parser.parseFragment(item.querySelector('title')?.text ?? '').text?.trim() ?? '';
      var link = item.querySelector('link')?.text.trim() ?? '';
      if (link.isEmpty) {
        link = item.querySelector('guid')?.text.trim() ?? '';
      }
      
      // HTML elementlerini temizle
      final rawDesc = item.querySelector('description')?.text ?? '';
      var description = parser.parseFragment(rawDesc).text?.replaceAll('&nbsp;', ' ').trim() ?? '';
      if (description.length > 200) {
        description = '${description.substring(0, 197)}...';
      }

      // Resim çekme (enclosure veya media:content)
      var imageUrl = item.querySelector('enclosure')?.attributes['url'] ?? '';
      if (imageUrl.isEmpty) {
        final mediaContent = item.getElementsByTagName('media:content');
        if (mediaContent.isNotEmpty) {
          imageUrl = mediaContent.first.attributes['url'] ?? '';
        }
      }

      final pubDateStr = item.querySelector('pubdate')?.text.trim() ?? item.querySelector('pubDate')?.text.trim() ?? '';
      final date = _parseRfc822Date(pubDateStr);
      
      String pubDate = pubDateStr;
      if (date != null) {
        final trMonths = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
        pubDate = '${date.day} ${trMonths[date.month]}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }

      if (title.isNotEmpty && link.isNotEmpty) {
        allNews.add(NewsModel(
          title: title,
          link: link,
          description: description,
          imageUrl: imageUrl,
          pubDate: pubDate,
          source: 'Seydişehir Haber',
          date: date,
        ));
      }
    }

    // Tarihe göre sırala (En yeni en üstte)
    allNews.sort((a, b) {
      if (a.date != null && b.date != null) {
        return b.date!.compareTo(a.date!);
      }
      return 0;
    });

    return allNews;
  } catch (e) {
    debugPrint('❌ [ERROR] RSS Parser: $e');
    rethrow;
  }
});

DateTime? _parseRfc822Date(String dateStr) {
  try {
    var cleaned = dateStr;
    if (cleaned.contains(',')) {
      cleaned = cleaned.split(',')[1].trim();
    }
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length >= 4) {
      final day = int.tryParse(parts[0]) ?? 1;
      final monthStr = parts[1].toLowerCase();
      final year = int.tryParse(parts[2]) ?? 2026;
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

      var date = DateTime(year, month, day, hour, minute, second);
      if (parts.length >= 5) {
        final offsetStr = parts[4];
        if (offsetStr.startsWith('+') || offsetStr.startsWith('-')) {
          final sign = offsetStr.startsWith('+') ? 1 : -1;
          final offsetHours = int.tryParse(offsetStr.substring(1, 3)) ?? 0;
          final offsetMinutes = int.tryParse(offsetStr.substring(3, 5)) ?? 0;
          final utcDate = date.subtract(Duration(hours: sign * offsetHours, minutes: sign * offsetMinutes));
          return utcDate.toLocal();
        }
      }
      return date;
    }
  } catch (_) {}
  return DateTime.tryParse(dateStr);
}
