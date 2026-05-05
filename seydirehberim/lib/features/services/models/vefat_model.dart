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
      final parts = date.split('.');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // Yıl
          int.parse(parts[1]), // Ay
          int.parse(parts[0]), // Gün
        );
      }
    } catch (_) {}
    return null;
  }
}
