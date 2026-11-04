import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/widgets.dart';

import '../tokens.dart';

/// Returns [d], or zero when the platform or the user asked for reduced
/// motion (design-system §5).
Duration motion(BuildContext context, Duration d) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;

/// Marks where a cascade of [Reveal]s starts. Reveals built more than a
/// moment after their scope appeared (for example list items scrolled into
/// view later) show at once instead of animating.
class RevealScope extends StatefulWidget {
  const RevealScope({super.key, required this.child});

  final Widget child;

  @override
  State<RevealScope> createState() => _RevealScopeState();
}

class _RevealScopeState extends State<RevealScope> {
  final _start = DateTime.now();

  @override
  Widget build(BuildContext context) => _RevealScopeData(start: _start, child: widget.child);
}

class _RevealScopeData extends InheritedWidget {
  const _RevealScopeData({required this.start, required super.child});

  final DateTime start;

  @override
  bool updateShouldNotify(_RevealScopeData old) => old.start != start;
}

/// Fades and lifts its child into place once, when first shown. [index]
/// staggers siblings; it is capped so long lists never make anyone wait.
/// Opacity and translation only, so it stays cheap on every renderer.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0, this.offset = 14});

  final Widget child;
  final int index;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  static const _step = Duration(milliseconds: 55);
  static const _length = Duration(milliseconds: 460);

  AnimationController? _controller;
  late Animation<double> _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final scope = context.getInheritedWidgetOfExactType<_RevealScopeData>();
    final late = scope != null && DateTime.now().difference(scope.start) > const Duration(milliseconds: 700);
    final reduced = late || motion(context, _length) == Duration.zero;
    final delay = _step * widget.index.clamp(0, 8);
    final total = delay + _length;
    final controller = AnimationController(vsync: this, duration: total, value: reduced ? 1 : 0);
    _controller = controller;
    _t = CurvedAnimation(
      parent: controller,
      curve: Interval(delay.inMicroseconds / total.inMicroseconds, 1, curve: AppMotion.emphasizedDecelerate),
    );
    if (!reduced) controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _t,
    child: AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) =>
          _t.value >= 1 ? child! : Transform.translate(offset: Offset(0, (1 - _t.value) * widget.offset), child: child),
    ),
  );
}

/// Shrinks its child a touch while pressed, for tactile feedback. Uses a
/// raw pointer listener, so it never competes with the child's gestures,
/// and lets go as soon as the pointer starts scrolling.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.975, this.enabled = true});

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  Offset? _origin;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (e) {
        _origin = e.position;
        _set(true);
      },
      onPointerMove: (e) {
        if (_down && _origin != null && (e.position - _origin!).distance > kTouchSlop) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: motion(context, AppMotion.quick),
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}

/// Keeps every child alive, like [IndexedStack], and fades the selected one
/// in when the selection changes. Used for the main navigation branches.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 240);
  late final AnimationController _controller = AnimationController(vsync: this, duration: _duration, value: 1);
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: AppMotion.standard);

  @override
  void didUpdateWidget(FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    if (motion(context, _duration) == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0.15);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: widget.index,
    sizing: StackFit.expand,
    children: [
      for (var i = 0; i < widget.children.length; i++)
        TickerMode(
          enabled: i == widget.index,
          // Same widget types at every position, so branch state survives.
          child: FadeTransition(
            opacity: i == widget.index ? _fade : kAlwaysCompleteAnimation,
            child: widget.children[i],
          ),
        ),
    ],
  );
}
