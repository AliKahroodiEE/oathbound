import 'package:flutter/widgets.dart';

/// Returns [d], or zero when the platform or the user asked for reduced
/// motion (design-system §5).
Duration motion(BuildContext context, Duration d) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;
