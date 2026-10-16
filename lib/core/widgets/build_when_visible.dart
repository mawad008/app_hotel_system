import 'package:flutter/widgets.dart';

/// Builds [child] only once it scrolls within [margin] logical pixels of the
/// screen — until then [placeholder] stands in (sized by the parent).
///
/// For heavy content below the fold on pages that build every section up
/// front (e.g. Hotel Detail's live map, which would otherwise start
/// downloading map tiles before the guest ever scrolls to it). Once built,
/// the child stays.
class BuildWhenVisible extends StatefulWidget {
  const BuildWhenVisible({
    super.key,
    required this.child,
    this.placeholder = const SizedBox.expand(),
    this.margin = 300,
  });

  final Widget child;
  final Widget placeholder;
  final double margin;

  @override
  State<BuildWhenVisible> createState() => _BuildWhenVisibleState();
}

class _BuildWhenVisibleState extends State<BuildWhenVisible> {
  bool _visible = false;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollPosition? position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_check);
      _position = position?..addListener(_check);
    }
    // Already on screen when first laid out (or not inside a scroll view).
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_visible || !mounted) return;
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final double top = box.localToGlobal(Offset.zero).dy;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final bool near = top < screenHeight + widget.margin &&
        top + box.size.height > -widget.margin;
    if (!near) return;
    _position?.removeListener(_check);
    setState(() => _visible = true);
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _visible ? widget.child : widget.placeholder;
}
