import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Animated launch screen layered above the app.
///
/// Its first frame is pixel-identical to the native splash (white, logo
/// centred at [logoSize]), so swapping the native splash for it is
/// invisible. It then plays a short branded intro and, once the intro has
/// finished *and* [ready] completes, reveals the app underneath.
class LaunchOverlay extends StatefulWidget {
  /// The app content (the navigator), always built underneath.
  final Widget child;

  /// Completes when the first screen has its data (or loading gave up).
  final Future<void> ready;

  const LaunchOverlay({super.key, required this.child, required this.ready});

  /// Logo size in logical pixels. Deliberately not ScreenUtil-scaled: it
  /// must match the native splash image (480px at xxxhdpi = 120dp).
  static const double logoSize = 120;

  @override
  State<LaunchOverlay> createState() => _LaunchOverlayState();
}

class _LaunchOverlayState extends State<LaunchOverlay>
    with TickerProviderStateMixin {
  static const Duration _introDuration = Duration(milliseconds: 1600);
  static const Duration _exitDuration = Duration(milliseconds: 480);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _introDuration,
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: _exitDuration,
  );

  bool _visible = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_run());
  }

  Future<void> _run() async {
    // The native splash stays on top until the logo is decoded, so the
    // hand-off never flashes an empty white screen. Independent of the
    // intro: a slow decode must not hold the app back.
    unawaited(
      precacheImage(const AssetImage(AppAssets.appLogo), context)
          .catchError((Object _) {})
          .whenComplete(FlutterNativeSplash.remove),
    );

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    await Future.wait([
      if (!reduceMotion) _intro.forward().orCancel.catchError((Object _) {}),
      widget.ready.catchError((Object _) {}),
    ]);
    if (!mounted) return;
    await _exit.forward().orCancel.catchError((Object _) {});
    if (mounted) setState(() => _visible = false);
  }

  @override
  void dispose() {
    _intro.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: Listenable.merge([_intro, _exit]),
          builder: (context, _) =>
              _LaunchScene(intro: _intro.value, exit: _exit.value),
        ),
      ],
    );
  }
}

/// One frame of the launch animation for intro progress [intro] and exit
/// progress [exit] (both 0..1).
class _LaunchScene extends StatelessWidget {
  final double intro;
  final double exit;

  const _LaunchScene({required this.intro, required this.exit});

  /// Maps [t] into the [begin]..[end] window of the timeline, curved.
  static double _phase(
    double t,
    double begin,
    double end, [
    Curve curve = Curves.linear,
  ]) {
    final v = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(v);
  }

  double get _logoScale {
    // Breathe in (1 → 0.93), spring back past 1 and settle, then lift on exit.
    final dip = _phase(intro, 0.0, 0.22, Curves.easeOut);
    final pop = _phase(intro, 0.22, 0.55, Curves.easeOutBack);
    final intro1 = 1 - 0.07 * dip + 0.07 * pop;
    return intro1 + 0.10 * Curves.easeIn.transform(exit);
  }

  @override
  Widget build(BuildContext context) {
    const size = LaunchOverlay.logoSize;
    final fade = 1 - Curves.easeOut.transform(exit);
    final words = _phase(intro, 0.48, 0.80, Curves.easeOutCubic);
    final tagline = _phase(intro, 0.60, 0.92, Curves.easeOutCubic);

    // White screen: dark status-bar icons whatever the app theme is, and no
    // taps reach the app until it has been revealed.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppColors.transparent,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: AbsorbPointer(
        child: Opacity(
          opacity: fade,
          child: ColoredBox(
            color: AppColors.white,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Growth ripples behind the logo.
                for (final start in const [0.24, 0.38])
                  _Ripple(progress: _phase(intro, start, start + 0.50)),
                Transform.scale(
                  scale: _logoScale,
                  child: _ShiningLogo(
                    size: size,
                    shine: _phase(intro, 0.42, 0.86, Curves.easeInOutCubic),
                  ),
                ),
                // Wordmark sits below the (exactly centred) logo.
                Transform.translate(
                  offset: Offset(0, size / 2 + 52 - 10 * (1 - words)),
                  child: Opacity(
                    opacity: words,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Track Free',
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.brandTealDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Opacity(
                          opacity: tagline,
                          child: Text(
                            'Small habits. Steady growth.',
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.brandTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
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

/// A soft ring expanding from the logo and fading out.
class _Ripple extends StatelessWidget {
  final double progress;

  const _Ripple({required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    final eased = Curves.easeOutCubic.transform(progress);
    final diameter = LaunchOverlay.logoSize * (1.0 + 1.1 * eased);
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.brandGreen.withValues(alpha: 0.45 * (1 - eased)),
            width: 2.5,
          ),
        ),
      ),
    );
  }
}

/// The logo with a diagonal light sweep at [shine] (0..1).
class _ShiningLogo extends StatelessWidget {
  final double size;
  final double shine;

  const _ShiningLogo({required this.size, required this.shine});

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      AppAssets.appLogo,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Track Free',
    );
    if (shine <= 0 || shine >= 1) return logo;

    // A narrow bright band travelling from top-left to bottom-right.
    final center = -0.4 + 1.8 * shine;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        transform: const GradientRotation(math.pi / 36),
        colors: [
          AppColors.white.withValues(alpha: 0),
          AppColors.white.withValues(alpha: 0.38),
          AppColors.white.withValues(alpha: 0),
        ],
        stops: [
          (center - 0.14).clamp(0.0, 1.0),
          center.clamp(0.0, 1.0),
          (center + 0.14).clamp(0.0, 1.0),
        ],
      ).createShader(rect),
      child: logo,
    );
  }
}
