import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../theme/hunter_theme.dart';

class AddQuestDialog extends StatefulWidget {
  const AddQuestDialog({super.key});

  @override
  State<AddQuestDialog> createState() => _AddQuestDialogState();
}

class _AddQuestDialogState extends State<AddQuestDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController(text: '1');

  DifficultyGrade _difficulty = DifficultyGrade.E;
  QuestCategory _category = QuestCategory.physical;
  HunterStat _stat = HunterStat.STR;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0d1220),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HunterTheme.purple.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: HunterTheme.purple.withValues(alpha: 0.25),
              blurRadius: 30,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CREATE CUSTOM QUEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: HunterTheme.slate400),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              const Text('QUEST NAME', style: TextStyle(color: HunterTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. 50 Pull-ups or 2-Hour Math Deep Work',
                  hintStyle: const TextStyle(color: HunterTheme.slate500, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF141a2e),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              // Description Field
              const Text('DESCRIPTION', style: TextStyle(color: HunterTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rules and requirements to verify completion',
                  hintStyle: const TextStyle(color: HunterTheme.slate500, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF141a2e),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              // Target Count
              const Text('TARGET QUANTITY (REPS/MINUTES/PAGES)', style: TextStyle(color: HunterTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '1',
                  filled: true,
                  fillColor: const Color(0xFF141a2e),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Category Selection
              const Text('QUEST CATEGORY', style: TextStyle(color: HunterTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  QuestCategory.physical,
                  QuestCategory.coding,
                  QuestCategory.study,
                  QuestCategory.mental,
                  QuestCategory.discipline,
                  QuestCategory.health,
                ].map((c) {
                  final isSelected = _category == c;
                  return ChoiceChip(
                    label: Text(getCategoryLabel(c), style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    selected: isSelected,
                    selectedColor: HunterTheme.cyan,
                    backgroundColor: const Color(0xFF141a2e),
                    onSelected: (_) => setState(() => _category = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Difficulty Grade
              const Text('DIFFICULTY GRADE', style: TextStyle(color: HunterTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: DifficultyGrade.values.map((d) {
                  final isSelected = _difficulty == d;
                  final color = Color(getDifficultyColor(d));
                  return ChoiceChip(
                    label: Text(d.name, style: TextStyle(color: isSelected ? Colors.black : color, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: const Color(0xFF141a2e),
                    onSelected: (_) => setState(() => _difficulty = d),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Stat Association
              const Text('TARGET STAT BOOST', style: TextStyle(color: HunterTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: HunterStat.values.map((s) {
                  final isSelected = _stat == s;
                  final statDef = hunterStats[s]!;
                  return ChoiceChip(
                    label: Text(s.name, style: TextStyle(color: isSelected ? Colors.black : Color(statDef.color), fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: Color(statDef.color),
                    backgroundColor: const Color(0xFF141a2e),
                    onSelected: (_) => setState(() => _stat = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) return;
                    final target = int.tryParse(_targetController.text) ?? 1;

                    final newQuest = Quest(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      name: title,
                      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                      difficulty: _difficulty,
                      category: _category,
                      stat: _stat,
                      target: target > 0 ? target : 1,
                      isCustom: true,
                    );

                    Provider.of<HunterProvider>(context, listen: false).addCustomQuest(newQuest);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HunterTheme.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('ENROLL QUEST', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
