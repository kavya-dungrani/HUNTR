import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../services/social_service.dart';
import '../services/presence_service.dart';

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
            backgroundColor: const Color(0xFF070B14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            title: const Text('REMOVE SQUAD OPERATIVE', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            content: Text(
              'Sever friend synchronization with @${_player!['username'] ?? 'hunter'}?',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('CONFIRM', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = Provider.of<HunterProvider>(context).profile;
    final isSelf = currentProfile != null && currentProfile.id == widget.playerUid;

    return Dialog(
      backgroundColor: const Color(0xFF070B14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: _loading || _player == null
            ? const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'HUNTER DOSSIER',
                            style: TextStyle(
                              color: Color(0xFFF0F6FC),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Avatar & Identity Row
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
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: Color(badgeInfo.color).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Color(badgeInfo.color), width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    rank.split('-')[0],
                                    style: TextStyle(
                                      color: Color(badgeInfo.color),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isOnline ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF070B14), width: 2),
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
                                        color: Color(0xFFF0F6FC),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Color(badgeInfo.color).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      badgeInfo.label,
                                      style: TextStyle(
                                        color: Color(badgeInfo.color),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@$username',
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Hunter ID + Copy Box
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A0F1D),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    child: Text(
                                      hid,
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _copyHunterId(hid),
                                    child: Icon(
                                      _copied ? Icons.check : Icons.copy,
                                      size: 13,
                                      color: _copied ? Colors.greenAccent : const Color(0xFF64748B),
                                    ),
                                  ),
                                  if (_copied)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Text('Copied', style: TextStyle(color: Colors.greenAccent, fontSize: 9)),
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

                  // 4-Card Status Grid (2x2)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F1D),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Equipped Title
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EQUIPPED TITLE',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 8.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.military_tech, color: Color(0xFFF59E0B), size: 13),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          _player!['equippedTitle'] ?? 'The Awakened',
                                          style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Hunter Guild
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'HUNTER GUILD',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 8.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.shield, color: Color(0xFFC084FC), size: 12),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          _player!['guildName'] != null
                                              ? '${_player!['guildName']} [${_player!['guildTag']}]'
                                              : 'Free Agent',
                                          style: const TextStyle(color: Color(0xFFC084FC), fontSize: 11, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Progression Level
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PROGRESSION LEVEL',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 8.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Level ${_player!['currentLevel'] ?? _player!['level'] ?? 1} • ${_player!['totalXp'] ?? 0} XP',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            // Transmission State
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TRANSMISSION STATE',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 8.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  StreamBuilder<bool>(
                                    stream: PresenceService.instance.streamUserPresence(widget.playerUid),
                                    builder: (context, snap) {
                                      final isOnline = snap.data ?? false;
                                      return Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: isOnline ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isOnline ? 'Online' : 'Dormant (Offline)',
                                            style: TextStyle(
                                              color: isOnline ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions: Close & Friend button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                        ),
                        child: const Text('Close', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      ),
                      const SizedBox(width: 8),

                      if (!isSelf && _friendStatus != 'self')
                        ElevatedButton.icon(
                          onPressed: _actionLoading ? null : _handleFriendAction,
                          icon: _actionLoading
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : Icon(
                                  _friendStatus == 'friends'
                                      ? Icons.check
                                      : _friendStatus == 'request_received'
                                          ? Icons.person_add
                                          : _friendStatus == 'request_sent'
                                              ? Icons.hourglass_top
                                              : Icons.person_add,
                                  size: 14,
                                ),
                          label: Text(
                            _friendStatus == 'friends'
                                ? 'FRIENDS'
                                : _friendStatus == 'request_received'
                                    ? 'ACCEPT REQUEST'
                                    : _friendStatus == 'request_sent'
                                        ? 'REQUEST SENT'
                                        : '+ ADD FRIEND',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5, letterSpacing: 0.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _friendStatus == 'friends'
                                ? const Color(0xFF10B981)
                                : const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
