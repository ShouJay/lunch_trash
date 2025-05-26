import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _membersKey = 'lunch_members';
  static const String _historyKey = 'garbage_history';

  // 獲取成員列表
  Future<List<Map<String, dynamic>>> getMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final membersJson = prefs.getStringList(_membersKey) ?? [];
    return membersJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }

  // 保存成員列表
  Future<void> saveMembers(List<Map<String, dynamic>> members) async {
    final prefs = await SharedPreferences.getInstance();
    final membersJson = members.map((member) => jsonEncode(member)).toList();
    await prefs.setStringList(_membersKey, membersJson);
  }

  // 獲取歷史記錄
  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  // 保存歷史記錄
  Future<void> saveHistory(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, history);
  }

  // 添加今天的抽籤記錄
  Future<void> addTodayDraw(String person) async {
    final history = await getHistory();
    final today = DateTime.now().toString().split(' ')[0];

    // 移除今天之前的記錄
    history.removeWhere((record) => record.startsWith(today));

    // 添加今天的記錄
    history.add('$today: $person');

    // 保存更新後的歷史紀錄
    await saveHistory(history);
  }
}
