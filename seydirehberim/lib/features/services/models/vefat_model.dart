class Vefat {
  final String name;
  final String relative;
  final String date;
  final String detail;
  final String neighborhood;
  final String contact;

  Vefat({
    required this.name,
    required this.relative,
    required this.date,
    required this.detail,
    required this.neighborhood,
    required this.contact,
  });

  factory Vefat.fromHtml(List<String> cells) {
    return Vefat(
      name: cells.length > 0 ? cells[0].trim() : '',
      relative: cells.length > 1 ? cells[1].trim() : '',
      date: cells.length > 2 ? cells[2].trim() : '',
      detail: cells.length > 3 ? cells[3].trim() : '',
      neighborhood: cells.length > 4 ? cells[4].trim() : '',
      contact: cells.length > 5 ? cells[5].trim() : '',
    );
  }

  DateTime? get dateTime {
    try {
      // "5 Mayıs 2026" veya "05.05.2026" formatlarını destekler
      final cleanedDate = date.trim().toLowerCase();
      
      // Eğer nokta ile ayrılmışsa (05.05.2026)
      if (cleanedDate.contains('.')) {
        final parts = cleanedDate.split('.');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } 
      
      // Eğer boşluk ile ayrılmışsa (5 mayıs 2026)
      final parts = cleanedDate.split(' ');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final year = int.parse(parts[2]);
        final monthStr = parts[1];
        
        int month = 1;
        if (monthStr.contains('ocak')) month = 1;
        else if (monthStr.contains('şubat')) month = 2;
        else if (monthStr.contains('mart')) month = 3;
        else if (monthStr.contains('nisan')) month = 4;
        else if (monthStr.contains('mayıs')) month = 5;
        else if (monthStr.contains('haziran')) month = 6;
        else if (monthStr.contains('temmuz')) month = 7;
        else if (monthStr.contains('ağustos')) month = 8;
        else if (monthStr.contains('eylül')) month = 9;
        else if (monthStr.contains('ekim')) month = 10;
        else if (monthStr.contains('kasım')) month = 11;
        else if (monthStr.contains('aralık')) month = 12;
        
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }
}
