import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../services/guild_service.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          return Dialog(
            backgroundColor: const Color(0xFF070B14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1.5),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield, color: Color(0xFF00E5FF), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ESTABLISH SYNDICATE',
                              style: TextStyle(
                                color: Color(0xFFF0F6FC),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'FOUND A PERMANENT HUNTER COALITION IN THE REGISTRY',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9.5,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
                    const SizedBox(height: 16),

                    if (errorMsg != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          errorMsg!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),

                    // Guild Name
                    const Text(
                      'SYNDICATE DESIGNATION',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Asmodeus, Ahjin, Hunters',
                        hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0A0F1D),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Guild Tag
                    const Text(
                      'TACTICAL TAG (2-5 CHARS)',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: tagCtrl,
                      maxLength: 5,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'e.g. ASMO, AHJIN',
                        hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0A0F1D),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Guild Description
                    const Text(
                      'SYNDICATE MANIFESTO',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Guild objective and admission criteria...',
                        hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0A0F1D),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Join Type
                    const Text(
                      'ENROLLMENT PROTOCOL',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDlgState(() => joinType = 'open'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: joinType == 'open' ? const Color(0xFF00E5FF).withValues(alpha: 0.15) : const Color(0xFF0A0F1D),
                                border: Border.all(
                                  color: joinType == 'open' ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.1),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '[ OPEN ENTRY ]',
                                style: TextStyle(
                                  color: joinType == 'open' ? const Color(0xFF00E5FF) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDlgState(() => joinType = 'request'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: joinType == 'request' ? const Color(0xFFC084FC).withValues(alpha: 0.15) : const Color(0xFF0A0F1D),
                                border: Border.all(
                                  color: joinType == 'request' ? const Color(0xFFC084FC) : Colors.white.withValues(alpha: 0.1),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '[ APPROVAL ONLY ]',
                                style: TextStyle(
                                  color: joinType == 'request' ? const Color(0xFFC084FC) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final n = nameCtrl.text.trim();
                              final t = tagCtrl.text.trim().toUpperCase();
                              if (n.length < 3) {
                                setDlgState(() => errorMsg = 'Guild name must be at least 3 characters.');
                                return;
                              }
                              if (t.length < 2 || t.length > 5) {
                                setDlgState(() => errorMsg = 'Guild tag must be between 2 and 5 characters.');
                                return;
                              }

                              setDlgState(() {
                                isSubmitting = true;
                                errorMsg = null;
                              });

                              try {
                                final leader = Provider.of<HunterProvider>(context, listen: false).profile!;
                                final gid = await GuildService.instance.createGuild(
                                  leader: leader,
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
                                }
                              } catch (e) {
                                setDlgState(() {
                                  errorMsg = e.toString().replaceAll('Exception:', '').trim();
                                  isSubmitting = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text(
                        isSubmitting ? 'INITIALIZING SYNDICATE...' : '◆ ESTABLISH SYNDICATE ◆',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
              '[ GLOBAL HUNTER SYNDICATES ]',
              style: TextStyle(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                fontSize: 10,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'GUILD OPERATIONS',
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
          if (!inGuild)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _showCreateGuildDialog,
                icon: const Icon(Icons.add, size: 14, color: Color(0xFF00E5FF)),
                label: const Text(
                  '+ CREATE',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF00E5FF).withValues(alpha: 0.2), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. User's Guild Command Center (if in guild)
            if (inGuild) ...[
              _buildMyGuildSection(user),
              const SizedBox(height: 24),
            ],

            // 2. Discover & Browse Guilds
            _buildBrowseSection(user),
          ],
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF070B14),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFC084FC).withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC084FC).withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Color(0xFFC084FC), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '[ ACTIVE SYNDICATE COMMAND ]',
                        style: TextStyle(
                          color: const Color(0xFFC084FC).withValues(alpha: 0.9),
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0xFFC084FC).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      isLeader ? 'MASTER' : 'MEMBER',
                      style: const TextStyle(
                        color: Color(0xFFC084FC),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Guild Title Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tactical Tag Box
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F1D),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (guild['tag'] ?? 'HUN').toString(),
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guild['name'] ?? 'Hunter Syndicate',
                          style: const TextStyle(
                            color: Color(0xFFF0F6FC),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFFF59E0B), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Master: @${guild['leaderUsername'] ?? 'hunter'}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${guild['memberCount'] ?? 1} Hunters',
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Leave / Disband Button
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                    onPressed: () async {
                      final isSole = isLeader && ((guild['memberCount'] as int?) ?? 1) <= 1;
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF070B14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                          ),
                          title: Text(
                            isSole ? 'DISBAND SYNDICATE' : 'LEAVE SYNDICATE',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          content: Text(
                            isSole
                                ? 'You are the sole leader of this syndicate. Exiting will permanently dismantle it from the registry. Proceed?'
                                : 'Sever connection with this syndicate?',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('CANCEL', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('CONFIRM EXIT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await GuildService.instance.leaveGuild(gid, user.id, isLeader);
                        if (context.mounted) {
                          Provider.of<HunterProvider>(context, listen: false).updateGuildInfo(null, null, null, null);
                        }
                      }
                    },
                    tooltip: isLeader ? 'Disband Syndicate' : 'Leave Syndicate',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                guild['description'] ?? 'No description provided.',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Leader: Pending Join Requests
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
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.pending_actions, color: Color(0xFFF59E0B), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'PENDING ENROLLMENT REQUESTS (${reqs.length})',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.5,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...reqs.map((r) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0F1D),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r['displayName'] ?? 'Hunter',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '@${r['username'] ?? 'hunter'} • Lv.${r['level'] ?? 1} • ${r['rank'] ?? 'E-Rank'}',
                                          style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => GuildService.instance.acceptJoinRequest(guild, r),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF00E5FF),
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            minimumSize: Size.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                          ),
                                          child: const Text('APPROVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 16),
                                          onPressed: () => GuildService.instance.rejectJoinRequest(gid, r['uid']),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // Syndicate Roster
              Row(
                children: [
                  const Icon(Icons.group, color: Color(0xFF00E5FF), size: 13),
                  const SizedBox(width: 6),
                  const Text(
                    'SYNDICATE ROSTER',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: GuildService.instance.streamGuildMembers(gid),
                builder: (context, mSnap) {
                  final members = mSnap.data ?? [];
                  if (members.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                    itemBuilder: (context, idx) {
                      final m = members[idx];
                      final isMemLeader = m['role'] == 'leader';
                      final rank = (m['rank'] ?? 'E-Rank').toString();
                      final badge = getRankBadgeInfo(rank);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0F1D),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isMemLeader
                                ? const Color(0xFFC084FC).withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank Box
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Color(badge.color).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Color(badge.color).withValues(alpha: 0.4)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                rank.split('-')[0],
                                style: TextStyle(
                                  color: Color(badge.color),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        m['displayName'] ?? 'Hunter',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      if (isMemLeader) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: const Text(
                                            'MASTER',
                                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 8, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '@${m['username'] ?? 'hunter'} • Lv.${m['level'] ?? 1}',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),

                            // View Dossier Button
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => PlayerProfileDialog(
                                    playerUid: m['uid'],
                                    initialPlayer: m,
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                '[ DOSSIER ]',
                                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ),

                            if (isLeader && !isMemLeader) ...[
                              IconButton(
                                icon: const Icon(Icons.person_remove, color: Colors.redAccent, size: 16),
                                onPressed: () => GuildService.instance.removeMember(gid, m['uid']),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Expel Member',
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
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.search, color: Color(0xFF00E5FF), size: 14),
                SizedBox(width: 6),
                Text(
                  'BROWSE GUILDS',
                  style: TextStyle(
                    color: Color(0xFFF0F6FC),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),

            // Filter Tabs
            Row(
              children: ['all', 'open', 'request'].map((f) {
                final isSel = _joinTypeFilter == f;
                return GestureDetector(
                  onTap: () => setState(() => _joinTypeFilter = f),
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF00E5FF).withValues(alpha: 0.15) : const Color(0xFF0A0F1D),
                      border: Border.all(
                        color: isSel ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.08),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      f.toUpperCase(),
                      style: TextStyle(
                        color: isSel ? const Color(0xFF00E5FF) : const Color(0xFF64748B),
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Search Input
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF070B14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF475569), size: 16),
            hintText: 'Search by syndicate name or tag...',
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
        const SizedBox(height: 12),

        // Live Real-Time Guilds Stream
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: GuildService.instance.streamGuilds(joinTypeFilter: _joinTypeFilter),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                ),
              );
            }

            var list = snapshot.data ?? [];

            // Apply search query filter in-memory
            if (_searchQuery.isNotEmpty) {
              list = list.where((g) {
                final n = (g['name'] ?? '').toString().toLowerCase();
                final t = (g['tag'] ?? '').toString().toLowerCase();
                return n.contains(_searchQuery) || t.contains(_searchQuery);
              }).toList();
            }

            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFF070B14),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFF475569), size: 36),
                    const SizedBox(height: 12),
                    const Text(
                      '[ ! ] NO ACTIVE SYNDICATES DETECTED',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'No hunter syndicates match your search parameters. Establish your own syndicate today.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    if (user?.guildId == null || user!.guildId!.isEmpty) ...[
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _showCreateGuildDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text(
                          '+ ESTABLISH SYNDICATE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final g = list[idx];
                final gid = (g['id'] ?? '').toString();
                final isMember = user?.guildId == gid;
                final isOpen = g['joinType'] == 'open';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B14),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isMember
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          // Tag Box
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0F1D),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (g['tag'] ?? 'HUN').toString(),
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
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
                                      g['name'] ?? 'Guild',
                                      style: const TextStyle(
                                        color: Color(0xFFF0F6FC),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isOpen
                                            ? Colors.greenAccent.withValues(alpha: 0.15)
                                            : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(2),
                                        border: Border.all(
                                          color: isOpen ? Colors.greenAccent : const Color(0xFFF59E0B),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        isOpen ? 'OPEN' : 'APPROVAL',
                                        style: TextStyle(
                                          color: isOpen ? Colors.greenAccent : const Color(0xFFF59E0B),
                                          fontSize: 8,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Master: @${g['leaderUsername'] ?? 'hunter'} • ${g['memberCount'] ?? 1} Hunters',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        g['description'] ?? 'No description provided.',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isMember)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                '[ YOUR SYNDICATE ]',
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (user?.guildId != null && user!.guildId!.isNotEmpty)
                            const Text(
                              '(Leave current syndicate to join)',
                              style: TextStyle(color: Color(0xFF475569), fontSize: 9.5),
                            )
                          else ...[
                            FutureBuilder<Map<String, dynamic>?>(
                              future: user != null
                                  ? GuildService.instance.getUserGuildRequest(gid, user.id)
                                  : Future.value(null),
                              builder: (context, reqSnap) {
                                final req = reqSnap.data;
                                if (req != null) {
                                  return TextButton(
                                    onPressed: () async {
                                      await GuildService.instance.cancelJoinRequest(gid, user!.id);
                                      setState(() {});
                                    },
                                    child: const Text(
                                      '[ PENDING (CANCEL) ]',
                                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontFamily: 'monospace'),
                                    ),
                                  );
                                }

                                if (isOpen) {
                                  return ElevatedButton(
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
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00E5FF),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                    ),
                                    child: const Text(
                                      '◆ ENROLL ◆',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5),
                                    ),
                                  );
                                } else {
                                  return ElevatedButton(
                                    onPressed: () async {
                                      if (user == null) return;
                                      await GuildService.instance.requestToJoinGuild(user, gid);
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFC084FC),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                    ),
                                    child: const Text(
                                      'REQUEST ENTRY',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
