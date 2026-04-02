import 'package:flutter/material.dart';
import 'package:at_onboarding_flutter/at_onboarding_flutter.dart';
import '../constants.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // Wipe keychain so at_onboarding_flutter always shows the login/atKey
    // upload screen — never auto-authenticates. Start animation after.
    _resetSession().then((_) {
      if (mounted) _animController.forward();
    });
  }

  /// Wipe all AtSigns from the device keychain so `at_onboarding_flutter`
  /// has no cached credential to auto-authenticate with. The .atKey file and
  /// Hive data on disk are untouched — only the stored-AtSign list is cleared.
  Future<void> _resetSession() async {
    try {
      AtClientManager.getInstance().reset();
    } catch (_) {}
    try {
      final manager = KeyChainManager.getInstance();
      final stored = await manager.getAtSignListFromKeychain();
      for (final atSign in stored) {
        await manager.deleteAtSignFromKeychain(atSign);
      }
    } catch (_) {}
  }

  /// Called by the "Sign in" button.
  Future<void> _startOnboarding() async {
    if (_busy) return;
    setState(() => _busy = true);

    // Step 1: open the standard onboarding flow WITHOUT a pre-configured
    // AtClientPreference — the onboarding UI lets the user pick their AtSign.
    // We build a preference with a unique temp directory so two windows
    // opened simultaneously don't lock each other's keystore files.
    final result = await AtOnboarding.onboard(
      context: context,
      config: AtOnboardingConfig(
        atClientPreference: AtManagementApp.preferencesFor(
            'temp_${DateTime.now().millisecondsSinceEpoch}'),
        rootEnvironment: RootEnvironment.Production,
        domain: atDirectoryHost,
        appAPIKey: '477b-876u-bcez-nio5-um4f-832q',
      ),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (result.status == AtOnboardingResultStatus.success) {
      // Step 2: Now that we know the AtSign, rebuild the preference with the
      // correct per-AtSign storage path and re-init the AtClient.
      final atSign =
          AtClientManager.getInstance().atClient.getCurrentAtSign() ?? 'unknown';

      final preference = AtManagementApp.preferencesFor(atSign);
      await AtClientManager.getInstance().setCurrentAtSign(
        atSign,
        appNamespace,
        preference,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (result.status == AtOnboardingResultStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Sign-in failed: ${result.message ?? "Unknown error"}'),
        ),
      );
    }
    // AtOnboardingResultStatus.cancel → user dismissed, do nothing.
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),

                    // Logo
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.atsignWhite,
                            AppTheme.atsignWhite,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.orangeGlow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset('assets/atsign_logo.png', fit: BoxFit.contain),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'AtManagement',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Zero-Trust Project Management\nPowered by the atPlatform',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    _featureCard(
                      Icons.lock_outline_rounded,
                      'End-to-End Encrypted',
                      'Your data is encrypted before it leaves your device',
                    ),
                    const SizedBox(height: 10),
                    _featureCard(
                      Icons.cloud_off_rounded,
                      'No Central Server',
                      'Data lives on your personal atServer only',
                    ),
                    const SizedBox(height: 10),
                    _featureCard(
                      Icons.shield_outlined,
                      'Instant Access Revocation',
                      'Remove team members with a single tap',
                    ),

                    const SizedBox(height: 40),

                    _busy
                        ? const CircularProgressIndicator(
                            color: AppTheme.atsignOrange)
                        : _OnboardButton(onTap: _startOnboarding),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _featureCard(
      IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.atsignOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.atsignOrange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated CTA button ──────────────────────────────────────────────────────

class _OnboardButton extends StatefulWidget {
  final VoidCallback onTap;
  const _OnboardButton({required this.onTap});

  @override
  State<_OnboardButton> createState() => _OnboardButtonState();
}

class _OnboardButtonState extends State<_OnboardButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hovered
                    ? [AppTheme.atsignOrangeDark, AppTheme.atsignOrange]
                    : [AppTheme.atsignOrange, AppTheme.atsignOrangeDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: _hovered
                  ? AppTheme.orangeGlow
                  : [
                      BoxShadow(
                        color: AppTheme.atsignOrange.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.alternate_email, size: 20, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Sign in with your AtSign',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
