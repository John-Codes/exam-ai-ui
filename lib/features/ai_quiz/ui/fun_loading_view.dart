import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'loading_ad_bridge.dart';

/// Entertaining loading state for the AI quiz while the question API
/// cold-starts. Mirrors the classic app's loader — animated truck, rotating
/// CDL jokes / facts / pay facts, live elapsed timer and honest wait copy —
/// so a Render cold start reads as intentional instead of a blank screen.
///
/// While visible it also un-hides the HTML ad overlay reserved in the app
/// shell (`#loading-ad`), turning dead wait time into ad inventory.
class FunLoadingView extends StatefulWidget {
  const FunLoadingView({super.key, this.hint});

  /// Optional one-line context, e.g. "Loading Air Brakes questions…".
  final String? hint;

  @override
  State<FunLoadingView> createState() => _FunLoadingViewState();
}

class _FunLoadingViewState extends State<FunLoadingView> {
  static const _rotateEvery = Duration(seconds: 6);

  static const List<({IconData icon, String label, String text})> _nuggets = [
    (icon: Icons.emoji_emotions, label: 'Trucker humor', text: 'Why did the truck driver bring a ladder to work? To reach the high beams.'),
    (icon: Icons.emoji_emotions, label: 'Trucker humor', text: "I told my rig a joke about cargo. It didn't haul out laughing."),
    (icon: Icons.emoji_emotions, label: 'Trucker humor', text: "What's a trucker's favorite music? Heavy metal — obviously."),
    (icon: Icons.emoji_emotions, label: 'Trucker humor', text: 'Parallel parking a big rig is the final boss of driving.'),
    (icon: Icons.lightbulb, label: 'CDL fact', text: 'A fully loaded semi can legally weigh up to 80,000 lbs — about 36,000 kg.'),
    (icon: Icons.lightbulb, label: 'CDL fact', text: 'Air brakes use pressurized air, not fluid. That is why the low-pressure warning matters.'),
    (icon: Icons.lightbulb, label: 'CDL fact', text: 'The pre-trip inspection has over 100 checkable items. Practice makes permanent.'),
    (icon: Icons.lightbulb, label: 'CDL fact', text: 'The General Knowledge test has 50 questions in most states. You need 80% to pass.'),
    (icon: Icons.payments, label: 'Pay day', text: 'Median US heavy-truck driver pay is about \$55,000 a year — and CDL grads often out-earn college grads.'),
    (icon: Icons.payments, label: 'Pay day', text: 'Tanker and Hazmat endorsements are among the best paid — up to \$20,000+ extra per year.'),
    (icon: Icons.payments, label: 'Pay day', text: 'Owner-operators can gross \$150,000–\$300,000 a year before expenses.'),
    (icon: Icons.payments, label: 'Pay day', text: 'Many fleets pay sign-on bonuses of \$5,000–\$10,000 for new CDL drivers.'),
    (icon: Icons.route, label: 'On the road', text: 'Trucking moves about 70% of all freight tonnage in the United States.'),
    (icon: Icons.route, label: 'On the road', text: 'A typical over-the-road driver covers 100,000+ miles a year. That is 4 laps around Earth.'),
    (icon: Icons.route, label: 'On the road', text: 'The longest US interstate, I-90, runs 3,020 miles from Seattle to Boston.'),
  ];

  late final List<({IconData icon, String label, String text})> _shuffled;
  int _index = 0;
  int _elapsedSeconds = 0;
  Timer? _rotateTimer;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _shuffled = List.of(_nuggets)..shuffle(Random(42));
    setLoadingAdVisible(true);
    _rotateTimer = Timer.periodic(_rotateEvery, (_) {
      if (mounted) setState(() => _index = (_index + 1) % _shuffled.length);
    });
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    setLoadingAdVisible(false);
    _rotateTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  String get _waitMessage {
    if (_elapsedSeconds < 10) return 'Starting engine…';
    if (_elapsedSeconds < 25) return 'Fetching your questions…';
    if (_elapsedSeconds < 45) return 'Still coming — free servers nap between visits.';
    return 'Almost there — thanks for your patience!';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final nugget = _shuffled[_index];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _DrivingTruck(),
              const SizedBox(height: 24),
              Text(
                widget.hint ?? 'Waking up your AI tutor…',
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '$_waitMessage (${_elapsedSeconds}s)',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                'First load after a quiet period can take up to a minute.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  key: ValueKey(_index),
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(nugget.icon, size: 18, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            nugget.label,
                            style: text.labelMedium
                                ?.copyWith(color: scheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nugget.text,
                        style: text.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A road strip with a truck that drives across it on a looping animation.
class _DrivingTruck extends StatefulWidget {
  const _DrivingTruck();

  @override
  State<_DrivingTruck> createState() => _DrivingTruckState();
}

class _DrivingTruckState extends State<_DrivingTruck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 260,
      height: 84,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final bob = sin(t * 2 * pi) * 2;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    9,
                    (_) => Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20 + bob,
                left: (t < 0.5 ? t : 1 - t) * 180,
                child: child!,
              ),
            ],
          );
        },
        child: Icon(
          Icons.local_shipping,
          size: 44,
          color: scheme.primary,
        ),
      ),
    );
  }
}
