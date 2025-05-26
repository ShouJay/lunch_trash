import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/result_card.dart';

class DrawPage extends StatefulWidget {
  const DrawPage({super.key});

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  final StorageService _storageService = StorageService();
  List<Map<String, dynamic>> _lunchMembers = [];
  String? _selectedPerson;
  DateTime? _drawTime;
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _storageService.getMembers();
      if (mounted) {
        setState(() {
          _lunchMembers = members;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('載入成員列表失敗')),
        );
      }
    }
  }

  void _showShareDialog() {
    if (_selectedPerson == null || _drawTime == null) return;

    final shareText = '''
今日倒垃圾抽籤結果
今天倒垃圾的人是：$_selectedPerson
抽籤時間：${_drawTime!.toString()}
''';

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('分享結果'),
          content: SelectableText(shareText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('關閉'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMemberSelectionDialog() async {
    if (!mounted) return;

    final tempMembers = List<Map<String, dynamic>>.from(_lunchMembers);
    bool? shouldDraw;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('選擇參與抽籤的成員'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              for (var member in tempMembers) {
                                member['selected'] = true;
                              }
                            });
                          },
                          child: const Text('全選'),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              for (var member in tempMembers) {
                                member['selected'] = false;
                              }
                            });
                          },
                          child: const Text('取消全選'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tempMembers.length,
                        itemBuilder: (context, index) {
                          final member = tempMembers[index];
                          return CheckboxListTile(
                            title: Text(member['name']?.toString() ?? ''),
                            value: member['selected'] == true,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                member['selected'] = value ?? false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    shouldDraw = false;
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    shouldDraw = true;
                    Navigator.of(context).pop();
                  },
                  child: const Text('開始抽籤'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldDraw == true && mounted) {
      setState(() {
        _lunchMembers = tempMembers;
      });
      await _storageService.saveMembers(_lunchMembers);
      _startDraw();
    }
  }

  Future<void> _startDraw() async {
    if (!mounted || _isDrawing) return;

    final selectedMembers =
        _lunchMembers.where((member) => member['selected'] == true).toList();

    if (selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請選擇至少一位成員參與抽籤'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isDrawing = true;
      _selectedPerson = null;
      _drawTime = null;
    });

    try {
      // 抽籤動畫
      for (int i = 0; i < 10; i++) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          final random =
              DateTime.now().millisecondsSinceEpoch % selectedMembers.length;
          _selectedPerson = selectedMembers[random]['name']?.toString() ?? '';
        });
      }

      // 最終結果
      if (!mounted) return;
      final random =
          DateTime.now().millisecondsSinceEpoch % selectedMembers.length;
      final selectedPerson = selectedMembers[random]['name']?.toString() ?? '';

      setState(() {
        _selectedPerson = selectedPerson;
        _drawTime = DateTime.now();
        _isDrawing = false;
      });

      await _storageService.addTodayDraw(selectedPerson);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDrawing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('抽籤過程發生錯誤，請重試'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_selectedPerson == null || _drawTime == null) ...[
            const Text(
              '準備抽籤',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '目前有 ${_lunchMembers.length} 位成員',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isDrawing ? null : _showMemberSelectionDialog,
              icon: const Icon(Icons.shuffle),
              label: Text(
                _isDrawing ? '抽籤中...' : '選擇成員並抽籤',
                style: const TextStyle(fontSize: 20),
              ),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ] else ...[
            ResultCard(
              selectedPerson: _selectedPerson!,
              drawTime: _drawTime!,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _isDrawing
                      ? null
                      : () {
                          setState(() {
                            _selectedPerson = null;
                            _drawTime = null;
                          });
                        },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新抽籤'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _isDrawing ? null : _showShareDialog,
                  icon: const Icon(Icons.share),
                  label: const Text('分享結果'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _isDrawing ? null : _showMemberSelectionDialog,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('選擇其他成員'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
