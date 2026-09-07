import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadow/core/theme.dart';

/// Palette de couleurs de Shadow.
const Color _homeBlue = ShadowColors.primaryGreen;
const Color _homeHeaderBlue = Color(0xFF449184);

enum LockdownTab { timer, stats, settings }

/// Écran principal gérant le minuteur avec une logique mécanique d'odomètre et de roue crantée.
class LockdownTimerScreen extends StatefulWidget {
  const LockdownTimerScreen({super.key});

  @override
  State<LockdownTimerScreen> createState() => _LockdownTimerScreenState();
}

class _LockdownTimerScreenState extends State<LockdownTimerScreen>
    with SingleTickerProviderStateMixin {
  static const _stepMinutes = 15;
  static const _minimumMinutes = 15;
  static const _maximumMinutes = 24 * 60; // 24 heures

  /// Valeur cible (snap) pour le minuteur.
  int _selectedMinutes = 15;

  /// Valeur visuelle continue pilotant les roues de l'odomètre et le cadran.
  double _animatedMinutes = 15.0;

  LockdownTab _currentTab = LockdownTab.timer;

  /// Contrôleur gérant les transitions fluides.
  late final AnimationController _animController;
  Animation<double>? _minutesAnimation;

  /// Gestion du glissement (drag).
  double _dragStartY = 0;
  double _dragStartMinutes = 0;
  bool _isDragging = false;

  static const List<_Preset> _presets = [
    _Preset(minutes: 15, bigLabel: '15', smallLabel: 'minutes'),
    _Preset(minutes: 30, bigLabel: '30', smallLabel: 'minutes'),
    _Preset(minutes: 60, bigLabel: '1', smallLabel: 'heure'),
    _Preset(minutes: 90, bigLabel: '1:30', smallLabel: 'heures'),
    _Preset(minutes: 120, bigLabel: '2', smallLabel: 'heures'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        if (_minutesAnimation != null) {
          setState(() => _animatedMinutes = _minutesAnimation!.value);
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Anime la durée vers une cible (transition "Preset" ou "Snap").
  void _animateToMinutes(int targetMinutes, {bool fast = false}) {
    if (targetMinutes == _selectedMinutes && !_isDragging && _animController.isAnimating) return;

    HapticFeedback.selectionClick();
    _selectedMinutes = targetMinutes;

    final distance = (_animatedMinutes - targetMinutes).abs();
    final duration = fast
        ? (220 + distance * 4).clamp(260, 700).toInt()
        : (300 + distance * 8).clamp(320, 850).toInt();
    _animController.duration = Duration(milliseconds: duration);

    _minutesAnimation = Tween<double>(
      begin: _animatedMinutes,
      end: targetMinutes.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward(from: 0);
  }

  /// Début du glissement. Zone de détection élargie pour plus de confort.
  void _handleDragStart(DragStartDetails details) {
    _animController.stop();
    setState(() {
      _isDragging = true;
      _dragStartY = details.globalPosition.dy;
      _dragStartMinutes = _animatedMinutes;
    });
  }

  /// Mise à jour du glissement : l'odomètre suit le doigt au pixel près.
  void _handleDragUpdate(DragUpdateDetails details) {
    final deltaY = details.globalPosition.dy - _dragStartY;
    // Ratio : 1 min de temps pour 2.8 pixels de glissement vertical.
    final deltaMinutes = -deltaY / 2.8;

    double newValue = (_dragStartMinutes + deltaMinutes)
        .clamp(_minimumMinutes.toDouble(), _maximumMinutes.toDouble());

    if (newValue != _animatedMinutes) {
      setState(() {
        _animatedMinutes = newValue;
        _selectedMinutes = ((newValue / _stepMinutes).round() * _stepMinutes).toInt();
      });

      // Feedback haptique discret aux paliers.
      if ((_animatedMinutes % _stepMinutes).abs() < 0.2) {
        // HapticFeedback.lightImpact();
      }
    }
  }

  /// Fin du glissement : recalage automatique.
  void _handleDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);

    final velocityY = details.velocity.pixelsPerSecond.dy;
    final hasFling = velocityY.abs() > 500;
    final momentum = hasFling
        ? (-velocityY * 0.10).clamp(-360.0, 360.0)
        : 0.0;
    final target = ((_animatedMinutes + momentum) / _stepMinutes).round() *
        _stepMinutes;
    final clampedTarget = target
        .clamp(_minimumMinutes, _maximumMinutes)
        .toInt();

    _animateToMinutes(clampedTarget, fast: hasFling);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _homeHeaderBlue,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _homeBlue,
        body: ColoredBox(
          color: _homeHeaderBlue,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopTabBar(
                  currentTab: _currentTab,
                  onTabSelected: (tab) => setState(() => _currentTab = tab),
                ),
                Expanded(
                  child: ColoredBox(
                    color: _homeBlue,
                    child: _currentTab == LockdownTab.timer
                        ? _buildTimerBody()
                        : _PlaceholderTab(tab: _currentTab),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBody() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final timerSize = (screenWidth * 0.235).clamp(70.0, 115.0).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 36),
      child: Column(
        children: [
          SizedBox(height: screenWidth * 0.20),
          // Odomètre mécanique à 4 roues crantées.
          _OdometerDurationDisplay(
            minutes: _animatedMinutes,
            style: GoogleFonts.spaceMono(
              fontSize: timerSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              height: 1,
              color: Colors.black,
            ),
          ),
          SizedBox(height: screenWidth * 0.16),
          Expanded(child: _buildCentralZone(screenWidth)),
          const SizedBox(height: 26),
          _LockdownButton(
            onCompleted: () {
              HapticFeedback.heavyImpact();
              Navigator.of(context).push(
                PageRouteBuilder<void>(
                  transitionDuration: const Duration(milliseconds: 260),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      _LockdownActiveScreen(duration: Duration(minutes: _selectedMinutes)),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                      FadeTransition(opacity: animation, child: child),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCentralZone(double screenWidth) {
    return LayoutBuilder(
      builder: (context, constraints) => Transform.translate(
        offset: const Offset(-26, 0),
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: screenWidth,
          maxWidth: screenWidth,
          minHeight: constraints.maxHeight,
          maxHeight: constraints.maxHeight,
          child: Stack(
            children: [
              // Grille des presets à gauche.
              Positioned(
                left: 26,
                top: 0,
                bottom: 0,
                width: screenWidth * 0.5,
                child: _buildPresetGrid(),
              ),
              // Cadran rotatif visuel.
              Positioned.fill(
                child: IgnorePointer(
                  child: _FlatDurationWheel(
                    displayMinutes: _animatedMinutes,
                  ),
                ),
              ),
              // Zone de détection du geste couvrant toute la moitié droite et le centre.
              Positioned(
                left: screenWidth * 0.58,
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  dragStartBehavior: DragStartBehavior.down,
                  onPanStart: _handleDragStart,
                  onPanUpdate: _handleDragUpdate,
                  onPanEnd: _handleDragEnd,
                  onPanCancel: () {
                    if (_isDragging) {
                      setState(() => _isDragging = false);
                      _animateToMinutes(_selectedMinutes);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetGrid() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _presetTile(_presets[0])),
              const SizedBox(width: 20),
              Expanded(child: _presetTile(_presets[3])),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _presetTile(_presets[1])),
                    const SizedBox(height: 20),
                    Expanded(child: _presetTile(_presets[2])),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: _presetTile(_presets[4])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetTile(_Preset preset) {
    return _PresetDurationButton(
      preset: preset,
      selected: _selectedMinutes == preset.minutes,
      onTap: () => _animateToMinutes(preset.minutes),
    );
  }
}

class _Preset {
  const _Preset({
    required this.minutes,
    required this.bigLabel,
    required this.smallLabel,
  });

  final int minutes;
  final String bigLabel;
  final String smallLabel;
}

/// Affichage odomètre mécanique avec cascade de mouvements (Carry-over).
class _OdometerDurationDisplay extends StatelessWidget {
  const _OdometerDurationDisplay({
    required this.minutes,
    required this.style,
  });

  final double minutes;
  final TextStyle style;

  /// Réalise le mouvement mécanique : une roue ne tourne que pour le carry-over
  /// de la roue de rang inférieur (transition 9->0 ou 5->0).
  double mechanicalStep(double value, double range) {
    final floor = (value / range).floor();
    final fract = (value / range) - floor;
    // La roue suivante ne tourne que sur les derniers 10% du tour actuel.
    if (fract < 0.9) return floor.toDouble();
    return floor + (fract - 0.9) * 10.0;
  }

  @override
  Widget build(BuildContext context) {
    // Calcul des steps continus pour chaque roue :
    final m2Steps = minutes; // M2 tourne tout le temps
    final m1Steps = mechanicalStep(minutes, 10.0); // M1 attend 10 unités de M2
    final h2Steps = mechanicalStep(minutes, 60.0); // H2 attend 60 unités (1h)
    final h1Steps = mechanicalStep(minutes, 600.0); // H1 attend 600 unités (10h)

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _OdometerDigitWheel(
          key: const ValueKey('h1-digit'),
          stepIndex: h1Steps,
          modulo: 10,
          style: style,
        ),
        _OdometerDigitWheel(
          key: const ValueKey('h2-digit'),
          stepIndex: h2Steps,
          modulo: 10,
          style: style,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Text(':', style: style),
        ),
        _OdometerDigitWheel(
          key: const ValueKey('m1-digit'),
          stepIndex: m1Steps,
          modulo: 6,
          style: style,
        ),
        _OdometerDigitWheel(
          key: const ValueKey('m2-digit'),
          stepIndex: m2Steps,
          modulo: 10,
          style: style,
        ),
      ],
    );
  }
}

/// Une roue dentée de l'odomètre pilotée directement par l'offset.
class _OdometerDigitWheel extends StatefulWidget {
  const _OdometerDigitWheel({
    super.key,
    required this.stepIndex,
    required this.modulo,
    required this.style,
  });

  final double stepIndex;
  final int modulo;
  final TextStyle style;

  @override
  State<_OdometerDigitWheel> createState() => _OdometerDigitWheelState();
}

class _OdometerDigitWheelState extends State<_OdometerDigitWheel> {
  static const _baseOffset = 10000;
  late final FixedExtentScrollController _controller;

  int get _alignedBaseOffset =>
      _baseOffset - (_baseOffset % widget.modulo);

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: _alignedBaseOffset + widget.stepIndex.toInt(),
    );
  }

  @override
  void didUpdateWidget(covariant _OdometerDigitWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.hasClients) {
      final fontSize = widget.style.fontSize ?? 80;
      final itemExtent = fontSize * 1.05;
      _controller.jumpTo(
        (_alignedBaseOffset + widget.stepIndex) * itemExtent,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.style.fontSize ?? 80;
    final itemExtent = fontSize * 1.05;
    final digitWidth = fontSize * 0.62;

    return SizedBox(
      width: digitWidth,
      height: itemExtent,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: itemExtent,
        physics: const NeverScrollableScrollPhysics(),
        diameterRatio: 1.8,
        perspective: 0.005,
        squeeze: 1.0,
        childDelegate: ListWheelChildLoopingListDelegate(
          children: List.generate(
            widget.modulo,
            (digit) => Center(
              child: Text('$digit', style: widget.style, maxLines: 1),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barre d'onglets supérieure.
class _TopTabBar extends StatelessWidget {
  const _TopTabBar({
    required this.currentTab,
    required this.onTabSelected,
  });

  final LockdownTab currentTab;
  final ValueChanged<LockdownTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _homeHeaderBlue,
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TabItem(
            icon: Icons.timer_outlined,
            selected: currentTab == LockdownTab.timer,
            onTap: () => onTabSelected(LockdownTab.timer),
          ),
          const SizedBox(width: 8),
          _TabItem(
            icon: Icons.show_chart_rounded,
            selected: currentTab == LockdownTab.stats,
            onTap: () => onTabSelected(LockdownTab.stats),
          ),
          const SizedBox(width: 8),
          _TabItem(
            icon: Icons.settings_rounded,
            selected: currentTab == LockdownTab.settings,
            onTap: () => onTabSelected(LockdownTab.settings),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final usableWidth = MediaQuery.sizeOf(context).width - 32;
    final tabColor = selected ? _homeBlue : ShadowColors.statBoxBackground;
    return SizedBox(
      width: usableWidth * (selected ? 0.385 : 0.275),
      height: selected ? 90 : 76,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tabColor,
            borderRadius: selected
                ? const BorderRadius.vertical(top: Radius.circular(34))
                : BorderRadius.circular(38),
            border: selected ? null : Border.all(color: Colors.black, width: 2),
          ),
          child: Icon(icon, size: 34, color: Colors.black),
        ),
      ),
    );
  }
}

class _PresetDurationButton extends StatelessWidget {
  const _PresetDurationButton({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final _Preset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? _homeBlue : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black, width: 2.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              preset.bigLabel,
              style: GoogleFonts.spaceMono(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1,
                color: foreground,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              preset.smallLabel,
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cadran rotatif dont la rotation est synchronisée sur displayMinutes.
class _FlatDurationWheel extends StatelessWidget {
  const _FlatDurationWheel({
    required this.displayMinutes,
  });

  final double displayMinutes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final center = Offset(width * 1.126, height * 0.5);
        final radius = width * 0.503;
        const stepAngle = 2 * math.pi / 16;

        // La position du cadran reste continue pendant toute l'animation.
        // Il ne faut pas faire tourner un sous-ensemble de repères puis
        // remettre sa rotation à zéro à chaque nouveau créneau : ce reset
        // est perceptible pendant les transitions animées.
        final clampedMinutes = displayMinutes
            .clamp(15.0, 1440.0)
            .toDouble();
        final slotPosition = clampedMinutes / 15.0;
        final centerSlot = slotPosition.round().clamp(1, 96).toInt();
        final visibleMinutes = ((clampedMinutes / 15).round() * 15)
            .clamp(15, 1440)
            .toInt();

        final dialValues = <Widget>[];
        // Fenêtre de labels autour du curseur. Chaque label est positionné
        // directement avec la position continue du doigt/ressort.
        for (var i = -8; i <= 8; i++) {
          final slotIndex = centerSlot + i;
          if (slotIndex == centerSlot) continue;
          final minutes = slotIndex * 15;
          if (minutes < 15 || minutes > 1440) continue;

          final offset = slotIndex - slotPosition;
          final angle = math.pi - offset * stepAngle;
          final point = Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          );

          dialValues.add(
            Positioned(
              left: point.dx + width * 0.045,
              top: point.dy - 18,
              width: width * 0.31,
              height: 38,
              child: Transform.rotate(
                angle: angle - math.pi,
                alignment: Alignment.centerLeft,
                child: _ArcLabel(label: _formatDuration(minutes)),
              ),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Stack(clipBehavior: Clip.none, children: dialValues),
            ),
            // Sélecteur central (pilule noire).
            Positioned(
              left: center.dx - radius,
              top: center.dy - 36,
              width: width - (center.dx - radius),
              height: 72,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    bottomLeft: Radius.circular(36),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 25, height: 4, color: _homeBlue),
                        const SizedBox(width: 14),
                        Text(
                          _formatDuration(visibleMinutes),
                          style: GoogleFonts.spaceMono(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _homeBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ArcLabel extends StatelessWidget {
  const _ArcLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 28, height: 5, color: Colors.black),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _LockdownButton extends StatelessWidget {
  const _LockdownButton({required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return _SwipeLockdownButton(onCompleted: onCompleted);
  }
}

class _SwipeLockdownButton extends StatefulWidget {
  const _SwipeLockdownButton({required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<_SwipeLockdownButton> createState() => _SwipeLockdownButtonState();
}

class _SwipeLockdownButtonState extends State<_SwipeLockdownButton>
    with SingleTickerProviderStateMixin {
  static const _thumbSize = 70.0;
  static const _horizontalPadding = 10.0;
  double _progress = 0;
  late final AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() => setState(() => _progress = _snapAnimation.value));
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _updateProgress(DragUpdateDetails details, double trackWidth) {
    final travel = trackWidth - _thumbSize - (_horizontalPadding * 2);
    if (travel <= 0) return;
    _snapController.stop();
    setState(() {
      _progress = (_progress + details.delta.dx / travel).clamp(0.0, 1.0).toDouble();
    });
  }

  void _finishDrag() {
    if (_progress >= 0.96) {
      setState(() => _progress = 1);
      HapticFeedback.mediumImpact();
      _snapTo(0);
      widget.onCompleted();
    } else {
      _snapTo(0);
    }
  }

  void _snapTo(double value) {
    _snapController.stop();
    _snapAnimation = Tween<double>(begin: _progress, end: value).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final travel = constraints.maxWidth - _thumbSize - (_horizontalPadding * 2);
        final left = _horizontalPadding + travel * _progress;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => _updateProgress(details, constraints.maxWidth),
          onHorizontalDragEnd: (_) => _finishDrag(),
          onHorizontalDragCancel: () => _snapTo(0),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(45),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: Text(
                      'VERROUILLER',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        color: _homeBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: left,
                  top: _horizontalPadding,
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: const BoxDecoration(
                      color: _homeBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Transform.rotate(
                      angle: -math.pi * _progress,
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.black,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LockdownActiveScreen extends StatefulWidget {
  const _LockdownActiveScreen({required this.duration});

  final Duration duration;

  @override
  State<_LockdownActiveScreen> createState() => _LockdownActiveScreenState();
}

class _LockdownActiveScreenState extends State<_LockdownActiveScreen> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _remaining = widget.duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= Duration.zero) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        systemNavigationBarColor: Colors.black,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'VERROUILLAGE ACTIF',
                  style: GoogleFonts.spaceMono(
                    color: _homeBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '${_remaining.inHours.toString().padLeft(2, '0')}:${(_remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.spaceMono(
                    color: _homeBlue,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'MODE FOCUS',
                  style: GoogleFonts.spaceMono(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
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

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.tab});

  final LockdownTab tab;

  @override
  Widget build(BuildContext context) {
    final label = tab == LockdownTab.stats ? 'Statistiques' : 'Réglages';
    return Center(
      child: Text(
        label,
        style: GoogleFonts.spaceMono(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}

String _formatDuration(num totalMinutes) {
  final int minutesInt = totalMinutes.toInt();
  final hours = minutesInt ~/ 60;
  final minutes = minutesInt % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}
