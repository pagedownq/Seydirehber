import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'dart:convert';
import '../models/news_model.dart';
import 'package:flutter/foundation.dart';

final newsProvider = FutureProvider<List<NewsModel>>((ref) async {
  const String baseUrl = 'https://www.seydisehirhaber.com';
  const String categoryUrl = '$baseUrl/kategori/32/seydisehir';
  
  try {
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    };

    // Ana sayfa ve Kategori sayfasını aynı anda çekiyoruz
    final responses = await Future.wait([
      http.get(Uri.parse(baseUrl), headers: headers),
      http.get(Uri.parse(categoryUrl), headers: headers),
    ]).timeout(const Duration(seconds: 15));

    final List<String> uniqueLinks = [];
    final Set<String> seen = {};

    for (var response in responses) {
      if (response.statusCode != 200) continue;
      final document = parser.parse(utf8.decode(response.bodyBytes));
      // /haber/ içeren tüm linkleri bul
      final List<dom.Element> newsLinks = document.querySelectorAll('a[href*="/haber/"]');

      for (var el in newsLinks) {
        String? link = el.attributes['href'];
        // Resim/video galerilerini veya boş linkleri atla
        if (link == null || link.isEmpty || link.contains('resimler/') || link.contains('video/')) continue;
        
        if (!link.startsWith('http')) link = '$baseUrl${link.startsWith('/') ? '' : '/'}$link';
        
        // Kopya (Duplicate) kontrolü
        if (!seen.contains(link)) {
          seen.add(link);
          uniqueLinks.add(link);
        }
        // Toplamda en fazla 30 haber yeterli (performans için)
        if (uniqueLinks.length >= 30) break;
      }
    }

    // Haber detaylarını paralel olarak 5'erli gruplarla çekelim
    List<NewsModel> allNews = [];
    for (var i = 0; i < uniqueLinks.length; i += 5) {
      final end = (i + 5 < uniqueLinks.length) ? i + 5 : uniqueLinks.length;
      final batch = uniqueLinks.sublist(i, end);
      
      final results = await Future.wait(batch.map((link) => _fetchNewsDetail(link, baseUrl)));
      allNews.addAll(results.whereType<NewsModel>());
    }

    // Tarih/ID Sıralaması (En yeni en üstte)
    allNews.sort((a, b) {
      if (a.date != null && b.date != null) return b.date!.compareTo(a.date!);
      final idA = int.tryParse(RegExp(r'/haber/(\d+)/').firstMatch(a.link)?.group(1) ?? '0') ?? 0;
      final idB = int.tryParse(RegExp(r'/haber/(\d+)/').firstMatch(b.link)?.group(1) ?? '0') ?? 0;
      return idB.compareTo(idA);
    });

    return allNews;
  } catch (e) {
    debugPrint('❌ [ERROR] Scraper: $e');
    rethrow;
  }
});

Future<NewsModel?> _fetchNewsDetail(String link, String baseUrl) async {
  try {
    final response = await http.get(Uri.parse(link), headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;
    final doc = parser.parse(utf8.decode(response.bodyBytes));

    // 1. Başlık (HTML kodlarından temizle)
    String rawTitle = doc.querySelector('h1')?.text.trim() ?? 
                   doc.querySelector('meta[property="og:title"]')?.attributes['content']?.replaceAll(' | Seydisehirhaber.com', '').trim() ?? 
                   'Haber';
    String title = parser.parseFragment(rawTitle).text?.trim() ?? rawTitle;

    // 2. Resim (Hiyerarşik Arama)
    String imageUrl = '';
    
    // a. OG:Image (En temiz kaynak)
    imageUrl = doc.querySelector('meta[property="og:image"]')?.attributes['content'] ?? '';
    
    // b. Facebook Paylaşım Linkindeki Resim
    if (imageUrl.isEmpty || imageUrl.contains('placeholder')) {
      final fbLink = doc.querySelector('a[href*="facebook.com/sharer"]')?.attributes['href'];
      if (fbLink != null && fbLink.contains('picture=')) {
        final uri = Uri.parse(fbLink);
        imageUrl = uri.queryParameters['picture'] ?? '';
      }
    }
    
    // c. H1 altındaki ilk büyük resim
    if (imageUrl.isEmpty) {
      final articleImg = doc.querySelector('article img, .news-content img, .entry-content img');
      imageUrl = articleImg?.attributes['src'] ?? '';
    }

    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = '$baseUrl${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
    }

    // 3. Tarih ve Saat
    DateTime? date;
    String pubDate = 'Güncel';
    
    // a. Meta Published Time (Saniye hassasiyetinde)
    final metaTime = doc.querySelector('meta[property="article:published_time"]')?.attributes['content'];
    if (metaTime != null) {
      date = DateTime.tryParse(metaTime)?.toLocal();
    }
    
    // b. Sayfa içindeki metinden saat çekme
    if (date == null) {
      final match = RegExp(r'(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2})').firstMatch(doc.body?.text ?? '');
      if (match != null) {
        date = DateTime(
          int.parse(match.group(3)!), 
          int.parse(match.group(2)!), 
          int.parse(match.group(1)!),
          int.parse(match.group(4)!),
          int.parse(match.group(5)!),
        );
      }
    }

    // c. Resim URL'sinden Unix Timestamp (Son çare saat için)
    if (date == null && imageUrl.isNotEmpty) {
      final tsMatch = RegExp(r'(\d{10})_').firstMatch(imageUrl);
      if (tsMatch != null) {
        date = DateTime.fromMillisecondsSinceEpoch(int.parse(tsMatch.group(1)!) * 1000);
      }
    }

    if (date != null) {
      final trMonths = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
      pubDate = '${date.day} ${trMonths[date.month]}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // 4. Açıklama (HTML kodlarından temizle)
    String rawDesc = doc.querySelector('meta[name="description"]')?.attributes['content']?.trim() ?? '';
    String description = parser.parseFragment(rawDesc).text?.replaceAll('&nbsp;', ' ').trim() ?? '';

    return NewsModel.fromHtml(
      title: title,
      link: link,
      imageUrl: imageUrl,
      description: description,
      pubDate: pubDate,
      source: 'Seydişehir Haber',
      date: date,
    );
  } catch (e) {
    return null;
  }
}
