import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../theme/hunter_theme.dart';

class LevelUpDialog extends StatefulWidget {
  final int newLevel;
  final String? newRank;
  final VoidCallback onDismiss;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    this.newRank,
    required this.onDismiss,
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNewRank = widget.newRank != null && widget.newRank!.isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      children: [
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            HunterTheme.cyan,
            HunterTheme.purple,
            HunterTheme.amber,
            HunterTheme.pink,
          ],
        ),
        ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0c101d),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: HunterTheme.cyan,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: HunterTheme.cyan.withValues(alpha: 0.35),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // System Header Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: HunterTheme.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: HunterTheme.cyan.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      '[ SYSTEM NOTIFICATION ]',
                      style: TextStyle(
                        color: HunterTheme.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Level Up Title
                  const Text(
                    'LEVEL UP!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(color: HunterTheme.cyan, blurRadius: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // New Level Badge
                  Text(
                    'LEVEL ${widget.newLevel}',
                    style: const TextStyle(
                      color: HunterTheme.cyanLight,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  if (hasNewRank) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: HunterTheme.purpleGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'RANK PROMOTION: ${widget.newRank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141928),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF26304a)),
                    ),
                    child: const Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Skill Points Granted', style: TextStyle(color: HunterTheme.slate400, fontSize: 13)),
                            Text('+3 SP', style: TextStyle(color: HunterTheme.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Maximum Capacity', style: TextStyle(color: HunterTheme.slate400, fontSize: 13)),
                            Text('+HP / +MP Extended', style: TextStyle(color: HunterTheme.emerald, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HunterTheme.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 10,
                      ),
                      child: const Text(
                        'CLAIM REWARDS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
