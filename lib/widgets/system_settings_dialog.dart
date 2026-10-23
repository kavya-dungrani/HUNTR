import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hunter_provider.dart';
import '../services/audio_service.dart';
import '../services/firebase_service.dart';
import '../theme/hunter_theme.dart';

class SystemSettingsDialog extends StatefulWidget {
  const SystemSettingsDialog({super.key});

  @override
  State<SystemSettingsDialog> createState() => _SystemSettingsDialogState();
}

class _SystemSettingsDialogState extends State<SystemSettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final hunter = Provider.of<HunterProvider>(context);
    final user = FirebaseService.instance.currentUser;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0c101d),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HunterTheme.slate600, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings, color: HunterTheme.cyan, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'SYSTEM PROTOCOLS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: HunterTheme.slate400),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0xFF1e263c), height: 24),

            // Account / Hunter ID Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF131929),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF222c44)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LINKED HUNTER PROFILE', style: TextStyle(color: HunterTheme.slate400, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    hunter.profile?.hunterId ?? 'UNKNOWN',
                    style: const TextStyle(color: HunterTheme.cyanLight, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user != null ? (user.email ?? 'Firebase Anonymous Hunter (${user.uid.substring(0, 8)}...)') : 'Offline Local Storage',
                    style: const TextStyle(color: HunterTheme.slate500, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sound Effects Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sound Effects & Haptics', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text('Audio alerts on quest completion and level up', style: TextStyle(color: HunterTheme.slate400, fontSize: 12)),
              value: AudioService.instance.soundEnabled,
              activeThumbColor: HunterTheme.cyan,
              onChanged: (val) {
                setState(() {
                  AudioService.instance.soundEnabled = val;
                });
              },
            ),

            const SizedBox(height: 16),

            // Logout Hunter
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  hunter.signOutHunter();
                },
                icon: const Icon(Icons.logout_rounded, color: HunterTheme.slate300, size: 18),
                label: const Text('DISCONNECT / LOG OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF28344e)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Reset Account / Hunter Protocol
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF0e1322),
                      title: const Text('CONFIRM HUNTER RESET', style: TextStyle(color: HunterTheme.red, fontWeight: FontWeight.bold)),
                      content: const Text(
                        'This will permanently reset your hunter stats, levels, and active quests. Proceed with awakening rebirth?',
                        style: TextStyle(color: HunterTheme.slate300, fontSize: 13),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('CANCEL', style: TextStyle(color: HunterTheme.slate400)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).pop();
                            hunter.resetHunter();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: HunterTheme.red),
                          child: const Text('RESET SYSTEM', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, color: HunterTheme.red, size: 18),
                label: const Text('REBIRTH / RESET PROFILE', style: TextStyle(color: HunterTheme.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: HunterTheme.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
