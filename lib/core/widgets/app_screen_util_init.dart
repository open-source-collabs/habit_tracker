import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_dimensions.dart';

/// App-wide [ScreenUtilInit] applying the central [AppDesign] scaling policy.
///
/// Use this instead of a raw [ScreenUtilInit] (including in tests) so every
/// `.w` / `.h` / `.r` / `.sp` value is bounded consistently.
class AppScreenUtilInit extends StatelessWidget {
  const AppScreenUtilInit({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppDesign.designSizeFor(MediaQuery.sizeOf(context)),
      builder: (context, _) => builder(context),
    );
  }
}
