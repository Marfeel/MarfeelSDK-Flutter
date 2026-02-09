import 'package:flutter/material.dart';

import 'compass_tracking.dart';

class CompassScrollView extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final Axis scrollDirection;

  const CompassScrollView({
    super.key,
    required this.child,
    this.controller,
    this.padding,
    this.physics,
    this.scrollDirection = Axis.vertical,
  });

  @override
  State<CompassScrollView> createState() => _CompassScrollViewState();
}

class _CompassScrollViewState extends State<CompassScrollView> {
  late ScrollController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = ScrollController();
      _ownsController = true;
    }
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(CompassScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onScroll);
      if (_ownsController) {
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _ownsController = false;
      } else {
        _controller = ScrollController();
        _ownsController = true;
      }
      _controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final maxExtent = _controller.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final percentage =
        (_controller.offset / maxExtent * 100).round().clamp(0, 100);
    CompassTracking.updateScrollPercentage(percentage);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      padding: widget.padding,
      physics: widget.physics,
      scrollDirection: widget.scrollDirection,
      child: widget.child,
    );
  }
}
