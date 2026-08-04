import 'dart:async';
import 'package:flutter/material.dart';
import '../../../ui/theme/theme.dart';

class RestTimerSection extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback onFinished;
  final VoidCallback onClose;

  const RestTimerSection({
    super.key,
    required this.initialSeconds,
    required this.onFinished,
    required this.onClose,
  });

  @override
  State<RestTimerSection> createState() => _RestTimerSectionState();
}

class _RestTimerSectionState extends State<RestTimerSection> {
  late int _secondsLeft;
  int _breathCycleTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.initialSeconds;
    _startTimer();
  }

  @override
  void didUpdateWidget(RestTimerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSeconds != widget.initialSeconds) {
      _secondsLeft = widget.initialSeconds;
      _breathCycleTime = 0;
      _timer?.cancel();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        setState(() {
          _secondsLeft = 0;
        });
        _timer?.cancel();
        widget.onFinished();
      } else {
        setState(() {
          _secondsLeft -= 1;
          _breathCycleTime = (_breathCycleTime + 1) % 10;
        });
      }
    });
  }

  Map<String, dynamic> _getBreathGuide(int cycleTime) {
    if (cycleTime < 4) {
      // Inhale: 0s to 3s -> progress from 0.5 to 1.0
      final progress = (cycleTime + 1) / 4.0;
      return {
        'text': 'Hít vào... 👃',
        'scale': 0.5 + (progress * 0.5),
      };
    } else if (cycleTime < 6) {
      // Hold: 4s to 5s -> stay at 1.0
      return {
        'text': 'Giữ thở... 🛑',
        'scale': 1.0,
      };
    } else {
      // Exhale: 6s to 9s -> progress from 1.0 down to 0.5
      final progress = (cycleTime - 5) / 4.0;
      return {
        'text': 'Thở ra... 💨',
        'scale': 1.0 - (progress * 0.5),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = context.customColors;
    final guide = _getBreathGuide(_breathCycleTime);
    final breathText = guide['text'] as String;
    final scale = guide['scale'] as double;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: customColors.recoveryBlueBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: customColors.recoveryBlue, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      "⏱️",
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Thời gian nghỉ",
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                customColors.primaryText.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.5),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            "$_secondsLeft giây",
                            key: ValueKey<int>(_secondsLeft),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: customColors.recoveryBlue,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // +10s Button
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _secondsLeft += 10;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: customColors.recoveryBlue, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 38),
                    ),
                    child: Text(
                      "+10s",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: customColors.recoveryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Skip Button
                  ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customColors.recoveryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 38),
                    ),
                    child: const Text(
                      "Bỏ qua",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Divider(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              height: 1),
          const SizedBox(height: 12),

          // Breathing Guide Animation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular progress indicator/breathing circle
              SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        curve: Curves.linear,
                        width: 56.0 * scale,
                        height: 56.0 * scale,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFF97316).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        curve: Curves.linear,
                        width: 28.0 * scale,
                        height: 28.0 * scale,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF97316),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "NHỊP THỞ PHỤC HỒI",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF97316),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    breathText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: customColors.primaryText,
                    ),
                  )
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
