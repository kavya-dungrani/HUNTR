import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../services/social_service.dart';
import '../services/presence_service.dart';
import '../widgets/add_friend_dialog.dart';
import '../widgets/player_profile_dialog.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hunter = Provider.of<HunterProvider>(context);
    final user = hunter.profile;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF030509),
        body: Center(
          child: Text(
            '[ AUTHENTICATION REQUIRED ]',
            style: TextStyle(color: Color(0xFF64748B), fontFamily: 'monospace'),
          ),
        ),
      );
    }

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
              '[ SQUAD SYNCHRONIZATION ]',
              style: TextStyle(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                fontSize: 10,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'HUNTER NETWORK',
              style: TextStyle(
                color: Color(0xFFF0F6FC),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {
                showDialog(context: context, builder: (_) => const AddFriendDialog());
              },
              icon: const Icon(Icons.person_add, size: 14, color: Color(0xFF00E5FF)),
              label: const Text(
                '+ ADD',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E5FF),
          indicatorWeight: 2,
          labelColor: const Color(0xFF00E5FF),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'monospace', letterSpacing: 1),
          tabs: [
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: SocialService.instance.streamFriends(user.id),
              builder: (context, snap) {
                final count = snap.data?.length ?? 0;
                return Tab(text: '[ SQUAD ($count) ]');
              },
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: SocialService.instance.streamIncomingRequests(user.id),
              builder: (context, snap) {
                final count = snap.data?.length ?? 0;
                return Tab(text: '[ TRANSMISSIONS ($count) ]');
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Friends Roster
          _buildFriendsTab(user.id),

          // Tab 2: Incoming Requests
          _buildRequestsTab(user.id),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(String currentUid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SocialService.instance.streamFriends(currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
        }

        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.group, color: Color(0xFF00E5FF), size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '[ NO ACTIVE SQUAD OPERATIVES ]',
                    style: TextStyle(
                      color: Color(0xFFF0F6FC),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Search for other hunters and link neural IDs.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(context: context, builder: (_) => const AddFriendDialog());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text(
                      '+ LINK NEW OPERATIVE',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Search / Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _filter = v.trim().toLowerCase()),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF070B14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF475569), size: 16),
                  hintText: 'Filter squad members by name or @handle...',
                  hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                  ),
                ),
              ),
            ),

            // Friends List with Live Online Presence
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: friends.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final f = friends[idx];
                  final uid = (f['uid'] ?? '').toString();
                  final username = (f['username'] ?? 'hunter').toString();
                  final displayName = (f['displayName'] ?? 'Hunter').toString();
                  final level = (f['level'] ?? 1).toString();
                  final rank = (f['rank'] ?? 'E-Rank').toString();
                  final badge = getRankBadgeInfo(rank);

                  if (_filter.isNotEmpty &&
                      !username.contains(_filter) &&
                      !displayName.toLowerCase().contains(_filter)) {
                    return const SizedBox.shrink();
                  }

                  return StreamBuilder<bool>(
                    stream: PresenceService.instance.streamUserPresence(uid),
                    builder: (context, pSnap) {
                      final isOnline = pSnap.data ?? false;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF070B14),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isOnline
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank Avatar Box + Live Dot
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(badge.color).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Color(badge.color).withValues(alpha: 0.5)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    rank.split('-')[0],
                                    style: TextStyle(
                                      color: Color(badge.color),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -1,
                                  right: -1,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: isOnline ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF070B14), width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          displayName,
                                          style: const TextStyle(
                                            color: Color(0xFFF0F6FC),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Color(badge.color).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: Text(
                                          badge.label,
                                          style: TextStyle(
                                            color: Color(badge.color),
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '@$username',
                                        style: const TextStyle(
                                          color: Color(0xFF00E5FF),
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '• Lv.$level',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace'),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isOnline ? '● Online' : '○ Offline',
                                        style: TextStyle(
                                          color: isOnline ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                          fontSize: 9.5,
                                          fontWeight: isOnline ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PlayerProfileDialog(
                                    playerUid: uid,
                                    initialPlayer: f,
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                '[ DOSSIER ]',
                                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 9.5, fontFamily: 'monospace'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_remove, color: Color(0xFF64748B), size: 16),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF070B14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                                    ),
                                    title: const Text('REMOVE OPERATIVE', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    content: Text(
                                      'Remove @$username from your squad synchronization?',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: Colors.white, fontSize: 11))),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('REMOVE', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await SocialService.instance.removeFriend(currentUid, uid);
                                }
                              },
                              tooltip: 'Remove',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
        );
      },
    );
  }

  Widget _buildRequestsTab(String currentUid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SocialService.instance.streamIncomingRequests(currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_read_outlined, color: Color(0xFF475569), size: 36),
                const SizedBox(height: 12),
                const Text(
                  '[ NO PENDING TRANSMISSIONS ]',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final r = requests[idx];
            final reqId = (r['id'] ?? '').toString();
            final fromUid = (r['fromUid'] ?? '').toString();
            final fromUsername = (r['fromUsername'] ?? 'hunter').toString();
            final fromDisplayName = (r['fromDisplayName'] ?? 'Hunter').toString();
            final fromRank = (r['fromRank'] ?? 'E-Rank').toString();
            final fromLevel = (r['fromLevel'] ?? 1).toString();
            final badge = getRankBadgeInfo(fromRank);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF070B14),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Color(badge.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Color(badge.color).withValues(alpha: 0.5)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      fromRank.split('-')[0],
                      style: TextStyle(
                        color: Color(badge.color),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fromDisplayName,
                          style: const TextStyle(color: Color(0xFFF0F6FC), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '@$fromUsername • Lv.$fromLevel • $fromRank',
                          style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),

                  // Accept & Decline Buttons
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await SocialService.instance.acceptFriendRequest(reqId, fromUid, currentUid);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                        ),
                        child: const Text('ACCEPT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 16),
                        onPressed: () async {
                          await SocialService.instance.declineFriendRequest(reqId);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
