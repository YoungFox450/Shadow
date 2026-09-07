import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadow/core/theme.dart';

// Palette partagée avec l'onboarding : vert menthe, noir et typographie mono.
const Color _homeBlue = ShadowColors.primaryGreen;
// Variante légèrement estompée du vert principal pour distinguer la navigation.
const Color _homeHeaderBlue = Color(0xFF449184);

enum LockdownTab { timer, stats, settings }

class LockdownTimerScreen extends StatefulWidget {
  const LockdownTimerScreen({super.key});

  @override
  State<LockdownTimerScreen> createState() => _LockdownTimerScreenState();
}

class _LockdownTimerScreenState extends State<LockdownTimerScreen> {
  static const _stepMinutes = 15;
  static const _minimumMinutes = 15;
  static const _maximumMinutes = 24 * 60;

  int _selectedMinutes = 15;
  LockdownTab _currentTab = LockdownTab.timer;
  double _wheelDragDistance = 0;
  bool _wheelChangedDuringDrag = false;

  static const List<_Preset> _presets = [
    _Preset(minutes: 15, bigLabel: '15', smallLabel: 'minutes'),
    _Preset(minutes: 30, bigLabel: '30', smallLabel: 'minutes'),
    _Preset(minutes: 60, bigLabel: '1', smallLabel: 'hour'),
    _Preset(minutes: 90, bigLabel: '1:30', smallLabel: 'hours'),
    _Preset(minutes: 120, bigLabel: '2', smallLabel: 'hours'),
  ];

  String get _formattedDuration => _formatDuration(_selectedMinutes);

  void _selectMinutes(int minutes, {bool preserveDrag = false}) {
    if (minutes == _selectedMinutes) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMinutes = minutes;
      if (!preserveDrag) _wheelDragDistance = 0;
    });
  }

  void _handleWheelDragStart(DragStartDetails _) {
    _wheelDragDistance = 0;
    _wheelChangedDuringDrag = false;
  }

  void _handleWheelDragUpdate(DragUpdateDetails details) {
    _wheelDragDistance += details.delta.dy;
    const threshold = 34.0;
    while (_wheelDragDistance.abs() >= threshold) {
      // Le geste suit l'écran : vers le haut, on avance dans les durées.
      final direction = _wheelDragDistance < 0 ? 1 : -1;
      final next = (_selectedMinutes + direction * _stepMinutes)
          .clamp(_minimumMinutes, _maximumMinutes)
          .toInt();
      if (next == _selectedMinutes) {
        _wheelDragDistance = 0;
        break;
      }
      _selectMinutes(next, preserveDrag: true);
      _wheelChangedDuringDrag = true;
      _wheelDragDistance += _wheelDragDistance < 0 ? threshold : -threshold;
    }

    // Repeint aussi pendant le déplacement, même avant le prochain pas de
    // 15 minutes, afin que le cadran colle réellement au geste.
    if (mounted) setState(() {});
  }

  void _handleWheelDragEnd(DragEndDetails _) {
    if (_wheelDragDistance == 0) {
      _wheelChangedDuringDrag = false;
      return;
    }

    final next = _wheelChangedDuringDrag
        ? _selectedMinutes
        : (_selectedMinutes + (_wheelDragDistance < 0 ? 1 : -1) * _stepMinutes)
            .clamp(_minimumMinutes, _maximumMinutes)
            .toInt();
    _wheelDragDistance = 0;
    _wheelChangedDuringDrag = false;

    if (next != _selectedMinutes) {
      _selectMinutes(next, preserveDrag: true);
    } else if (mounted) {
      setState(() {});
    }
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
    final timerSize = (screenWidth * 0.255).clamp(78.0, 128.0).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 36),
      child: Column(
        children: [
          SizedBox(height: screenWidth * 0.215),
          Text(
            _formattedDuration,
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
            onTap: () {
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Shadow verrouillé pour $_formattedDuration',
                    style: GoogleFonts.spaceMono(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _homeBlue,
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
          child: SizedBox(
            width: screenWidth,
            height: constraints.maxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 26,
                  top: 0,
                  bottom: 0,
                  width: screenWidth * 0.5,
                  child: _buildPresetGrid(),
                ),
                Positioned.fill(
                    child: IgnorePointer(
                      child: _FlatDurationWheel(
                        selectedMinutes: _selectedMinutes,
                        dragDistance: _wheelDragDistance,
                      ),
                  ),
                ),
                Positioned(
                  left: screenWidth * 0.56,
                  right: 0,
                  top: 0,
                  bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragStart: _handleWheelDragStart,
                      onVerticalDragUpdate: _handleWheelDragUpdate,
                      onVerticalDragEnd: _handleWheelDragEnd,
                      onVerticalDragCancel: () {
                        if (_wheelDragDistance != 0 || _wheelChangedDuringDrag) {
                          setState(() {
                            _wheelDragDistance = 0;
                            _wheelChangedDuringDrag = false;
                          });
                        }
                      },
                    ),
                ),
              ],
            ),
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
      onTap: () => _selectMinutes(preset.minutes),
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
    final tabColor = selected ? Colors.black : ShadowColors.statBoxBackground;
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
            border: selected
                ? null
                : Border.all(color: Colors.black, width: 2),
          ),
          child: Icon(
            icon,
            size: 34,
            color: selected ? _homeBlue : Colors.black,
          ),
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

/// Cadran plat décalé à droite de l'écran. Le sélecteur reste fixe et le
/// calque contenant les valeurs tourne autour du centre du cadran.
class _FlatDurationWheel extends StatelessWidget {
  const _FlatDurationWheel({
    required this.selectedMinutes,
    required this.dragDistance,
  });

  final int selectedMinutes;
  final double dragDistance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final center = Offset(width * 1.126, height * 0.5);
        final radius = width * 0.503;
        final selectedIndex = selectedMinutes ~/ 15 - 1;
        const stepAngle = 2 * math.pi / 16;
        final selectedSlot = selectedIndex % 16;
        // On conserve l'angle cumulé : le cadran tourne sans se recaler
        // tous les 16 emplacements et ne donne donc jamais l'impression
        // de changer de centre ou de diamètre.
        // Une fraction du geste est conservée pour que le cadran suive
        // immédiatement le doigt, dans le même sens que son déplacement.
        final dragRotation = -dragDistance / 34.0 * stepAngle;
        final dialRotation = selectedIndex * stepAngle + dragRotation;

        final dialValues = <Widget>[];
        for (var slot = 0; slot < 16; slot++) {
          var relativeIndex = slot - selectedSlot;
          if (relativeIndex > 8) relativeIndex -= 16;
          if (relativeIndex < -8) relativeIndex += 16;
          if (relativeIndex == 0) continue;

          final minutes = selectedMinutes + relativeIndex * 15;
          if (minutes < _LockdownTimerScreenState._minimumMinutes ||
              minutes > _LockdownTimerScreenState._maximumMinutes) {
            continue;
          }

          // Les valeurs suivantes sont sous le sélecteur et remontent vers
          // lui lorsque le cadran tourne.
          final angle = math.pi - slot * stepAngle;
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
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: dialRotation),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: dialValues,
                  ),
                ),
                builder: (context, rotation, child) {
                  return Transform.rotate(
                    angle: rotation,
                    alignment: Alignment.topLeft,
                    origin: center,
                    child: child,
                  );
                },
              ),
            ),
            Positioned(
              left: center.dx - radius,
              top: center.dy - 45,
              width: width - (center.dx - radius),
              height: 90,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(45),
                    bottomLeft: Radius.circular(45),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 25, height: 4, color: _homeBlue),
                      const SizedBox(width: 14),
                      Text(
                        _formatDuration(selectedMinutes),
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
  const _LockdownButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(45),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(color: _homeBlue, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 36),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 70),
                  child: Text(
                    'LOCKDOWN',
                    style: GoogleFonts.spaceMono(
                      color: _homeBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
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

String _formatDuration(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return hours.toString().padLeft(2, '0') +
      ':' +
      minutes.toString().padLeft(2, '0');
}
