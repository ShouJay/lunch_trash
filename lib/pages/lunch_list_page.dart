import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../data/default_members.dart';

class LunchListPage extends StatefulWidget {
  const LunchListPage({super.key});

  @override
  State<LunchListPage> createState() => _LunchListPageState();
}

class _LunchListPageState extends State<LunchListPage> {
  final List<Map<String, dynamic>> _lunchMembers = [];
  final TextEditingController _nameController = TextEditingController();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await _storageService.getMembers();
    if (members.isEmpty) {
      // 如果是第一次載入，使用預設名單
      final defaultMembers = DefaultMembers.members
          .map((name) => {
                'name': name,
                'selected': true,
              })
          .toList();
      await _storageService.saveMembers(defaultMembers);
      setState(() {
        _lunchMembers.clear();
        _lunchMembers.addAll(defaultMembers);
      });
    } else {
      setState(() {
        _lunchMembers.clear();
        _lunchMembers.addAll(members);
      });
    }
  }

  void _addMember() {
    if (_nameController.text.isNotEmpty) {
      setState(() {
        _lunchMembers.add({
          'name': _nameController.text,
          'selected': true,
        });
        _nameController.clear();
      });
      _storageService.saveMembers(_lunchMembers);
    }
  }

  void _removeMember(int index) {
    setState(() {
      _lunchMembers.removeAt(index);
    });
    _storageService.saveMembers(_lunchMembers);
  }

  void _toggleMemberSelection(int index) {
    setState(() {
      _lunchMembers[index]['selected'] = !_lunchMembers[index]['selected'];
    });
    _storageService.saveMembers(_lunchMembers);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '新增成員',
                    hintText: '請輸入姓名',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _addMember,
                child: const Text('新增'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '點擊成員可以切換是否參與抽籤',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _lunchMembers.length,
              itemBuilder: (context, index) {
                final member = _lunchMembers[index];
                return ListTile(
                  title: Text(member['name']),
                  leading: Checkbox(
                    value: member['selected'],
                    onChanged: (_) => _toggleMemberSelection(index),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.amber),
                    onPressed: () => _removeMember(index),
                  ),
                  onTap: () => _toggleMemberSelection(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
