import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Drop-in replacement for `ListView.builder` that fades + slides each item
/// in with a staggered delay, so list screens feel considered on first
/// load instead of popping in all at once.
class StaggeredListView extends StatelessWidget {
  const StaggeredListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: padding,
        itemCount: itemCount,
        itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 24,
            child: FadeInAnimation(child: itemBuilder(context, index)),
          ),
        ),
      ),
    );
  }
}
