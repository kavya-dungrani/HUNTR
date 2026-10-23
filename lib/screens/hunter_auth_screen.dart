import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_engine.dart';
import '../providers/hunter_provider.dart';
import '../theme/hunter_theme.dart';

class HunterAuthScreen extends StatefulWidget {
  final bool initialIsSignUp;

  const HunterAuthScreen({
    super.key,
    this.initialIsSignUp = false,
  });

  @override
  State<HunterAuthScreen> createState() => _HunterAuthScreenState();
}

class _HunterAuthScreenState extends State<HunterAuthScreen>
    with SingleTickerProviderStateMixin {
  late bool _isSignUp;

  // Form Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedAffinity = 'AGI';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Map<String, ({String title, String desc, Color color, HunterStat stat})>
      _affinityDetails = {
    'STR': (
      title: 'Monarch of Destruction',
      desc: 'Overwhelming kinetic force, trials of brute iron. (+5 STR)',
      color: HunterTheme.strColor,
      stat: HunterStat.STR,
    ),
    'AGI': (
      title: 'Shadow Step Assassin',
      desc: 'Sub-second reflexes, phantom speed & rapid strikes. (+5 AGI)',
      color: HunterTheme.agiColor,
      stat: HunterStat.AGI,
    ),
    'VIT': (
      title: 'Immortal Vanguard',
      desc: 'Unbreakable stamina, maximum durability & steel defense. (+5 VIT)',
      color: HunterTheme.vitColor,
      stat: HunterStat.VIT,
    ),
    'INT': (
      title: 'Monarch of Shadows',
      desc: 'Cognitive dominance, tactical strategy & LeetCode focus. (+5 INT)',
      color: HunterTheme.intColor,
      stat: HunterStat.INT,
    ),
    'PERC': (
      title: 'Ruler\'s Authority',
      desc: 'Spatial mindfulness, razor-sharp discipline & vision. (+5 PERC)',
      color: HunterTheme.percColor,
      stat: HunterStat.PERC,
    ),
  };

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _switchMode(bool signUp) {
    setState(() {
      _isSignUp = signUp;
      _errorMessage = null;
    });
  }

  String _cleanFirebaseError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('user-not-found') || msg.contains('invalid-credential')) {
      return 'No Hunter found with these credentials or passcode is invalid.';
    }
    if (msg.contains('wrong-password')) {
      return 'Incorrect Hunter passcode. Please re-verify.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'This email is already registered. Please switch to Log In.';
    }
    if (msg.contains('weak-password')) {
      return 'Passcode is too weak. Please use at least 6 characters.';
    }
    if (msg.contains('invalid-email')) {
      return 'Invalid email address format.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Network communication failure. Please check your internet connection.';
    }
    if (msg.contains('popup_closed_by_user') || msg.contains('canceled') || msg.contains('cancelled')) {
      return 'Google sign-in was canceled.';
    }
    return msg.replaceAll(RegExp(r'\[.*?\]'), '').trim();
  }

  Future<void> _handleEmailAuth() async {
    setState(() {
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid Hunter email address.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Security passcode must be at least 6 characters.');
      return;
    }

    if (_isSignUp) {
      final name = _nameController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (name.isEmpty) {
        setState(() => _errorMessage = 'Please enter your Hunter Designation Name.');
        return;
      }
      if (password != confirmPassword) {
        setState(() => _errorMessage = 'Passcodes do not match. Please verify.');
        return;
      }

      setState(() => _isLoading = true);
      try {
        final hunter = Provider.of<HunterProvider>(context, listen: false);
        await hunter.signUpWithEmail(
          name: name,
          email: email,
          password: password,
          affinity: _selectedAffinity,
        );
      } catch (e) {
        setState(() {
          _errorMessage = _cleanFirebaseError(e);
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = true);
      try {
        final hunter = Provider.of<HunterProvider>(context, listen: false);
        await hunter.loginWithEmail(email, password);
      } catch (e) {
        setState(() {
          _errorMessage = _cleanFirebaseError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final hunter = Provider.of<HunterProvider>(context, listen: false);
      await hunter.loginWithGoogle(preferredAffinity: _selectedAffinity);
    } catch (e) {
      setState(() {
        _errorMessage = _cleanFirebaseError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGuestAwakening() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final hunter = Provider.of<HunterProvider>(context, listen: false);
      await hunter.awakenHunter(
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : 'Shadow Hunter',
        affinity: _selectedAffinity,
        isAnonymous: true,
      );
    } catch (e) {
      setState(() {
        _errorMessage = _cleanFirebaseError(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAffinity = _affinityDetails[_selectedAffinity]!;

    return Scaffold(
      backgroundColor: const Color(0xFF060812),
      body: Stack(
        children: [
          // Background ambient dungeon glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HunterTheme.cyan.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HunterTheme.purple.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Animated System Directive Badge
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: HunterTheme.cyan.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: HunterTheme.cyan.withValues(
                                      alpha: 0.3 + 0.5 * _pulseAnimation.value),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: HunterTheme.cyan.withValues(
                                        alpha: 0.25 * _pulseAnimation.value),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Text(
                                _isSignUp
                                    ? '[ SYSTEM: NEW HUNTER AWAKENING ]'
                                    : '[ SYSTEM: HUNTER GATEWAY ACCESS ]',
                                style: const TextStyle(
                                  color: HunterTheme.cyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Holographic Crest Emblem
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                (_isSignUp ? activeAffinity.color : HunterTheme.cyan)
                                    .withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                            ),
                            border: Border.all(
                              color: _isSignUp ? activeAffinity.color : HunterTheme.cyan,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isSignUp
                                        ? activeAffinity.color
                                        : HunterTheme.cyan)
                                    .withValues(alpha: 0.4),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _isSignUp ? Icons.auto_awesome : Icons.shield_rounded,
                              color: _isSignUp ? activeAffinity.color : HunterTheme.cyan,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title & Subtitle
                      Text(
                        _isSignUp ? 'HUNTER REGISTRATION' : 'HUNTER ASSOCIATION',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSignUp
                            ? 'Awaken your stats and sync your license to the cloud network'
                            : 'Synchronize your Hunter license, rank, and dungeon logs',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: HunterTheme.slate400,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Tab Toggle: LOGIN vs SIGN UP
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0d1222),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1c2438)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildModeTab(
                                title: 'LOG IN',
                                isSelected: !_isSignUp,
                                onTap: () => _switchMode(false),
                              ),
                            ),
                            Expanded(
                              child: _buildModeTab(
                                title: 'SIGN UP',
                                isSelected: _isSignUp,
                                onTap: () => _switchMode(true),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error Banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF281118),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: HunterTheme.red.withValues(alpha: 0.8),
                                width: 1.2),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: HunterTheme.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFffb4b4),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Form Fields Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0b0f1d),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: (_isSignUp
                                    ? activeAffinity.color
                                    : HunterTheme.cyan)
                                .withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SIGN UP EXTRA FIELDS
                            if (_isSignUp) ...[
                              _buildFieldLabel('HUNTER DESIGNATION / NAME'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _nameController,
                                hintText: 'e.g. Sung Jin-Woo, Shadow Monarch',
                                icon: Icons.badge_outlined,
                              ),
                              const SizedBox(height: 16),

                              // Starting Affinity Selection
                              _buildFieldLabel('AWAKENING AFFINITY (+5 BONUS)'),
                              const SizedBox(height: 8),
                              _buildAffinitySelector(),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: activeAffinity.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: activeAffinity.color.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.flash_on,
                                        color: activeAffinity.color, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${activeAffinity.title}: ${activeAffinity.desc}',
                                        style: TextStyle(
                                          color: activeAffinity.color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // EMAIL FIELD
                            _buildFieldLabel('HUNTER COMM-LINK (EMAIL)'),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: _emailController,
                              hintText: 'hunter@association.com',
                              icon: Icons.alternate_email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            // PASSWORD FIELD
                            _buildFieldLabel('SECURITY PASSCODE'),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: _passwordController,
                              hintText: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: HunterTheme.slate400,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),

                            // CONFIRM PASSWORD FIELD (SIGN UP ONLY)
                            if (_isSignUp) ...[
                              const SizedBox(height: 16),
                              _buildFieldLabel('CONFIRM SECURITY PASSCODE'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                hintText: '••••••••',
                                icon: Icons.lock_clock_outlined,
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: HunterTheme.slate400,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                            ],

                            const SizedBox(height: 22),

                            // PRIMARY ACTION BUTTON (LOGIN / SIGN UP)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: _isSignUp
                                      ? LinearGradient(
                                          colors: [
                                            activeAffinity.color,
                                            HunterTheme.purple,
                                          ],
                                        )
                                      : HunterTheme.cyanGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isSignUp
                                              ? activeAffinity.color
                                              : HunterTheme.cyan)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleEmailAuth,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _isSignUp
                                                  ? Icons.how_to_reg_rounded
                                                  : Icons.login_rounded,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                _isSignUp
                                                    ? 'AWAKEN & REGISTER'
                                                    : 'ACCESS HUNTER SYSTEM',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // DIVIDER WITH TEXT
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                      color: Color(0xFF1c2438), thickness: 1),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'OR AUTHENTICATE VIA',
                                    style: TextStyle(
                                      color: HunterTheme.slate500,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(
                                      color: Color(0xFF1c2438), thickness: 1),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // GOOGLE SIGN IN BUTTON
                            _buildGoogleButton(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // BOTTOM TOGGLE LINK (SIGN UP AT THE BOTTOM IF NO ACCOUNT)
                      Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _switchMode(!_isSignUp),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _isSignUp
                                      ? 'Already registered with the Association? '
                                      : 'Don\'t have a Hunter license or account? ',
                                  style: const TextStyle(
                                    color: HunterTheme.slate400,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  _isSignUp ? 'Log In' : 'Sign Up',
                                  style: const TextStyle(
                                    color: HunterTheme.cyanLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: HunterTheme.cyanLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Quick Offline Guest Awakening
                      Center(
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _handleGuestAwakening,
                          icon: const Icon(Icons.flash_off_rounded,
                              color: HunterTheme.slate500, size: 14),
                          label: const Text(
                            'Quick Trial / Offline Guest Mode',
                            style: TextStyle(
                              color: HunterTheme.slate500,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? HunterTheme.cyan.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: HunterTheme.cyan.withValues(alpha: 0.8), width: 1.2)
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : HunterTheme.slate400,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: HunterTheme.slate300,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: HunterTheme.slate600, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF070a14),
        prefixIcon: Icon(icon, color: HunterTheme.cyan, size: 18),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1c2438), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: HunterTheme.cyan, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAffinitySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _affinityDetails.entries.map((entry) {
          final isSelected = _selectedAffinity == entry.key;
          final color = entry.value.color;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAffinity = entry.key;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.25)
                      : const Color(0xFF0e1322),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFF1c2336),
                    width: isSelected ? 1.8 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: isSelected ? Colors.white : HunterTheme.slate400,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF111728),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26324d), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading ? null : _handleGoogleAuth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoogleIconBadge(),
                const SizedBox(width: 12),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleIconBadge() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 16,
          fontWeight: FontWeight.w900,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}
