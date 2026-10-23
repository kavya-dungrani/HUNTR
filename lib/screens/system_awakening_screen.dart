import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../theme/hunter_theme.dart';

class SystemAwakeningScreen extends StatefulWidget {
  const SystemAwakeningScreen({super.key});

  @override
  State<SystemAwakeningScreen> createState() => _SystemAwakeningScreenState();
}

class _SystemAwakeningScreenState extends State<SystemAwakeningScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedAffinity = 'AGI';
  bool _useEmailAuth = false;
  late AnimationController _pulseController;

  final Map<String, ({String title, String desc, Color color, HunterStat stat})> _affinityDetails = {
    'STR': (
      title: 'Monarch of Destruction',
      desc: 'Overwhelming physical force, unyielding kinetic power, and trials of brute iron.',
      color: HunterTheme.strColor,
      stat: HunterStat.STR,
    ),
    'AGI': (
      title: 'Shadow Step Assassin',
      desc: 'Sub-second reflexes, high-velocity sprints, swift execution, and phantom evasions.',
      color: HunterTheme.agiColor,
      stat: HunterStat.AGI,
    ),
    'VIT': (
      title: 'Immortal Vanguard',
      desc: 'Unbreakable cellular stamina, rapid recovery, physical endurance, and steel defense.',
      color: HunterTheme.vitColor,
      stat: HunterStat.VIT,
    ),
    'INT': (
      title: 'Monarch of Shadows',
      desc: 'Deep cognitive architecture, supreme problem solving, LeetCode mastery, and knowledge.',
      color: HunterTheme.intColor,
      stat: HunterStat.INT,
    ),
    'PERC': (
      title: 'Ruler\'s Authority',
      desc: 'Absolute spatial mindfulness, razor discipline, sixth sense, and mental focus.',
      color: HunterTheme.percColor,
      stat: HunterStat.PERC,
    ),
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAwakening() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1f283d),
          content: Text('Please enter your Hunter Designation Name', style: TextStyle(color: HunterTheme.red)),
        ),
      );
      return;
    }

    final hunter = Provider.of<HunterProvider>(context, listen: false);

    if (_useEmailAuth) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isEmpty || password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1f283d),
            content: Text('Please enter valid email and password (min 6 chars)', style: TextStyle(color: HunterTheme.red)),
          ),
        );
        return;
      }
      await hunter.awakenHunter(
        name: name,
        affinity: _selectedAffinity,
        email: email,
        password: password,
      );
    } else {
      await hunter.awakenHunter(
        name: name,
        affinity: _selectedAffinity,
        isAnonymous: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAffinity = _affinityDetails[_selectedAffinity]!;

    return Scaffold(
      backgroundColor: const Color(0xFF060810),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              // Solo Leveling System Notice Box
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: HunterTheme.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: HunterTheme.cyan.withValues(alpha: 0.3 + 0.5 * _pulseController.value),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: HunterTheme.cyan.withValues(alpha: 0.2 * _pulseController.value),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: const Text(
                      '[ SYSTEM DIRECTIVE: HUNTER AWAKENING ]',
                      style: TextStyle(
                        color: HunterTheme.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Summoning Rune Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      activeAffinity.color.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(color: activeAffinity.color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: activeAffinity.color.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.shield_outlined, color: activeAffinity.color, size: 48),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'THE HUNTER SYSTEM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Only you have been chosen to transcend limits and awaken as a Monarch.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HunterTheme.slate400,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // 1. Hunter Name Input
              Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'STEP 1: DESIGNATION (HUNTER NAME)',
                  style: TextStyle(color: HunterTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'e.g. Sung Jin-Woo',
                  hintStyle: const TextStyle(color: HunterTheme.slate500, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFF101525),
                  prefixIcon: const Icon(Icons.person, color: HunterTheme.cyan),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF222c44)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: HunterTheme.cyan, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 2. Combat Affinity Selector
              Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'STEP 2: COMBAT AFFINITY (PRIMARY STAT)',
                  style: TextStyle(color: HunterTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _affinityDetails.keys.map((aff) {
                  final isSel = _selectedAffinity == aff;
                  final color = _affinityDetails[aff]!.color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAffinity = aff),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: isSel ? color.withValues(alpha: 0.25) : const Color(0xFF101525),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? color : const Color(0xFF222c44),
                          width: isSel ? 2 : 1,
                        ),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          aff,
                          style: TextStyle(
                            color: isSel ? Colors.white : HunterTheme.slate400,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Affinity Card Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0e1322),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: activeAffinity.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeAffinity.title,
                      style: TextStyle(color: activeAffinity.color, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeAffinity.desc,
                      style: const TextStyle(color: HunterTheme.slate400, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3. Firebase Auth Credentials Option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AUTHENTICATION MODE',
                    style: TextStyle(color: HunterTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _useEmailAuth = !_useEmailAuth),
                    child: Text(
                      _useEmailAuth ? 'Switch to Quick Awakening' : 'Use Firebase Email & Pass',
                      style: const TextStyle(color: HunterTheme.cyanLight, fontSize: 12),
                    ),
                  ),
                ],
              ),

              if (_useEmailAuth) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'hunter@guild.com',
                    hintStyle: const TextStyle(color: HunterTheme.slate500, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF101525),
                    prefixIcon: const Icon(Icons.email, color: HunterTheme.cyan),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password (min 6 characters)',
                    hintStyle: const TextStyle(color: HunterTheme.slate500, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF101525),
                    prefixIcon: const Icon(Icons.lock, color: HunterTheme.cyan),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // AWAKEN BUTTON
              Consumer<HunterProvider>(
                builder: (context, hunter, _) {
                  if (hunter.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: HunterTheme.cyan));
                  }
                  return Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [HunterTheme.cyan, activeAffinity.color],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: HunterTheme.cyan.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _handleAwakening,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'INITIATE SYSTEM AWAKENING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
