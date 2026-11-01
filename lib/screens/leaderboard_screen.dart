import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/player_profile_dialog.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedRankFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<HunterProvider>(context).profile;

    return Scaffold(
      backgroundColor: const Color(0xFF030509),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[ SYSTEM // GLOBAL HUNTER REGISTRY ]',
              style: TextStyle(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                fontSize: 10,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'HUNTER LEADERBOARD',
              style: TextStyle(
                color: Color(0xFFF0F6FC),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF00E5FF).withValues(alpha: 0.2), height: 1),
        ),
      ),
      body: Column(
        children: [
          // 1. Rank Filter Tabs: ALL, S, A, B, C, D, E
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF070B14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ALL', 'S', 'A', 'B', 'C', 'D', 'E'].map((rf) {
                  final isSel = _selectedRankFilter == rf;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRankFilter = rf),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF00E5FF).withValues(alpha: 0.15) : const Color(0xFF0A0F1D),
                        border: Border.all(
                          color: isSel ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        rf == 'ALL' ? '[ ALL RANKS ]' : '[ $rf-RANK ]',
                        style: TextStyle(
                          color: isSel ? const Color(0xFF00E5FF) : const Color(0xFF64748B),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 2. User Standing HUD (Pinned)
          if (userProfile != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF070B14),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF00E5FF)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userProfile.currentRank.split('-')[0],
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        fontFamily: 'monospace',
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
                            Text(
                              userProfile.displayName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Level ${userProfile.currentLevel} • ${userProfile.currentRank} • ${userProfile.hunterId}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${userProfile.totalXp} XP',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Text(
                        'REGISTERED',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 3. Real-Time Leaderboard Stream
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirebaseService.instance.streamLeaderboard(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                  );
                }

                var list = snapshot.data ?? [];

                // Filter by selected rank tab
                if (_selectedRankFilter != 'ALL') {
                  list = list.where((h) {
                    final r = (h['rank'] ?? h['currentRank'] ?? '').toString();
                    return r.startsWith(_selectedRankFilter);
                  }).toList();
                }

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFF475569), size: 36),
                        const SizedBox(height: 12),
                        const Text(
                          '[ NO HUNTERS REGISTERED IN THIS TIER ]',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final h = list[idx];
                    final rank = (h['rank'] ?? h['currentRank'] ?? 'E-Rank').toString();
                    final badgeInfo = getRankBadgeInfo(rank);
                    final isTop3 = idx < 3;
                    final targetUid = (h['id'] ?? h['uid'] ?? '').toString();

                    final borderCol = idx == 0
                        ? const Color(0xFFF59E0B) // Gold
                        : idx == 1
                            ? const Color(0xFFCBD5E1) // Silver
                            : idx == 2
                                ? const Color(0xFFD97706) // Bronze
                                : Colors.white.withValues(alpha: 0.08);

                    final totalXp = (h['totalXp'] is num)
                        ? (h['totalXp'] as num).toInt()
                        : int.tryParse(h['totalXp']?.toString() ?? '0') ?? 0;

                    final guildTag = h['guildTag']?.toString();

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070B14),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isTop3 ? borderCol.withValues(alpha: 0.5) : borderCol,
                          width: isTop3 ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Rank Number #01, #02...
                          Container(
                            width: 32,
                            alignment: Alignment.center,
                            child: Text(
                              '#${(idx + 1).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: idx == 0
                                    ? const Color(0xFFF59E0B)
                                    : idx == 1
                                        ? const Color(0xFFCBD5E1)
                                        : idx == 2
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF64748B),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Rank Badge Box
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(badgeInfo.color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Color(badgeInfo.color).withValues(alpha: 0.5)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              rank.split('-')[0],
                              style: TextStyle(
                                color: Color(badgeInfo.color),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Hunter Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        h['displayName'] ?? 'Hunter',
                                        style: const TextStyle(
                                          color: Color(0xFFF0F6FC),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (guildTag != null && guildTag.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(2),
                                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 0.5),
                                        ),
                                        child: Text(
                                          '[$guildTag]',
                                          style: const TextStyle(
                                            color: Color(0xFF00E5FF),
                                            fontSize: 8.5,
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
                                  '@${h['username'] ?? 'hunter'} • Lv.${h['level'] ?? 1} • ${h['equippedTitle'] ?? 'The Awakened'}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // XP and Dossier Button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$totalXp XP',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  if (targetUid.isNotEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (_) => PlayerProfileDialog(
                                        playerUid: targetUid,
                                        initialPlayer: h,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 0.5),
                                  ),
                                  child: const Text(
                                    'DOSSIER',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 9,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
