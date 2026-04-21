import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/log_service.dart';
import '../../../core/services/haptic_service.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final LogService _logService = LogService();
  bool _showSuccessOnly = false;
  bool _showErrorsOnly = false;

  @override
  Widget build(BuildContext context) {
    final logs = _logService.logs.where((log) {
      if (_showErrorsOnly && log.type != LogType.error) return false;
      if (_showSuccessOnly && log.type != LogType.success) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sistem Logları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              HapticService.selection();
              setState(() => _logService.clear());
            },
            tooltip: 'Temizle',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.white,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Sadece Hatalar'),
                  selected: _showErrorsOnly,
                  onSelected: (val) => setState(() {
                    _showErrorsOnly = val;
                    if (val) _showSuccessOnly = false;
                  }),
                  selectedColor: AppColors.error.withOpacity(0.2),
                  checkmarkColor: AppColors.error,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Başarılar'),
                  selected: _showSuccessOnly,
                  onSelected: (val) => setState(() {
                    _showSuccessOnly = val;
                    if (val) _showErrorsOnly = false;
                  }),
                  selectedColor: Colors.green.withOpacity(0.2),
                  checkmarkColor: Colors.green,
                ),
              ],
            ),
          ),
          
          // Log List
          Expanded(
            child: logs.isEmpty
                ? const Center(child: Text('Henüz log bulunmuyor.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogCard(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(AppLog log) {
    Color typeColor;
    IconData typeIcon;
    
    switch (log.type) {
      case LogType.error:
        typeColor = AppColors.error;
        typeIcon = Icons.error_rounded;
        break;
      case LogType.warning:
        typeColor = Colors.orange;
        typeIcon = Icons.warning_rounded;
        break;
      case LogType.success:
        typeColor = Colors.green;
        typeIcon = Icons.check_circle_rounded;
        break;
      case LogType.info:
      default:
        typeColor = AppColors.primary;
        typeIcon = Icons.info_rounded;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: typeColor.withOpacity(0.2)),
      ),
      child: ExpansionTile(
        leading: Icon(typeIcon, color: typeColor),
        title: Text(
          log.message,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('HH:mm:ss.SSS').format(log.timestamp),
          style: AppTextStyles.caption,
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          if (log.error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                log.error!,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '${log.message}\n\n${log.error ?? ""}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Log panoya kopyalandı')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Kopyala'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
