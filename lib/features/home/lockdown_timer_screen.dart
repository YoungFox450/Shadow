import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadow/core/theme.dart';

enum LockdownTab { timer, stats, settings }

class LockdownTimerScreen extends StatefulWidget {
  const LockdownTimerScreen({super.key});

  @override
  State<LockdownTimerScreen> createState() => _LockdownTimerScreenState();
}

class _LockdownTimerScreenState extends State<LockdownTimerScreen> {
  int _selectedMinutes = 15;
  LockdownTab _currentTab = LockdownTab.timer;

  static const List<_Preset> _presets = [
    _Preset(minutes: 15, bigLabel: '15', smallLabel: 'minutes'),
    _Preset(minutes: 30, bigLabel: '30', smallLabel: 'minutes'),
    _Preset(minutes: 60, bigLabel: '1', smallLabel: 'hour'),
    _Preset(minutes: 90, bigLabel: '1:30', smallLabel: 'hours'),
    _Preset(minutes: 120, bigLabel: '2', smallLabel: 'hours'),
  ];

  String get _formattedDuration {
    final hours = _selectedMinutes ~/ 60;
    final minutes = _selectedMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  void _selectMinutes(int minutes) {
    HapticFeedback.selectionClick();
    setState(() => _selectedMinutes = minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShadowColors.primaryGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopTabBar(
              currentTab: _currentTab,
              onTabSelected: (tab) => setState(() => _currentTab = tab),
            ),
            Expanded(
              child: _currentTab == LockdownTab.timer
                  ? _buildTimerBody()
                  : _PlaceholderTab(tab: _currentTab),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 0, 20),
      child: Column(
        children: [
          // Gros chrono central
          Text(
            _formattedDuration,
            style: GoogleFonts.spaceMono(
              fontSize: 76,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              height: 1.0,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 36),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Colonne de gauche : 15 min / 30 min / 1 heure
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Expanded(child: _presetTile(_presets[0])),
                            const SizedBox(height: 12),
                            Expanded(child: _presetTile(_presets[1])),
                            const SizedBox(height: 12),
                            Expanded(child: _presetTile(_presets[2])),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Colonne de droite : 1:30 en haut, 2 heures (double hauteur)
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Expanded(child: _presetTile(_presets[3])),
                            const SizedBox(height: 12),
                            Expanded(flex: 2, child: _presetTile(_presets[4])),
                          ],
                        ),
                      ),
                      // Espace réservé pour la molette
                      const Expanded(flex: 3, child: SizedBox()),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: -40,
                    width: 230,
                    child: _DurationWheelPicker(
                      selectedMinutes: _selectedMinutes,
                      onChanged: _selectMinutes,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: _LockdownButton(
              onTap: () {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Shadow verrouillé pour $_formattedDuration",
                      style: GoogleFonts.spaceMono(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: ShadowColors.primaryGreen,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetTile(_Preset preset) {
    return _PresetDurationButton(
      bigLabel: preset.bigLabel,
      smallLabel: preset.smallLabel,
      isSelected: _selectedMinutes == preset.minutes,
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

// --- WIDGETS INTERNES ---

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
      color: Colors.black.withOpacity(0.05),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              _TabPill(
                icon: Icons.timer_outlined,
                isSelected: currentTab == LockdownTab.timer,
                onTap: () => onTabSelected(LockdownTab.timer),
              ),
              const SizedBox(width: 12),
              _TabPill(
                icon: Icons.show_chart_rounded,
                isSelected: currentTab == LockdownTab.stats,
                onTap: () => onTabSelected(LockdownTab.stats),
              ),
              const SizedBox(width: 12),
              _TabPill(
                icon: Icons.settings_outlined,
                isSelected: currentTab == LockdownTab.settings,
                onTap: () => onTabSelected(LockdownTab.settings),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = i < 4;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? Colors.black : Colors.transparent,
                    border: filled ? null : Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 64,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.black.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          icon,
          color: isSelected ? ShadowColors.primaryGreen : Colors.black,
          size: 22,
        ),
      ),
    );
  }
}

class _PresetDurationButton extends StatelessWidget {
  const _PresetDurationButton({
    required this.bigLabel,
    required this.smallLabel,
    required this.isSelected,
    required this.onTap,
  });

  final String bigLabel;
  final String smallLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black, width: 2.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bigLabel,
              style: GoogleFonts.spaceMono(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color: isSelected ? ShadowColors.primaryGreen : Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              smallLabel,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? ShadowColors.primaryGreen : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationWheelPicker extends StatefulWidget {
  const _DurationWheelPicker({
    required this.selectedMinutes,
    required this.onChanged,
    this.stepMinutes = 15,
    this.maxMinutes = 240,
  });

  final int selectedMinutes;
  final ValueChanged<int> onChanged;
  final int stepMinutes;
  final int maxMinutes;

  @override
  State<_DurationWheelPicker> createState() => _DurationWheelPickerState();
}

class _DurationWheelPickerState extends State<_DurationWheelPicker> {
  late final List<int> _values;
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _values = [
      for (int m = widget.stepMinutes; m <= widget.maxMinutes; m += widget.stepMinutes) m,
    ];
    _controller = FixedExtentScrollController(initialItem: _indexFor(widget.selectedMinutes));
  }

  @override
  void didUpdateWidget(covariant _DurationWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = _indexFor(widget.selectedMinutes);
    if (targetIndex != _controller.selectedItem) {
      _controller.animateToItem(
        targetIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  int _indexFor(int minutes) {
    final clamped = minutes.clamp(widget.stepMinutes, widget.maxMinutes);
    final index = (clamped / widget.stepMinutes).round() - 1;
    return index.clamp(0, _values.length - 1);
  }

  String _format(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: 54,
      diameterRatio: 1.15,
      perspective: 0.006,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        widget.onChanged(_values[index]);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: _values.length,
        builder: (context, index) {
          final minutes = _values[index];
          final isSelected = minutes == widget.selectedMinutes;
          return _WheelItem(
            label: _format(minutes),
            isSelected: isSelected,
          );
        },
      ),
    );
  }
}

class _WheelItem extends StatelessWidget {
  const _WheelItem({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final tickWidth = isSelected ? 22.0 : 14.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tickWidth,
          height: 2.5,
          color: isSelected ? ShadowColors.primaryGreen : Colors.black,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: isSelected ? 20 : 15,
            fontWeight: FontWeight.w700,
            color: isSelected ? ShadowColors.primaryGreen : Colors.black,
          ),
        ),
      ],
    );

    if (!isSelected) {
      return Center(child: content);
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(30),
        ),
        child: content,
      ),
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
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ShadowColors.primaryGreen, width: 2),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: ShadowColors.primaryGreen,
                size: 22,
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 46),
                  child: Text(
                    'LOCKDOWN',
                    style: GoogleFonts.spaceMono(
                      color: ShadowColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
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
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}
