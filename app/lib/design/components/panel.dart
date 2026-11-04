import 'package:flutter/material.dart';

import '../tokens.dart';

/// Stone panel: slate fill, hairline border, optional overline header
/// whose rule runs to the end edge (design-system §6).
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsetsDirectional.all(AppSpace.lg),
    this.onTap,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            SectionHeader(title!, trailing: trailing),
            const SizedBox(height: AppSpace.md),
          ],
          child,
        ],
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Semantics(
      header: true,
      child: Row(
        children: [
          // Long translations or 200 % text scale ellipsize rather than overflow.
          Flexible(
            flex: 3,
            child: Text(
              Directionality.of(context) == TextDirection.ltr ? text.toUpperCase() : text,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          const Expanded(child: Divider()),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.sm),
            Flexible(flex: 3, child: trailing!),
          ],
        ],
      ),
    );
  }
}
