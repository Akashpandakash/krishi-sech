import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppPressableHaptic { selection, light, medium, heavy, none }

class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.haptic = AppPressableHaptic.light,
    this.scale = 0.97,
    this.semanticLabel,
  }) : assert(scale > 0 && scale <= 1);

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final AppPressableHaptic haptic;
  final double scale;
  final String? semanticLabel;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _pointer;
  Offset? _pointerOrigin;
  bool _pointerCancelled = false;

  bool get _ownsGesture => widget.onTap != null || widget.onLongPress != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 105),
      reverseDuration: const Duration(milliseconds: 125),
    );
  }

  @override
  void didUpdateWidget(AppPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) _release();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    if (!widget.enabled) return;
    if (_reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  void _release() {
    if (_reduceMotion) {
      _controller.value = 0;
    } else {
      _controller.reverse();
    }
  }

  bool get _reduceMotion {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations == true ||
        media?.accessibleNavigation == true;
  }

  Future<void> _haptic() => switch (widget.haptic) {
    AppPressableHaptic.selection => HapticFeedback.selectionClick(),
    AppPressableHaptic.light => HapticFeedback.lightImpact(),
    AppPressableHaptic.medium => HapticFeedback.mediumImpact(),
    AppPressableHaptic.heavy => HapticFeedback.heavyImpact(),
    AppPressableHaptic.none => Future<void>.value(),
  };

  void _handleTap() {
    if (!widget.enabled) return;
    _haptic();
    widget.onTap?.call();
  }

  void _handleLongPress() {
    if (!widget.enabled) return;
    _haptic();
    widget.onLongPress?.call();
  }

  void _pointerDown(PointerDownEvent event) {
    if (!widget.enabled || _pointer != null) return;
    _pointer = event.pointer;
    _pointerOrigin = event.position;
    _pointerCancelled = false;
    _press();
  }

  void _pointerMove(PointerMoveEvent event) {
    if (_pointer != event.pointer || _pointerOrigin == null) return;
    if ((event.position - _pointerOrigin!).distance > kTouchSlop) {
      _pointerCancelled = true;
      _release();
    }
  }

  void _pointerUp(PointerUpEvent event) {
    if (_pointer != event.pointer) return;
    final shouldHaptic = !_pointerCancelled;
    _resetPointer();
    if (shouldHaptic) _haptic();
  }

  void _pointerCancel(PointerCancelEvent event) {
    if (_pointer != event.pointer) return;
    _resetPointer();
  }

  void _resetPointer() {
    _pointer = null;
    _pointerOrigin = null;
    _pointerCancelled = false;
    _release();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final curved = Curves.easeOutCubic.transform(_controller.value);
        final scale = 1 - ((1 - widget.scale) * curved);
        final opacity = 1 - (0.08 * curved);
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: child),
        );
      },
    );

    if (!widget.enabled) return result;

    if (_ownsGesture) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        onTap: _handleTap,
        onLongPressStart: (_) => _press(),
        onLongPressEnd: (_) => _release(),
        onLongPress: widget.onLongPress == null ? null : _handleLongPress,
        child: result,
      );
    } else {
      result = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _pointerDown,
        onPointerMove: _pointerMove,
        onPointerUp: _pointerUp,
        onPointerCancel: _pointerCancel,
        child: result,
      );
    }

    return widget.semanticLabel == null
        ? result
        : Semantics(label: widget.semanticLabel, child: result);
  }
}
