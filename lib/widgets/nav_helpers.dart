import 'package:flutter/material.dart';
import 'moviq_scaffold.dart';

int moviqTabIndex(MoviqBottomTab tab) {
  switch (tab) {
    case MoviqBottomTab.dashboard:
      return 0;
    case MoviqBottomTab.search:
      return 1;
    case MoviqBottomTab.chat:
      return 2;
    case MoviqBottomTab.favorites:
      return 3;
    case MoviqBottomTab.profile:
      return 4;
  }
}

Route<dynamic> slideRoute({
  required Widget page,
  required bool fromRight,
}) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final begin = Offset(fromRight ? 1 : -1, 0);
      final tween = Tween(begin: begin, end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

void navigateWithSlide({
  required BuildContext context,
  required MoviqBottomTab current,
  required MoviqBottomTab target,
  required Widget Function() builder,
}) {
  if (current == target) return;
  final fromRight = moviqTabIndex(target) > moviqTabIndex(current);
  Navigator.pushReplacement(
    context,
    slideRoute(page: builder(), fromRight: fromRight),
  );
}
