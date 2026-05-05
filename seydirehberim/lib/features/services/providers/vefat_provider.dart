import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/vefat_model.dart';

final vefatListProvider = FutureProvider<List<Vefat>>((ref) async {
  try {
    final response = await http.get(Uri.parse('https://www.seydisehir.bel.tr/vefatedenler'));
    
    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      var rows = document.querySelectorAll('table.table tbody tr');
      
      List<Vefat> vefatList = [];
      for (var row in rows) {
        var cells = row.querySelectorAll('th, td').map((e) => e.text).toList();
        if (cells.length >= 4) { // En az isim ve detay olmalı
          vefatList.add(Vefat.fromHtml(cells));
        }
      }
      return vefatList;
    } else {
      throw Exception('Belediye sitesine ulaşılamadı: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Vefat ilanları yüklenirken hata oluştu: $e');
  }
});
