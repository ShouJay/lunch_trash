import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<String> _history = [];
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _storageService.getHistory();
    setState(() {
      _history = history;
    });
  }

  // 嘗試解析紀錄格式："2024-05-01 抽中: 王小明"
  Map<String, String> _parseRecord(String record) {
    final match =
        RegExp(r'^(\d{4}-\d{2}-\d{2})[\s\S]*?([\u4e00-\u9fa5A-Za-z0-9_]+)')
            .firstMatch(record);
    if (match != null && match.groupCount >= 2) {
      return {
        'date': match.group(1) ?? '',
        'person': match.group(2) ?? '',
      };
    }
    // fallback: 全部顯示在 person
    return {'date': '', 'person': record};
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '歷史紀錄',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暫無歷史紀錄',
                            style: TextStyle(color: Colors.grey, fontSize: 18)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _history.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final parsed = _parseRecord(_history[index]);
                      final date = parsed['date'] ?? '';
                      final person = parsed['person'] ?? '';
                      String dateStr = date;
                      try {
                        if (date.isNotEmpty) {
                          final dt = DateTime.parse(date);
                          dateStr = DateFormat('yyyy年MM月dd日').format(dt);
                        }
                      } catch (_) {}
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          title: Text(
                            person,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: dateStr.isNotEmpty
                              ? Text(dateStr,
                                  style: const TextStyle(color: Colors.grey))
                              : null,
                          trailing:
                              const Icon(Icons.delete, color: Colors.amber),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
