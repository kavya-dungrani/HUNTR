import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../services/guild_service.dart';
import '../theme/hunter_theme.dart';
import '../widgets/player_profile_dialog.dart';

class GuildsScreen extends StatefulWidget {
  const GuildsScreen({super.key});

  @override
  State<GuildsScreen> createState() => _GuildsScreenState();
}

class _GuildsScreenState extends State<GuildsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _joinTypeFilter = 'all';

  List<Map<String, dynamic>> _browseList = [];
  bool _browseLoading = true;
  final Map<String, Map<String, dynamic>?> _pendingRequestsMap = {};

  @override
  void initState() {
    super.initState();
    _fetchGuilds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGuilds() async {
    setState(() => _browseLoading = true);
    final list = await GuildService.instance.searchGuilds(
      queryText: _searchQuery,
      joinTypeFilter: _joinTypeFilter,
    );
    if (!mounted) return;

    final currentProfile = Provider.of<HunterProvider>(context, listen: false).profile;
    if (currentProfile != null) {
      for (var g in list) {
        final gid = g['id'] as String;
        final req = await GuildService.instance.getUserGuildRequest(gid, currentProfile.id);
        _pendingRequestsMap[gid] = req;
      }
    }

    if (mounted) {
      setState(() {
        _browseList = list;
        _browseLoading = false;
      });
    }
  }

  void _showCreateGuildDialog() {
    final nameCtrl = TextEditingController();
    final tagCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String joinType = 'open';
    String? errorMsg;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF070b18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF2e1065)),
            ),
            title: const Row(
              children: [
                Icon(Icons.shield, color: Colors.purpleAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'CREATE GUILD',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                      ),
                    ),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Guild Name',
                      labelStyle: const TextStyle(color: HunterTheme.slate400, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF0e1322),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tagCtrl,
                    maxLength: 5,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Guild Tag (2-5 Uppercase Chars)',
                      labelStyle: const TextStyle(color: HunterTheme.slate400, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF0e1322),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Guild Directive / Description',
                      labelStyle: const TextStyle(color: HunterTheme.slate400, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF0e1322),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Join Protocol', style: TextStyle(color: HunterTheme.slate400, fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Anyone Can Join', style: TextStyle(fontSize: 11)),
                          selected: joinType == 'open',
                          selectedColor: Colors.purpleAccent.withValues(alpha: 0.3),
                          onSelected: (v) => setDlgState(() => joinType = 'open'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Request to Join', style: TextStyle(fontSize: 11)),
                          selected: joinType == 'request',
                          selectedColor: Colors.purpleAccent.withValues(alpha: 0.3),
                          onSelected: (v) => setDlgState(() => joinType = 'request'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: HunterTheme.slate400)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final currentProfile = Provider.of<HunterProvider>(context, listen: false).profile;
                        if (currentProfile == null) return;

                        final n = nameCtrl.text.trim();
                        final t = tagCtrl.text.trim().toUpperCase();
                        if (n.length < 3) {
                          setDlgState(() => errorMsg = 'Guild name must be at least 3 characters.');
                          return;
                        }
                        if (t.length < 2 || t.length > 5) {
                          setDlgState(() => errorMsg = 'Guild tag must be between 2 and 5 uppercase characters.');
                          return;
                        }

                        setDlgState(() {
                          isSubmitting = true;
                          errorMsg = null;
                        });

                        try {
                          final gid = await GuildService.instance.createGuild(
                            leader: currentProfile,
                            name: n,
                            tag: t,
                            description: descCtrl.text,
                            icon: 'monarch',
                            joinType: joinType,
                          );

                          if (mounted && ctx.mounted) {
                            Provider.of<HunterProvider>(context, listen: false).updateGuildInfo(
                              gid,
                              'leader',
                              n,
                              t,
                            );
                            Navigator.pop(ctx);
                            _fetchGuilds();
                          }
                        } catch (e) {
                          setDlgState(() {
                            errorMsg = e.toString().replaceAll('Exception:', '').trim();
                            isSubmitting = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                child: Text(isSubmitting ? 'Creating...' : 'Create', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hunter = Provider.of<HunterProvider>(context);
    final user = hunter.profile;
    final inGuild = user?.guildId != null && user!.guildId!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF070a14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0b0f1d),
        elevation: 0,
        title: const Text(
          'GUILD OPERATIONS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (!inGuild)
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.purpleAccent),
              onPressed: _showCreateGuildDialog,
              tooltip: 'Create Guild',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchGuilds,
        color: HunterTheme.cyan,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. User's Guild Card (if in guild)
              if (inGuild) ...[
                _buildMyGuildSection(user),
                const SizedBox(height: 24),
              ],

              // 2. Discover & Browse Guilds
              _buildBrowseSection(user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyGuildSection(HunterProfile user) {
    final gid = user.guildId!;
    return StreamBuilder<Map<String, dynamic>?>(
      stream: GuildService.instance.streamGuild(gid),
      builder: (context, snapshot) {
        final guild = snapshot.data;
        if (guild == null) {
          return const SizedBox.shrink();
        }

        final isLeader = user.guildRole == 'leader' || guild['leaderUid'] == user.id;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0c1026),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Guild Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purpleAccent),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (guild['tag'] ?? 'HUN').toString(),
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                guild['name'] ?? 'Hunter Guild',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purpleAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isLeader ? 'LEADER' : 'MEMBER',
                                style: const TextStyle(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${guild['memberCount'] ?? 1} Members • Leader: @${guild['leaderUsername'] ?? 'hunter'}',
                          style: const TextStyle(color: HunterTheme.slate400, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  // Leave / Disband Button
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    onPressed: () async {
                      final isSole = isLeader && ((guild['memberCount'] as int?) ?? 1) <= 1;
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF0e1322),
                          title: Text(isSole ? 'Disband Guild' : 'Leave Guild', style: const TextStyle(color: Colors.white)),
                          content: Text(
                            isSole
                              ? 'You are the sole leader. Leaving will permanently disband this guild. Proceed?'
                              : 'Exit your current hunter guild?',
                            style: const TextStyle(color: HunterTheme.slate400),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proceed', style: TextStyle(color: Colors.redAccent))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await GuildService.instance.leaveGuild(gid, user.id, isLeader);
                        if (context.mounted) {
                          Provider.of<HunterProvider>(context, listen: false).updateGuildInfo(null, null, null, null);
                          _fetchGuilds();
                        }
                      }
                    },
                    tooltip: isLeader ? 'Disband Guild' : 'Leave Guild',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                guild['description'] ?? 'No description provided.',
                style: const TextStyle(color: HunterTheme.slate300, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Leader: Pending Requests
              if (isLeader) ...[
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: GuildService.instance.streamGuildRequests(gid),
                  builder: (context, rSnap) {
                    final reqs = rSnap.data ?? [];
                    if (reqs.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PENDING JOIN REQUESTS (${reqs.length})',
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          ...reqs.map((r) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r['displayName'] ?? 'Hunter', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text('@${r['username'] ?? 'hunter'} • Lv.${r['level'] ?? 1}', style: const TextStyle(color: HunterTheme.slate400, fontSize: 10)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => GuildService.instance.acceptJoinRequest(guild, r),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: HunterTheme.cyan,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          minimumSize: Size.zero,
                                        ),
                                        child: const Text('Accept', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: HunterTheme.slate400, size: 16),
                                        onPressed: () => GuildService.instance.rejectJoinRequest(gid, r['uid']),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // Guild Members Roster
              const Text(
                'GUILD ROSTER',
                style: TextStyle(color: HunterTheme.slate400, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: GuildService.instance.streamGuildMembers(gid),
                builder: (context, mSnap) {
                  final members = mSnap.data ?? [];
                  if (members.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: HunterTheme.cyan));
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                    itemBuilder: (context, idx) {
                      final m = members[idx];
                      final isMemLeader = m['role'] == 'leader';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF070b18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1c2438)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(m['displayName'] ?? 'Hunter', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      if (isMemLeader) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.star, color: Colors.amber, size: 12),
                                      ],
                                    ],
                                  ),
                                  Text('@${m['username'] ?? 'hunter'} • Level ${m['level'] ?? 1}', style: const TextStyle(color: HunterTheme.slate400, fontSize: 10)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye, color: HunterTheme.slate400, size: 16),
                              onPressed: () {
                                showDialog(context: context, builder: (_) => PlayerProfileDialog(playerUid: m['uid']));
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            if (isLeader && !isMemLeader) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.person_remove, color: Colors.redAccent, size: 16),
                                onPressed: () => GuildService.instance.removeMember(gid, m['uid']),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrowseSection(HunterProfile? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Filters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'BROWSE GUILDS',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5),
            ),
            Row(
              children: ['all', 'open', 'request'].map((f) {
                final isSel = _joinTypeFilter == f;
                return GestureDetector(
                  onTap: () {
                    setState(() => _joinTypeFilter = f);
                    _fetchGuilds();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? HunterTheme.cyan : const Color(0xFF131828),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      f.toUpperCase(),
                      style: TextStyle(
                        color: isSel ? Colors.black : HunterTheme.slate400,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Input
        TextField(
          controller: _searchController,
          onSubmitted: (v) {
            setState(() => _searchQuery = v.trim());
            _fetchGuilds();
          },
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0e1322),
            prefixIcon: const Icon(Icons.search, color: HunterTheme.slate500, size: 18),
            hintText: 'Search by guild name or tag...',
            hintStyle: const TextStyle(color: HunterTheme.slate500, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),

        // Guilds Cards List
        if (_browseLoading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: HunterTheme.cyan)))
        else if (_browseList.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No active guilds match your parameters.', style: TextStyle(color: HunterTheme.slate500, fontSize: 12)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _browseList.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final g = _browseList[idx];
              final gid = g['id'] as String;
              final isMember = user?.guildId == gid;
              final pending = _pendingRequestsMap[gid];
              final isOpen = g['joinType'] == 'open';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0e1322),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1c2438)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purpleAccent),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (g['tag'] ?? 'HUN').toString(),
                            style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g['name'] ?? 'Guild',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${g['memberCount'] ?? 1} Members • Leader: @${g['leaderUsername'] ?? 'hunter'}',
                                style: const TextStyle(color: HunterTheme.slate400, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.green.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isOpen ? Colors.green : Colors.amber),
                          ),
                          child: Text(
                            isOpen ? 'OPEN' : 'REQUEST',
                            style: TextStyle(color: isOpen ? Colors.green : Colors.amber, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      g['description'] ?? 'No description provided.',
                      style: const TextStyle(color: HunterTheme.slate400, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isMember)
                          const Text('Your Guild', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 11))
                        else if (user?.guildId != null && user!.guildId!.isNotEmpty)
                          const Text('(Leave current guild to join)', style: TextStyle(color: HunterTheme.slate500, fontSize: 10))
                        else if (pending != null)
                          TextButton(
                            onPressed: () async {
                              await GuildService.instance.cancelJoinRequest(gid, user!.id);
                              _fetchGuilds();
                            },
                            child: const Text('Pending (Cancel)', style: TextStyle(color: Colors.amber, fontSize: 11)),
                          )
                        else if (isOpen)
                          ElevatedButton(
                            onPressed: () async {
                              if (user == null) return;
                              await GuildService.instance.joinOpenGuild(user, g);
                              if (context.mounted) {
                                Provider.of<HunterProvider>(context, listen: false).updateGuildInfo(
                                  gid,
                                  'member',
                                  g['name'],
                                  g['tag'],
                                );
                                _fetchGuilds();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HunterTheme.cyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Join Guild', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          )
                        else
                          ElevatedButton(
                            onPressed: () async {
                              if (user == null) return;
                              await GuildService.instance.requestToJoinGuild(user, gid);
                              _fetchGuilds();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1e293b),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Request to Join', style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
