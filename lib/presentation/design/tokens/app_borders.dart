import 'package:flutter/widgets.dart';
import 'app_colors.dart';

abstract final class AppBorders {
  /// 1dp · borderSubtle — dividers, hairlines.
  static const BorderSide hair = BorderSide(
    color: AppColors.borderSubtle,
    width: 1,
  );

  /// 1dp · borderDefault — cards, inputs au repos.
  static const BorderSide standard = BorderSide(
    color: AppColors.borderDefault,
    width: 1,
  );

  /// 1dp · accentPrimary — input/card focusé. Width inchangée.
  static const BorderSide focus = BorderSide(
    color: AppColors.accentPrimary,
    width: 1,
  );

  /// 1dp · stateError — input en erreur.
  static const BorderSide error = BorderSide(
    color: AppColors.stateError,
    width: 1,
  );

  /// 3dp left only — marker `AppTile.isActive`.
  static const BorderSide activeMarker = BorderSide(
    color: AppColors.accentPrimary,
    width: 3,
  );
}
