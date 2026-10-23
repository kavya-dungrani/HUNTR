import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hunter_provider.dart';
import '../theme/hunter_theme.dart';

class NotificationCenterDialog extends StatelessWidget {
  const NotificationCenterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final hunter = Provider.of<HunterProvider>(context);
    final logs = hunter.profile?.systemLog ?? [];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0b0f1a),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HunterTheme.cyan.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: HunterTheme.cyan.withValues(alpha: 0.15),
              blurRadius: 25,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: HunterTheme.cyan, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'SYSTEM LOGS',
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
            const Divider(color: Color(0xFF1c2438), height: 20),
            Expanded(
              child: logs.isEmpty
                  ? const Center(
                      child: Text('No system activity recorded yet', style: TextStyle(color: HunterTheme.slate500)),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, idx) {
                        final entry = logs[idx];
                        final date = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
                        final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121727),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF1d263d)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: HunterTheme.cyan.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bolt, color: HunterTheme.cyan, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.message,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(color: HunterTheme.slate500, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              if (entry.xp != null)
                                Text(
                                  '+${entry.xp} XP',
                                  style: const TextStyle(color: HunterTheme.amber, fontWeight: FontWeight.bold, fontSize: 12),
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
