import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/services/log_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  LogType? _filterType;

  @override
  Widget build(BuildContext context) {
    final allLogs = LogService().logs;
    final filteredLogs = _filterType == null
        ? allLogs
        : allLogs.where((l) => l.type == _filterType).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sistem Logları'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                LogService().clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final text = allLogs.map((l) => '[${l.type.name}] ${l.message}').join('\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tüm loglar kopyalandı')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(child: Text('Log bulunamadı'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return _buildLogCard(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip(null, 'Hepsi'),
          _filterChip(LogType.notification, 'Bildirim'),
          _filterChip(LogType.error, 'Hata'),
          _filterChip(LogType.warning, 'Uyarı'),
          _filterChip(LogType.success, 'Başarılı'),
          _filterChip(LogType.info, 'Bilgi'),
        ],
      ),
    );
  }

  Widget _filterChip(LogType? type, String label) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterType = selected ? type : null;
          });
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildLogCard(AppLog log) {
    final color = {
      LogType.info: Colors.blue,
      LogType.warning: Colors.orange,
      LogType.error: Colors.red,
      LogType.success: Colors.green,
      LogType.notification: Colors.purple,
    }[log.type];

    final icon = {
      LogType.info: Icons.info_outline,
      LogType.warning: Icons.warning_amber_rounded,
      LogType.error: Icons.error_outline,
      LogType.success: Icons.check_circle_outline,
      LogType.notification: Icons.notifications_none_rounded,
    }[log.type];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          log.message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          DateFormat('HH:mm:ss.SSS').format(log.timestamp),
          style: AppTextStyles.caption,
        ),
        children: [
          if (log.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
