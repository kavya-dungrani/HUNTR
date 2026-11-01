import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../services/social_service.dart';
import '../theme/hunter_theme.dart';
import 'player_profile_dialog.dart';

/// Formatter that automatically converts all typed or pasted characters to lowercase,
/// unless it starts with HUNTR- (Hunter ID lookup).
class AutoLowercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (text.trim().toLowerCase().startsWith('huntr-')) {
      text = text.toUpperCase();
    } else {
      text = text.toLowerCase();
    }
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class AddFriendDialog extends StatefulWidget {
  const AddFriendDialog({super.key});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  Timer? _debounceTimer;
  final Map<String, String> _statusMap = {};
  final Map<String, bool> _actionLoadingMap = {};

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    if (val.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final currentProfile = Provider.of<HunterProvider>(context, listen: false).profile;
      if (currentProfile == null) return;

      final res = await SocialService.instance.searchHunters(val, currentProfile.id);
      if (!mounted) return;

      setState(() {
        _results = res;
        _loading = false;
      });

      for (var p in res) {
        final uid = p['uid'] as String?;
        if (uid != null) {
          final st = await SocialService.instance.getFriendshipStatus(currentProfile.id, uid);
          if (mounted) {
            setState(() {
              _statusMap[uid] = st;
            });
          }
        }
      }
    });
  }

  Future<void> _handleAction(Map<String, dynamic> target) async {
    final currentProfile = Provider.of<HunterProvider>(context, listen: false).profile;
    if (currentProfile == null) return;
    final uid = target['uid'] as String;

    setState(() => _actionLoadingMap[uid] = true);
    try {
      final currentSt = _statusMap[uid] ?? 'none';
      if (currentSt == 'none') {
        await SocialService.instance.sendFriendRequest(currentProfile, target);
        setState(() => _statusMap[uid] = 'request_sent');
      } else if (currentSt == 'request_received') {
        final reqId = '${uid}_${currentProfile.id}';
        await SocialService.instance.acceptFriendRequest(reqId, uid, currentProfile.id);
        setState(() => _statusMap[uid] = 'friends');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _actionLoadingMap[uid] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF070B14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_add, color: HunterTheme.cyan, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ADD NEW FRIEND',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
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

            // Search Bar with Auto Lowercase
            TextField(
              controller: _controller,
              inputFormatters: [AutoLowercaseFormatter()],
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0c1224),
                prefixIcon: const Icon(Icons.search, color: HunterTheme.slate500, size: 20),
                hintText: 'Search username or Hunter ID...',
                hintStyle: const TextStyle(color: HunterTheme.slate500, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '* Username input is automatically converted to lowercase.',
              style: TextStyle(color: HunterTheme.slate500, fontSize: 10, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),

            // Results List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: HunterTheme.cyan),
                    )
                  : _controller.text.trim().isEmpty
                      ? const Center(
                          child: Text(
                            'Enter username or Hunter ID above to initiate scout.',
                            style: TextStyle(color: HunterTheme.slate500, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _results.isEmpty
                          ? Center(
                              child: Text(
                                'No Hunter found matching "${_controller.text.trim()}".',
                                style: const TextStyle(color: HunterTheme.slate500, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _results.length,
                              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final p = _results[idx];
                                final uid = (p['uid'] ?? '').toString();
                                final username = (p['username'] ?? 'hunter').toString();
                                final displayName = (p['displayName'] ?? 'Hunter').toString();
                                final hid = (p['hunterId'] ?? 'HUNTR-UNKNOWN').toString();
                                final level = (p['currentLevel'] ?? p['level'] ?? 1).toString();
                                final rank = (p['currentRank'] ?? p['rank'] ?? 'E-Rank').toString();
                                final badge = getRankBadgeInfo(rank);

                                final st = _statusMap[uid] ?? 'none';
                                final isBusy = _actionLoadingMap[uid] ?? false;

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0a0e20),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF1b233a)),
                                  ),
                                  child: Row(
                                    children: [
                                      // Rank Avatar
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Color(badge.color).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Color(badge.color)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          rank.split('-')[0],
                                          style: TextStyle(
                                            color: Color(badge.color),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Identity info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
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
                                                color: HunterTheme.slate400,
                                                fontSize: 10,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Action buttons
                                      IconButton(
                                        icon: const Icon(Icons.remove_red_eye, color: HunterTheme.slate400, size: 18),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => PlayerProfileDialog(
                                              playerUid: uid,
                                              initialPlayer: p,
                                            ),
                                          );
                                        },
                                        tooltip: 'View Profile',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),

                                      if (st == 'self')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF131828),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('You', style: TextStyle(color: HunterTheme.slate500, fontSize: 10)),
                                        )
                                      else if (st == 'friends')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10b981).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF10b981).withValues(alpha: 0.4)),
                                          ),
                                          child: const Text('Friends', style: TextStyle(color: Color(0xFF10b981), fontSize: 10, fontWeight: FontWeight.bold)),
                                        )
                                      else if (st == 'request_sent')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                          ),
                                          child: const Text('Sent', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                        )
                                      else if (st == 'request_received')
                                        ElevatedButton(
                                          onPressed: isBusy ? null : () => _handleAction(p),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: HunterTheme.cyan,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          child: const Text('Accept', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        )
                                      else
                                        ElevatedButton(
                                          onPressed: isBusy ? null : () => _handleAction(p),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: HunterTheme.cyan,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          ),
                                          child: const Text('Add', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
