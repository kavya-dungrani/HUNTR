import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../services/social_service.dart';
import '../services/presence_service.dart';
import '../theme/hunter_theme.dart';
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
        backgroundColor: Color(0xFF070a14),
        body: Center(
          child: Text('Please log in to access your squad.', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070a14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0f1d),
        elevation: 0,
        title: const Text(
          'SOCIAL SYNDICATE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: HunterTheme.cyan),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddFriendDialog(),
              );
            },
            tooltip: 'Add New Friend',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: HunterTheme.cyan,
          indicatorWeight: 3,
          labelColor: HunterTheme.cyan,
          unselectedLabelColor: HunterTheme.slate400,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
          tabs: [
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: SocialService.instance.streamFriends(user.id),
              builder: (context, snap) {
                final count = snap.data?.length ?? 0;
                return Tab(text: 'FRIENDS ($count)');
              },
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: SocialService.instance.streamIncomingRequests(user.id),
              builder: (context, snap) {
                final count = snap.data?.length ?? 0;
                return Tab(text: 'REQUESTS ($count)');
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Friends List
          _buildFriendsTab(user.id),

          // Tab 2: Incoming Requests
          _buildRequestsTab(user.id),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HunterTheme.cyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text(
          '+ ADD FRIEND',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddFriendDialog(),
          );
        },
      ),
    );
  }

  Widget _buildFriendsTab(String currentUid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SocialService.instance.streamFriends(currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: HunterTheme.cyan));
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
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: HunterTheme.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: HunterTheme.cyan.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.group, color: HunterTheme.cyan, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No friends yet.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Find other hunters and build your squad.',
                    style: TextStyle(color: HunterTheme.slate400, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(context: context, builder: (_) => const AddFriendDialog());
                    },
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Add Friend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HunterTheme.cyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  fillColor: const Color(0xFF0e1322),
                  prefixIcon: const Icon(Icons.search, color: HunterTheme.slate500, size: 18),
                  hintText: 'Filter squad members...',
                  hintStyle: const TextStyle(color: HunterTheme.slate500, fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1c2438)),
                  ),
                ),
              ),
            ),

            // Friends List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: friends.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 10),
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
                          color: const Color(0xFF0e1322),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1c2438)),
                        ),
                        child: Row(
                          children: [
                            // Presence dot + Avatar
                            Stack(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Color(badge.color).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Color(badge.color)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    rank.split('-')[0],
                                    style: TextStyle(
                                      color: Color(badge.color),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -1,
                                  right: -1,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isOnline ? const Color(0xFF10b981) : const Color(0xFF64748b),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF0e1322), width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Identity details
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
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: Color(badge.color).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          badge.label,
                                          style: TextStyle(
                                            color: Color(badge.color),
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '@$username',
                                    style: const TextStyle(
                                      color: HunterTheme.cyan,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOnline ? '● Level $level • Online' : '○ Level $level • Offline',
                                    style: TextStyle(
                                      color: isOnline ? const Color(0xFF10b981) : HunterTheme.slate500,
                                      fontSize: 10,
                                      fontWeight: isOnline ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye, color: HunterTheme.slate400, size: 20),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PlayerProfileDialog(
                                    playerUid: uid,
                                    initialPlayer: f,
                                  ),
                                );
                              },
                              tooltip: 'View Profile',
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_remove, color: HunterTheme.slate400, size: 20),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF0e1322),
                                    title: const Text('Remove Friend', style: TextStyle(color: Colors.white)),
                                    content: Text('Remove @$username from your squad?', style: const TextStyle(color: HunterTheme.slate400)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await SocialService.instance.removeFriend(currentUid, uid);
                                }
                              },
                              tooltip: 'Remove Friend',
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
          return const Center(child: CircularProgressIndicator(color: HunterTheme.cyan));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No pending friend requests.',
                style: TextStyle(color: HunterTheme.slate500, fontSize: 13),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: requests.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final req = requests[idx];
            final reqId = (req['id'] ?? '').toString();
            final fromUid = (req['fromUid'] ?? '').toString();
            final username = (req['fromUsername'] ?? 'hunter').toString();
            final displayName = (req['fromDisplayName'] ?? 'Hunter').toString();
            final hid = (req['fromHunterId'] ?? 'HUNTR-UNKNOWN').toString();
            final level = (req['fromLevel'] ?? 1).toString();
            final rank = (req['fromRank'] ?? 'E-Rank').toString();
            final badge = getRankBadgeInfo(rank);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0e1322),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1c2438)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(badge.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(badge.color)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      rank.split('-')[0],
                      style: TextStyle(
                        color: Color(badge.color),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '@$username',
                          style: const TextStyle(
                            color: HunterTheme.cyan,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          '$hid • Lv.$level',
                          style: const TextStyle(
                            color: HunterTheme.slate500,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Accept & Decline buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await SocialService.instance.acceptFriendRequest(reqId, fromUid, currentUid);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HunterTheme.cyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close, color: HunterTheme.slate400, size: 18),
                        onPressed: () async {
                          await SocialService.instance.declineFriendRequest(reqId);
                        },
                        tooltip: 'Decline',
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
