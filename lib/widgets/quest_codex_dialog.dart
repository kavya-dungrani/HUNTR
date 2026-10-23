import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../models/quest_library.dart';
import '../providers/hunter_provider.dart';
import '../theme/hunter_theme.dart';

class QuestCodexDialog extends StatefulWidget {
  const QuestCodexDialog({super.key});

  @override
  State<QuestCodexDialog> createState() => _QuestCodexDialogState();
}

class _QuestCodexDialogState extends State<QuestCodexDialog> {
  QuestCategory? _selectedCategory;
  DifficultyGrade? _selectedDifficulty;

  @override
  Widget build(BuildContext context) {
    final hunter = Provider.of<HunterProvider>(context, listen: false);

    var filtered = questLibrary.where((q) {
      if (_selectedCategory != null && q.category != _selectedCategory) {
        return false;
      }
      if (_selectedDifficulty != null && q.difficulty != _selectedDifficulty) {
        return false;
      }
      return true;
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFF0b0f19),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HunterTheme.cyan.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: HunterTheme.cyan.withValues(alpha: 0.2),
              blurRadius: 25,
            ),
          ],
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1c2438))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HunterTheme.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book, color: HunterTheme.cyan, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HUNTER CODEX',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'Select pre-registered trials to awaken your potential',
                          style: TextStyle(color: HunterTheme.slate400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: HunterTheme.slate400),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Category Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildCategoryChip('ALL', null),
                  _buildCategoryChip('PHYSICAL', QuestCategory.physical),
                  _buildCategoryChip('CODING', QuestCategory.coding),
                  _buildCategoryChip('STUDY', QuestCategory.study),
                  _buildCategoryChip('MENTAL', QuestCategory.mental),
                  _buildCategoryChip('DISCIPLINE', QuestCategory.discipline),
                  _buildCategoryChip('HEALTH', QuestCategory.health),
                ],
              ),
            ),

            // Quest List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No trials found for this category',
                        style: TextStyle(color: HunterTheme.slate500),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final quest = filtered[idx];
                        final diffColor = Color(getDifficultyColor(quest.difficulty));
                        final statDef = hunterStats[quest.stat]!;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121726),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF20283e)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Difficulty badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: diffColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: diffColor),
                                    ),
                                    child: Text(
                                      quest.difficulty.name,
                                      style: TextStyle(
                                        color: diffColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Stat badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(statDef.color).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+${statDef.code.name}',
                                      style: TextStyle(
                                        color: Color(statDef.color),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${quest.target} ${quest.unit}',
                                    style: const TextStyle(
                                      color: HunterTheme.cyanLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                quest.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                quest.description,
                                style: const TextStyle(
                                  color: HunterTheme.slate400,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '+${difficultyXp[quest.difficulty]} XP',
                                    style: const TextStyle(
                                      color: HunterTheme.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      hunter.acceptLibraryQuest(quest);
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(0xFF161f38),
                                          content: Text(
                                            'Trial Accepted: ${quest.name}',
                                            style: const TextStyle(color: HunterTheme.cyanLight),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('ACCEPT'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HunterTheme.cyan.withValues(alpha: 0.2),
                                      foregroundColor: HunterTheme.cyan,
                                      side: const BorderSide(color: HunterTheme.cyan),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, QuestCategory? cat) {
    final isSelected = _selectedCategory == cat;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = cat;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? HunterTheme.cyan : const Color(0xFF151b2c),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? HunterTheme.cyan : const Color(0xFF26324f),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : HunterTheme.slate300,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
