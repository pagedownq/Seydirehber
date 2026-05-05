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
      final now = DateTime.now();
      final oneMonthAgo = now.subtract(const Duration(days: 30));
      final oneMonthLater = now.add(const Duration(days: 30));

      for (var row in rows) {
        var cells = row.querySelectorAll('th, td').map((e) => e.text).toList();
        if (cells.length >= 4) {
          final vefat = Vefat.fromHtml(cells);
          final vefatDate = vefat.dateTime;

          // Eğer tarih ayrıştırılamıyorsa veya belirlediğimiz aralıktaysa listeye ekle
          if (vefatDate == null || 
              (vefatDate.isAfter(oneMonthAgo) && vefatDate.isBefore(oneMonthLater))) {
            vefatList.add(vefat);
          }
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
