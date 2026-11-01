import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../services/social_service.dart';
import '../services/presence_service.dart';
import '../theme/hunter_theme.dart';

class PlayerProfileDialog extends StatefulWidget {
  final String playerUid;
  final Map<String, dynamic>? initialPlayer;

  const PlayerProfileDialog({
    super.key,
    required this.playerUid,
    this.initialPlayer,
  });

  @override
  State<PlayerProfileDialog> createState() => _PlayerProfileDialogState();
}

class _PlayerProfileDialogState extends State<PlayerProfileDialog> {
  Map<String, dynamic>? _player;
  bool _loading = true;
  String _friendStatus = 'none';
  bool _actionLoading = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _player = widget.initialPlayer;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final currentProfile = Provider.of<HunterProvider>(context, listen: false).profile;
    if (widget.initialPlayer == null) {
      final p = await SocialService.instance.getPublicPlayer(widget.playerUid);
      if (mounted) {
        setState(() {
          _player = p;
          _loading = false;
        });
      }
    } else {
      _loading = false;
    }

    if (currentProfile != null) {
      final st = await SocialService.instance.getFriendshipStatus(
        currentProfile.id,
        widget.playerUid,
      );
      if (mounted) {
        setState(() {
          _friendStatus = st;
        });
      }
    }
  }

  void _copyHunterId(String hid) {
    Clipboard.setData(ClipboardData(text: hid));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _handleFriendAction() async {
    final currentProfile = Provider.of<HunterProvider>(context, listen: false).profile;
    if (currentProfile == null || _player == null || _actionLoading) return;

    setState(() => _actionLoading = true);
    try {
      if (_friendStatus == 'none') {
        await SocialService.instance.sendFriendRequest(currentProfile, _player!);
        setState(() => _friendStatus = 'request_sent');
      } else if (_friendStatus == 'request_received') {
        final reqId = '${widget.playerUid}_${currentProfile.id}';
        await SocialService.instance.acceptFriendRequest(reqId, widget.playerUid, currentProfile.id);
        setState(() => _friendStatus = 'friends');
      } else if (_friendStatus == 'friends') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0e1322),
            title: const Text('Remove Friend', style: TextStyle(color: Colors.white)),
            content: Text(
              'Remove @${_player!['username'] ?? 'hunter'} from your friends list?',
              style: const TextStyle(color: HunterTheme.slate400),
            ),
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
          await SocialService.instance.removeFriend(currentProfile.id, widget.playerUid);
          setState(() => _friendStatus = 'none');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = Provider.of<HunterProvider>(context, listen: false).profile;
    final isSelf = currentProfile != null && currentProfile.id == widget.playerUid;

    return Dialog(
      backgroundColor: const Color(0xFF070b18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF1e293b)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        child: _loading || _player == null
            ? const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: HunterTheme.cyan),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header with Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'HUNTER PROFILE',
                        style: TextStyle(
                          color: HunterTheme.cyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: HunterTheme.slate400, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Avatar & Identity
                  Builder(builder: (context) {
                    final rank = (_player!['currentRank'] ?? _player!['rank'] ?? 'E-Rank').toString();
                    final badgeInfo = getRankBadgeInfo(rank);
                    final hid = (_player!['hunterId'] ?? 'HUNTR-UNKNOWN').toString();
                    final username = (_player!['username'] ?? 'hunter').toString();
                    final displayName = (_player!['displayName'] ?? 'Hunter').toString();

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rank Avatar + Live Online Dot
                        StreamBuilder<bool>(
                          stream: PresenceService.instance.streamUserPresence(widget.playerUid),
                          builder: (context, snapshot) {
                            final isOnline = snapshot.data ?? false;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Color(badgeInfo.color).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Color(badgeInfo.color), width: 2),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    rank.split('-')[0],
                                    style: TextStyle(
                                      color: Color(badgeInfo.color),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: isOnline ? const Color(0xFF10b981) : const Color(0xFF64748b),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF070b18), width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 14),

                        // Name, Username, Hunter ID
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
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Color(badgeInfo.color).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      badgeInfo.label,
                                      style: TextStyle(
                                        color: Color(badgeInfo.color),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@$username',
                                style: const TextStyle(
                                  color: HunterTheme.cyan,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Hunter ID + Copy
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0c1224),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF1f293d)),
                                    ),
                                    child: Text(
                                      hid,
                                      style: const TextStyle(
                                        color: HunterTheme.slate300,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _copyHunterId(hid),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1f293d),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        _copied ? Icons.check : Icons.copy,
                                        size: 13,
                                        color: _copied ? Colors.greenAccent : HunterTheme.slate400,
                                      ),
                                    ),
                                  ),
                                  if (_copied)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Text('Copied!', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),

                  // Metadata Cards
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0a0e20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1b233a)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Title', style: TextStyle(color: HunterTheme.slate500, fontSize: 11)),
                            Text(
                              _player!['equippedTitle'] ?? 'The Awakened',
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF1b233a), height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Guild', style: TextStyle(color: HunterTheme.slate500, fontSize: 11)),
                            Text(
                              _player!['guildName'] != null
                                  ? '${_player!['guildName']} [${_player!['guildTag']}]'
                                  : 'No Guild',
                              style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF1b233a), height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Level & XP', style: TextStyle(color: HunterTheme.slate500, fontSize: 11)),
                            Text(
                              'Level ${_player!['currentLevel'] ?? _player!['level'] ?? 1} • ${_player!['totalXp'] ?? 0} XP',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF1b233a), height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Transmission', style: TextStyle(color: HunterTheme.slate500, fontSize: 11)),
                            StreamBuilder<bool>(
                              stream: PresenceService.instance.streamUserPresence(widget.playerUid),
                              builder: (context, snap) {
                                final isOnline = snap.data ?? false;
                                return Text(
                                  isOnline ? '● Online' : '○ Offline',
                                  style: TextStyle(
                                    color: isOnline ? const Color(0xFF10b981) : HunterTheme.slate500,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Friend Action Button
                  if (isSelf || _friendStatus == 'self')
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131828),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF222c42)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'This is You',
                        style: TextStyle(color: HunterTheme.slate400, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  else if (_friendStatus == 'friends')
                    ElevatedButton.icon(
                      onPressed: _actionLoading ? null : _handleFriendAction,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Friends (Tap to remove)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10b981).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF10b981),
                        side: const BorderSide(color: Color(0xFF10b981)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                  else if (_friendStatus == 'request_sent')
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Request Sent',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  else if (_friendStatus == 'request_received')
                    ElevatedButton.icon(
                      onPressed: _actionLoading ? null : _handleFriendAction,
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Accept Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HunterTheme.cyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _actionLoading ? null : _handleFriendAction,
                      icon: const Icon(Icons.person_add, size: 16),
                      label: Text(_actionLoading ? 'Sending...' : 'Add Friend'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HunterTheme.cyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
