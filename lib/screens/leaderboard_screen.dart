import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../services/firebase_service.dart';
import '../theme/hunter_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _hunters = [];
  bool _loading = true;
  String _selectedRankFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    final list = await FirebaseService.instance.fetchLeaderboard();
    if (mounted) {
      setState(() {
        _hunters = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<HunterProvider>(context).profile;

    var displayed = _hunters.where((h) {
      if (_selectedRankFilter == 'ALL') return true;
      return (h['rank'] ?? '').toString().contains(_selectedRankFilter);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF070a14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0f1d),
        elevation: 0,
        title: const Text(
          'GLOBAL HUNTER GUILD',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ALL', 'S-Rank', 'A-Rank', 'B-Rank', 'C-Rank'].map((rf) {
                  final isSel = _selectedRankFilter == rf;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRankFilter = rf),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? HunterTheme.cyan : const Color(0xFF131828),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel ? HunterTheme.cyan : const Color(0xFF222c42),
                        ),
                      ),
                      child: Text(
                        rf,
                        style: TextStyle(
                          color: isSel ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // User standing bar
          if (userProfile != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF162544), Color(0xFF131c36)]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HunterTheme.cyan.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: HunterTheme.cyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.black, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${userProfile.displayName} (YOU)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Level ${userProfile.currentLevel} • ${userProfile.currentRank}',
                          style: const TextStyle(color: HunterTheme.cyanLight, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${userProfile.totalXp} XP',
                    style: const TextStyle(color: HunterTheme.amber, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),

          // Leaderboard list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: HunterTheme.cyan))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayed.length,
                    itemBuilder: (context, idx) {
                      final h = displayed[idx];
                      final rank = (h['rank'] ?? 'E-Rank').toString();
                      final badgeInfo = getRankBadgeInfo(rank);
                      final isTop3 = idx < 3;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0e1322),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isTop3 ? Color(badgeInfo.color).withValues(alpha: 0.4) : const Color(0xFF1c2438),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank Number
                            Container(
                              width: 30,
                              alignment: Alignment.center,
                              child: Text(
                                '#${idx + 1}',
                                style: TextStyle(
                                  color: idx == 0
                                      ? Colors.amber
                                      : idx == 1
                                          ? const Color(0xFFcbd5e1)
                                          : idx == 2
                                              ? const Color(0xFFb45309)
                                              : HunterTheme.slate500,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
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
                                      Text(
                                        h['displayName'] ?? 'Unknown',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Color(badgeInfo.color).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          badgeInfo.label,
                                          style: TextStyle(color: Color(badgeInfo.color), fontSize: 10, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${h['equippedTitle'] ?? 'The Awakened'} • Level ${h['level'] ?? 1}',
                                    style: const TextStyle(color: HunterTheme.slate400, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            // Total XP
                            Text(
                              '${h['totalXp'] ?? 0} XP',
                              style: const TextStyle(color: HunterTheme.amber, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
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
