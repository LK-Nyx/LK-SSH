import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const Radius sharp = Radius.zero;
  static const Radius sm = Radius.circular(4);
  static const Radius md = Radius.circular(8);
  static const Radius lg = Radius.circular(12);
  static const Radius sheet = Radius.circular(16);

  static const BorderRadius all0 = BorderRadius.zero;
  static const BorderRadius all4 = BorderRadius.all(sm);
  static const BorderRadius all8 = BorderRadius.all(md);
  static const BorderRadius all12 = BorderRadius.all(lg);
  static const BorderRadius topSheet = BorderRadius.vertical(top: sheet);
}
