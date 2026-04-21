import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';
import 'dart:convert';
import '../models/news_model.dart';

final newsProvider = FutureProvider<List<NewsModel>>((ref) async {
  final Map<String, String> sources = {
    'Seydişehir\'in Sesi': 'https://www.seydisehirinsesi.com.tr/rss.xml',
  };

  final List<NewsModel> allNews = [];

  final results = await Future.wait(
    sources.entries.map((entry) async {
      try {
        final response = await http.get(
          Uri.parse(entry.value),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/xml, text/xml, */*',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          // allowMalformed: true helps with Turkish characters in legacy feeds
          final xml = utf8.decode(response.bodyBytes, allowMalformed: true);
          final myTransformer = Xml2Json();
          myTransformer.parse(xml);
          
          final jsonStr = myTransformer.toGData();
          final data = json.decode(jsonStr);
          
          final items = data['rss']?['channel']?['item'];
          
          List<NewsModel> sourceNews = [];
          if (items is List) {
            sourceNews = items.map((item) => NewsModel.fromXmlMap(item, entry.key)).toList();
          } else if (items is Map<String, dynamic>) {
            sourceNews = [NewsModel.fromXmlMap(items, entry.key)];
          }
          return sourceNews;
        } else {
          print('RSS Fetch Error (${entry.key}): Status ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching RSS from ${entry.key}: $e');
      }
      return <NewsModel>[];
    }),
  );

  for (var newsList in results) {
    allNews.addAll(newsList);
  }

  if (allNews.isEmpty) {
    throw Exception('Şu an haberlere ulaşılamıyor. Lütfen daha sonra tekrar deneyin.');
  }

  // Sort by date (newest first)
  allNews.sort((a, b) {
    if (a.date == null && b.date == null) return 0;
    if (a.date == null) return 1;
    if (b.date == null) return -1;
    return b.date!.compareTo(a.date!);
  });

  return allNews;
});
