import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';
import 'dart:convert';
import '../models/news_model.dart';

final newsProvider = FutureProvider<List<NewsModel>>((ref) async {
  final response = await http.get(Uri.parse('https://www.toroslargazetesi.com.tr/rss.xml'));
  
  if (response.statusCode == 200) {
    // Correct encoding for Turkish characters (usually UTF-8 or ISO-8859-9)
    // Most modern sites use UTF-8 now.
    final xml = utf8.decode(response.bodyBytes);
    final myTransformer = Xml2Json();
    myTransformer.parse(xml);
    
    // Using GData convention as it's usually cleaner for RSS
    final jsonStr = myTransformer.toGData();
    final data = json.decode(jsonStr);
    
    final items = data['rss']?['channel']?['item'];
    
    if (items is List) {
      return items.map((item) => NewsModel.fromXmlMap(item)).toList();
    } else if (items is Map<String, dynamic>) {
      return [NewsModel.fromXmlMap(items)];
    }
    
    return [];
  } else {
    throw Exception('Haberler alınamadı: ${response.statusCode}');
  }
});
