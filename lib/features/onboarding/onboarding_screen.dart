import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadow/core/theme.dart';

/// Modèle de données pour les étapes de l'onboarding
class _StepData {
  final String title;
  final String body;
  final String buttonLabel;

  const _StepData({
    required this.title,
    required this.body,
    required this.buttonLabel,
  });
}

/// Contenu des étapes
const List<_StepData> _steps = [
  _StepData(
    title: 'Pas de mode\néchappatoire.',
    body: "Il est temps de reprendre le contrôle. Bloque les apps qui font que le focus n'existe pas, chez toi.",
    buttonLabel: 'Verrouille les',
  ),
  _StepData(
    title: "J'ai besoin\nde ta\npermission",
    body: "J'ai besoin de ta permission pour bloquer les apps si tu veux travailler à nouveau.",
    buttonLabel: 'Accorder',
  ),
  _StepData(
    title: 'Nous avons\nbesoin\nde ta permission',
    body: "Pour te permettre de mieux te concentrer, nous devons bloquer les apps qui te perturbent, et pour ça ta permission est requise.",
    buttonLabel: 'Permission',
  ),
  _StepData(
    title: 'Prêts à\nverrouiller ?',
    body: 'Rejoins tous ceux qui ont déjà bloqué...',
    buttonLabel: 'Continue',
  ),
];

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const OnboardingScreen({super.key, this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentIndex < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinished?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShadowColors.primaryGreen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicateur de progression persistant (sauf sur les pages de chargement et permissions)
            _buildStaticProgressIndicator(),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentIndex = index),
                children: [
                  _StepPage(step: _steps[0], onNext: _onNext), // 0
                  _StepPage(step: _steps[1], onNext: _onNext), // 1
                  _StepPage(step: _steps[2], onNext: _onNext), // 2
                  _LoadingPage(
                    key: const ValueKey('loading-before-permissions'),
                    onReady: _onNext,
                  ), // 3
                  _PermissionsPage(onContinue: _onNext), // 4
                  _LoadingPage(
                    key: const ValueKey('loading-after-permissions'),
                    onReady: _onNext,
                    delay: const Duration(milliseconds: 1400),
                    title: 'Configuration du\nverrouillage en cours',
                    subtitle: 'On vérifie que tout est bien activé avant de te laisser entrer.',
                  ), // 5
                  _FinalPage(step: _steps[3], onNext: _onNext), // 6
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticProgressIndicator() {
    // Les pages 3, 4 et 5 ne montrent pas les points de progression selon la logique du flow
    bool isVisible = _currentIndex < 3 || _currentIndex == 6;
    int activeDot = _currentIndex >= 6 ? 3 : _currentIndex;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: _StepDots(total: 4, activeIndex: activeDot),
      ),
    );
  }
}

/// Widget des points de progression
class _StepDots extends StatelessWidget {
  final int total;
  final int activeIndex;

  const _StepDots({required this.total, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 8),
          width: isActive ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

/// Bouton principal stylisé
class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const _PillButton({
    required this.label, 
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: ShadowColors.primaryGreen,
          disabledBackgroundColor: Colors.black.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Layout pour les étapes textuelles (1, 2, 3)
class _StepPage extends StatelessWidget {
  final _StepData step;
  final VoidCallback onNext;

  const _StepPage({required this.step, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 3),
          Text(
            step.title,
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              height: 1.15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            step.body,
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              height: 1.5,
              color: Colors.black.withOpacity(0.85),
            ),
          ),
          const Spacer(flex: 5),
          _PillButton(label: step.buttonLabel, onPressed: onNext),
        ],
      ),
    );
  }
}

/// Page de chargement réutilisable
class _LoadingPage extends StatefulWidget {
  final VoidCallback onReady;
  final Duration delay;
  final String title;
  final String subtitle;

  const _LoadingPage({
    super.key,
    required this.onReady,
    this.delay = const Duration(seconds: 2),
    this.title = 'Clique sur le bouton de validation\npour bloquer les apps',
    this.subtitle = "Pas de souci, nous n'avons aucun tracker.\nVos données sont sécurisées par Google sur votre appareil.",
  });

  @override
  State<_LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<_LoadingPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) widget.onReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          const Spacer(flex: 4),
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          const Spacer(flex: 5),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              height: 1.5,
              color: Colors.black.withOpacity(0.85),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// Modèle pour les permissions
class _PermissionItem {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const List<_PermissionItem> _permissionItems = [
  _PermissionItem(
    icon: Icons.visibility_outlined,
    title: "Accès à l'utilisation",
    description: "Pour savoir quelles apps sont ouvertes et déclencher le blocage au bon moment.",
  ),
  _PermissionItem(
    icon: Icons.layers_outlined,
    title: 'Affichage par-dessus les apps',
    description: "Pour afficher l'écran de verrouillage par-dessus les applications bloquées.",
  ),
  _PermissionItem(
    icon: Icons.accessibility_new_outlined,
    title: "Service d'accessibilité",
    description: 'Pour détecter et bloquer les apps distrayantes en temps réel.',
  ),
];

/// Page détaillée des permissions
class _PermissionsPage extends StatefulWidget {
  final VoidCallback onContinue;

  const _PermissionsPage({required this.onContinue});

  @override
  State<_PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<_PermissionsPage> {
  final List<bool> _granted = List<bool>.filled(_permissionItems.length, false);

  bool get _allGranted => _granted.every((g) => g);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Active tes\npermissions',
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              height: 1.15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chaque permission ci-dessous est nécessaire pour que le verrouillage fonctionne correctement.',
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              height: 1.5,
              color: Colors.black.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _permissionItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _permissionItems[index];
                return _PermissionCard(
                  item: item,
                  granted: _granted[index],
                  onChanged: (value) => setState(() => _granted[index] = value),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _PillButton(
            label: _allGranted ? 'Continuer' : 'Autorise tout pour continuer',
            onPressed: _allGranted ? widget.onContinue : () {},
            enabled: _allGranted,
          ),
        ],
      ),
    );
  }
}

/// Carte de permission individuelle
class _PermissionCard extends StatelessWidget {
  final _PermissionItem item;
  final bool granted;
  final ValueChanged<bool> onChanged;

  const _PermissionCard({
    required this.item,
    required this.granted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShadowColors.statBoxBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: ShadowColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    height: 1.4,
                    color: Colors.black.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: granted,
            onChanged: onChanged,
            activeColor: Colors.black,
            activeTrackColor: Colors.black.withOpacity(0.35),
          ),
        ],
      ),
    );
  }
}

/// Boîte de statistique
class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShadowColors.statBoxBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              height: 1.3,
              color: Colors.black.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page finale
class _FinalPage extends StatelessWidget {
  final _StepData step;
  final VoidCallback onNext;

  const _FinalPage({required this.step, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 3),
          Text(
            step.title,
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              height: 1.15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.body,
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              height: 1.5,
              color: Colors.black.withOpacity(0.85),
            ),
          ),
          const Spacer(flex: 3),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(
                  child: _StatBox(
                    value: '00 000+',
                    label: 'ceux qui approuvent\nlockdown',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    value: '0.0 ★',
                    label: 'sur le Play Store',
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          _PillButton(label: step.buttonLabel, onPressed: onNext),
          const SizedBox(height: 12),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.85),
                ),
                children: [
                  const TextSpan(text: 'En continuant, vous acceptez nos\n'),
                  TextSpan(
                    text: "conditions d'utilisation",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Colors.black,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Action CGU
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
