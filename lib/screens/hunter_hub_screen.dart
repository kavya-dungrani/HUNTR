import 'friends_screen.dart';
import 'guilds_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../models/daily_system.dart';
import '../providers/hunter_provider.dart';
import '../theme/hunter_theme.dart';
import '../widgets/level_up_dialog.dart';
import '../widgets/quest_codex_dialog.dart';
import '../widgets/add_quest_dialog.dart';
import '../widgets/system_settings_dialog.dart';
import '../widgets/notification_center_dialog.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';

class HunterHubScreen extends StatefulWidget {
  const HunterHubScreen({super.key});

  @override
  State<HunterHubScreen> createState() => _HunterHubScreenState();
}

class _HunterHubScreenState extends State<HunterHubScreen> {
  QuestCategory? _selectedCategory;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 1-second ticker for Dungeon countdowns
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hunter = Provider.of<HunterProvider>(context);
    final profile = hunter.profile;

    if (profile == null) {
      return const Scaffold(
        backgroundColor: HunterTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: HunterTheme.cyan)),
      );
    }

    final rankBadge = getRankBadgeInfo(profile.currentRank);
    final xpInfo = getXpProgress(profile.totalXp);
    final activeDungeon = hunter.activeDungeon;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF060912),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= TOP HUD HEADER =================
                  _buildTopHud(context, hunter, profile, rankBadge),
                  const SizedBox(height: 16),

                  // ================= HP / MP & XP PROGRESS GAUGES =================
                  _buildGaugesCard(profile, xpInfo),
                  const SizedBox(height: 14),

                  // ================= STREAK BANNER =================
                  _buildStreakBanner(profile),
                  const SizedBox(height: 14),

                  // ================= RED GATE / DUNGEON BREAK BANNER =================
                  if (activeDungeon != null && !activeDungeon.completed && !activeDungeon.dismissed)
                    _buildDungeonBreakBanner(context, hunter, activeDungeon),

                  const SizedBox(height: 20),

                  // ================= DAILY QUESTS SECTION =================
                  _buildDailyQuestsSection(context, hunter),
                  const SizedBox(height: 24),

                  // ================= ACTIVE QUESTS SECTION =================
                  _buildActiveQuestsSection(context, hunter),
                  const SizedBox(height: 80), // Padding for bottom FABs
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomActionBar(context),
        ),

        // LEVEL UP OVERLAY MODAL
        if (hunter.showLevelUpModal)
          LevelUpDialog(
            newLevel: hunter.leveledUpTo,
            newRank: hunter.newRankAchieved,
            onDismiss: () => hunter.dismissLevelUpModal(),
          ),
      ],
    );
  }

  // ================= HUD WIDGETS =================

  Widget _buildTopHud(BuildContext context, HunterProvider hunter, HunterProfile profile, ({String label, int color}) rankBadge) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF070B14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          // Avatar / Class Icon
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(rankBadge.color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Color(rankBadge.color), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                profile.currentRank.split('-')[0],
                style: TextStyle(
                  color: Color(rankBadge.color),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.displayName,
                        style: const TextStyle(
                          color: Color(0xFFF0F6FC),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Color(rankBadge.color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        rankBadge.label,
                        style: TextStyle(
                          color: Color(rankBadge.color),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    if (profile.guildTag != null && profile.guildTag!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 0.5),
                        ),
                        child: Text(
                          '[${profile.guildTag}]',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${profile.username} • ${profile.hunterId}',
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Color(0xFF00E5FF), size: 20),
                onPressed: () {
                  showDialog(context: context, builder: (_) => const NotificationCenterDialog());
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings, color: Color(0xFF64748B), size: 20),
                onPressed: () {
                  showDialog(context: context, builder: (_) => const SystemSettingsDialog());
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGaugesCard(HunterProfile profile, ({int currentLevel, int currentProgressXp, int percentage, int totalXp, int xpNeededForNext}) xpInfo) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF070B14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        children: [
          // HP Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('HP (HEALTH)', style: TextStyle(color: HunterTheme.hpColor, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
              Text('${profile.hp} / ${profile.maxHp}', style: const TextStyle(color: HunterTheme.hpColor, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (profile.hp / profile.maxHp).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF180A0E),
              color: HunterTheme.hpColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),

          // MP Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MP (MANA)', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
              Text('${profile.mp} / ${profile.maxMp}', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (profile.mp / profile.maxMp).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF081424),
              color: const Color(0xFF38BDF8),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),

          // XP Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LEVEL ${xpInfo.currentLevel} XP', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
              Text('${xpInfo.currentProgressXp} / ${xpInfo.xpNeededForNext} XP (${xpInfo.percentage}%)', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (xpInfo.percentage / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF061520),
              color: const Color(0xFF00E5FF),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBanner(HunterProfile profile) {
    final bonus = getStreakBonus(profile.streak);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF070B14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.streak} DAY STREAK [ SYSTEM MULTIPLIER ]',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'monospace', letterSpacing: 0.5),
                ),
                Text(
                  bonus > 0 ? 'Active System Boost: +$bonus% Bonus XP on completion' : 'Complete daily quests to activate streak multiplier',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                ),
              ],
            ),
          ),
          if (bonus > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Text(
                '+$bonus%',
                style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDungeonBreakBanner(BuildContext context, HunterProvider hunter, DungeonBreak dungeon) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1c0b13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HunterTheme.red, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: HunterTheme.red.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: HunterTheme.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('EMERGENCY GATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Text(
                'TIME REMAINING: ${dungeon.formattedRemainingTime}',
                style: const TextStyle(color: HunterTheme.red, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: HunterTheme.slate500, size: 18),
                onPressed: () => hunter.dismissDungeonBreak(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dungeon.challenge,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '+${dungeon.xpReward} XP  •  +${dungeon.statXpReward} Stat Points',
                style: const TextStyle(color: HunterTheme.amber, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              ElevatedButton(
                onPressed: () => hunter.completeDungeonBreak(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HunterTheme.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('CONQUER GATE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= DAILY QUESTS (REFERENCE 1 — SOLO LEVELING QUEST INFO) =================

  Widget _buildDailyQuestsSection(BuildContext context, HunterProvider hunter) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF060B18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF00C8E0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C8E0).withValues(alpha: 0.25),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header box: [ (!) QUEST INFO ]
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C8E0).withValues(alpha: 0.12),
                border: Border.all(color: const Color(0xFF00C8E0), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00C8E0), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '!',
                      style: TextStyle(color: Color(0xFF00C8E0), fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'QUEST INFO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      shadows: [Shadow(color: Color(0xFF00C8E0), blurRadius: 10)],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Arrival Announcement
          const Center(
            child: Text(
              '[Daily Quest: Strength Training has arrived.]',
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Centered GOAL with double underline
          Center(
            child: Column(
              children: [
                const Text(
                  'GOAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    shadows: [Shadow(color: Color(0xFF00C8E0), blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 50,
                  height: 2,
                  color: const Color(0xFF00C8E0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Objectives Checklist
          if (hunter.dailyQuests.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '[ALL DAILY QUESTS CONQUERED]',
                  style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            )
          else
            ...hunter.dailyQuests.map((quest) {
              final isDone = quest.completed;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        quest.name,
                        style: TextStyle(
                          color: isDone ? const Color(0xFF4ADE80) : const Color(0xFFE2E8F0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '[${quest.progress}/${quest.target}]',
                          style: TextStyle(
                            color: isDone ? const Color(0xFF4ADE80) : const Color(0xFF00C8E0),
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            if (!isDone) {
                              hunter.incrementProgress(quest.id, 10);
                            }
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFF4ADE80).withValues(alpha: 0.2)
                                  : const Color(0xFF00C8E0).withValues(alpha: 0.08),
                              border: Border.all(
                                color: isDone ? const Color(0xFF4ADE80) : const Color(0xFF00C8E0),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            alignment: Alignment.center,
                            child: isDone
                                ? const Icon(Icons.check, size: 14, color: Color(0xFF4ADE80))
                                : const Text('+', style: TextStyle(color: Color(0xFF00C8E0), fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 18),

          // Bottom Warning Banner
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF00C8E0), width: 0.8)),
            ),
            child: const Text(
              'WARNING: Failure to complete the daily quest will result in an appropriate penalty.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 10.5,
                height: 1.4,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTIVE QUESTS =================

  Widget _buildActiveQuestsSection(BuildContext context, HunterProvider hunter) {
    var filtered = hunter.quests.where((q) {
      if (_selectedCategory == null) return true;
      return q.category == _selectedCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment, color: HunterTheme.purple, size: 18),
                SizedBox(width: 8),
                Text(
                  'ACTIVE TRIALS & QUESTS',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5),
                ),
              ],
            ),
            Text(
              '${hunter.quests.where((q) => q.completed).length} / ${hunter.quests.length}',
              style: const TextStyle(color: HunterTheme.slate400, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Category Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('ALL', null),
              _buildFilterPill('PHYSICAL', QuestCategory.physical),
              _buildFilterPill('CODING', QuestCategory.coding),
              _buildFilterPill('STUDY', QuestCategory.study),
              _buildFilterPill('DISCIPLINE', QuestCategory.discipline),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0e1322),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1d253b)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Text('No quests enrolled in this category.', style: TextStyle(color: HunterTheme.slate400, fontSize: 13)),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(context: context, builder: (_) => const QuestCodexDialog());
                    },
                    icon: const Icon(Icons.menu_book, color: HunterTheme.cyan, size: 18),
                    label: const Text('Open Quest Codex', style: TextStyle(color: HunterTheme.cyan, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          )
        else
          ...filtered.map((quest) => _buildQuestTile(context, hunter, quest)),
      ],
    );
  }

  Widget _buildFilterPill(String title, QuestCategory? cat) {
    final isSel = _selectedCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? HunterTheme.purple : const Color(0xFF131728),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? HunterTheme.purple : const Color(0xFF222c44)),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSel ? Colors.white : HunterTheme.slate400,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestTile(BuildContext context, HunterProvider hunter, Quest quest) {
    final diffColor = Color(getDifficultyColor(quest.difficulty));
    final statDef = hunterStats[quest.stat]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: quest.completed ? const Color(0xFF0c141e) : const Color(0xFF0f1424),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: quest.completed ? HunterTheme.emerald.withValues(alpha: 0.4) : const Color(0xFF1e2840),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Difficulty badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: diffColor),
                ),
                child: Text(
                  quest.difficulty.name,
                  style: TextStyle(color: diffColor, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              // Target Stat
              Text(
                '+${statDef.code.name}',
                style: TextStyle(color: Color(statDef.color), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (quest.isCustom)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, color: HunterTheme.slate500, size: 16),
                  onPressed: () => hunter.deleteQuest(quest.id),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quest.name,
            style: TextStyle(
              color: quest.completed ? HunterTheme.slate400 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              decoration: quest.completed ? TextDecoration.lineThrough : null,
            ),
          ),
          if (quest.description != null && quest.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              quest.description!,
              style: const TextStyle(color: HunterTheme.slate500, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),

          // Progress and Actions
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROGRESS: ${quest.progress} / ${quest.target}',
                      style: const TextStyle(color: HunterTheme.slate400, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (quest.progress / quest.target).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFF1a2236),
                        color: quest.completed ? HunterTheme.emerald : HunterTheme.cyan,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              if (!quest.completed) ...[
                IconButton(
                  icon: const Icon(Icons.add_circle, color: HunterTheme.cyan, size: 28),
                  onPressed: () => hunter.incrementProgress(quest.id),
                ),
                ElevatedButton(
                  onPressed: () => hunter.completeQuest(quest.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HunterTheme.cyan.withValues(alpha: 0.2),
                    foregroundColor: HunterTheme.cyan,
                    side: const BorderSide(color: HunterTheme.cyan),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ] else
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: HunterTheme.emerald, size: 20),
                    SizedBox(width: 4),
                    Text('CLEARED', style: TextStyle(color: HunterTheme.emerald, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM BAR =================

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF070B14),
        border: Border(top: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.25))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomActionItem(
            icon: Icons.menu_book,
            label: 'CODEX',
            color: const Color(0xFF00E5FF),
            onTap: () {
              showDialog(context: context, builder: (_) => const QuestCodexDialog());
            },
          ),
          _buildBottomActionItem(
            icon: Icons.shield,
            label: 'GUILDS',
            color: const Color(0xFFC084FC),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuildsScreen()));
            },
          ),
          _buildBottomActionItem(
            icon: Icons.group,
            label: 'SQUAD',
            color: const Color(0xFF38BDF8),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FriendsScreen()));
            },
          ),
          _buildBottomActionItem(
            icon: Icons.add_box,
            label: '+ QUEST',
            color: const Color(0xFF00E5FF),
            onTap: () {
              showDialog(context: context, builder: (_) => const AddQuestDialog());
            },
          ),
          _buildBottomActionItem(
            icon: Icons.person,
            label: 'STATUS',
            color: const Color(0xFFF59E0B),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          _buildBottomActionItem(
            icon: Icons.leaderboard,
            label: 'RANKS',
            color: const Color(0xFFF43F5E),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
