import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../models/achievements.dart';
import '../providers/hunter_provider.dart';
import '../theme/hunter_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hunter = Provider.of<HunterProvider>(context);
    final profile = hunter.profile;

    if (profile == null) {
      return const Scaffold(
        backgroundColor: HunterTheme.bgDark,
        body: Center(child: Text('Hunter Not Awakened', style: TextStyle(color: Colors.white))),
      );
    }

    final rankBadge = getRankBadgeInfo(profile.currentRank);
    final xpInfo = getXpProgress(profile.totalXp);

    // Calculate Combat Power Rating
    int combatPower = (profile.currentLevel * 45) +
        ((profile.stats[HunterStat.STR] ?? 10) * 12) +
        ((profile.stats[HunterStat.AGI] ?? 10) * 11) +
        ((profile.stats[HunterStat.VIT] ?? 10) * 10) +
        ((profile.stats[HunterStat.INT] ?? 10) * 13) +
        ((profile.stats[HunterStat.PERC] ?? 10) * 9);

    return Scaffold(
      backgroundColor: const Color(0xFF060913),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0f1d),
        elevation: 0,
        title: const Text(
          'STATUS WINDOW',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: HunterTheme.cyan),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF141c2e),
                  content: Text('Hunter Profile: ${profile.displayName} (${profile.currentRank}) - Power: $combatPower'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: HunterTheme.red),
            tooltip: 'Logout Hunter License',
            onPressed: () => _confirmSignOut(context, hunter),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Holographic Status Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF0c1020),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HunterTheme.cyan.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: HunterTheme.cyan.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar / Class Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161d33),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: HunterTheme.cyan),
                        ),
                        child: const Center(
                          child: Icon(Icons.shield, color: HunterTheme.cyan, size: 36),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  profile.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Spacer(),
                                // Rank Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(rankBadge.color).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Color(rankBadge.color)),
                                  ),
                                  child: Text(
                                    rankBadge.label,
                                    style: TextStyle(
                                      color: Color(rankBadge.color),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.equippedTitle.isNotEmpty ? profile.equippedTitle : 'The Awakened',
                              style: const TextStyle(color: HunterTheme.amber, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.hunterId,
                              style: const TextStyle(color: HunterTheme.slate400, fontSize: 12, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF1c253c), height: 28),

                  // Level, Combat Power, Quests Done
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStat('LEVEL', '${profile.currentLevel}', HunterTheme.cyanLight),
                      _buildSummaryStat('COMBAT POWER', '$combatPower', HunterTheme.pink),
                      _buildSummaryStat('QUESTS DONE', '${profile.questsCompleted}', HunterTheme.emerald),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EXP: ${xpInfo.currentProgressXp} / ${xpInfo.xpNeededForNext} (${xpInfo.percentage}%)',
                        style: const TextStyle(color: HunterTheme.cyanLight, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'TOTAL: ${xpInfo.totalXp} XP',
                        style: const TextStyle(color: HunterTheme.slate400, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (xpInfo.percentage / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFF161f36),
                      color: HunterTheme.cyan,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stat Points Available Banner
            if (profile.availableSkillPoints > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF854d0e), Color(0xFFca8a04)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 15),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'UNASSIGNED POINTS: ${profile.availableSkillPoints} SP AVAILABLE',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ),

            // PRIMARY ATTRIBUTES (STR, AGI, VIT, INT, PERC)
            const Text(
              'PRIMARY ATTRIBUTES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            ...HunterStat.values.map((s) {
              final def = hunterStats[s]!;
              final val = profile.stats[s] ?? 10;
              final color = Color(def.color);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0e1322),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1c253c)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withValues(alpha: 0.4)),
                          ),
                          child: Center(
                            child: Text(
                              s.name,
                              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(def.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(def.title, style: const TextStyle(color: HunterTheme.slate400, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(
                          '$val',
                          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                        if (profile.availableSkillPoints > 0) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: HunterTheme.amber, size: 28),
                            onPressed: () => hunter.allocateStatPoint(s),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (val / 100).clamp(0.05, 1.0),
                        backgroundColor: const Color(0xFF151b2c),
                        color: color,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // TITLES SECTION
            const Text(
              'EARNED TITLES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.titles.map((title) {
                final isEquipped = profile.equippedTitle == title;
                return GestureDetector(
                  onTap: () => hunter.equipTitle(title),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isEquipped ? HunterTheme.amber.withValues(alpha: 0.2) : const Color(0xFF121727),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isEquipped ? HunterTheme.amber : const Color(0xFF222c42),
                        width: isEquipped ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isEquipped) ...[
                          const Icon(Icons.check, color: HunterTheme.amber, size: 14),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          title,
                          style: TextStyle(
                            color: isEquipped ? HunterTheme.amber : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ACHIEVEMENTS & BADGES
            const Text(
              'ACHIEVEMENTS & BADGES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allAchievements.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, idx) {
                final ach = allAchievements[idx];
                final isUnlocked = hunter.unlockedAchievements.contains(ach.id);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnlocked ? const Color(0xFF14192b) : const Color(0xFF0b0e18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked ? HunterTheme.cyan.withValues(alpha: 0.4) : const Color(0xFF1c2336),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(ach.icon, style: const TextStyle(fontSize: 20)),
                          const Spacer(),
                          if (isUnlocked)
                            const Icon(Icons.check_circle, color: HunterTheme.emerald, size: 16)
                          else
                            const Icon(Icons.lock, color: HunterTheme.slate600, size: 16),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ach.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : HunterTheme.slate500,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '+${ach.xpReward} XP',
                        style: TextStyle(
                          color: isUnlocked ? HunterTheme.amber : HunterTheme.slate600,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Disconnect / Log Out Button
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context, hunter),
                icon: const Icon(Icons.logout_rounded, color: HunterTheme.red, size: 18),
                label: const Text(
                  'DISCONNECT HUNTER LICENSE (LOG OUT)',
                  style: TextStyle(
                    color: HunterTheme.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4a1921)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, HunterProvider hunter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0e1322),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF28344e)),
        ),
        title: const Text(
          '[ HUNTER LOGOUT ]',
          style: TextStyle(
            color: HunterTheme.red,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'Disconnect your Hunter credentials and return to the Association Gate? You can log back in at any time.',
          style: TextStyle(color: HunterTheme.slate300, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: HunterTheme.slate400)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              await hunter.signOutHunter();
            },
            style: ElevatedButton.styleFrom(backgroundColor: HunterTheme.red),
            child: const Text('LOG OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: HunterTheme.slate400, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
