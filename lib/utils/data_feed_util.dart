import 'package:charts/entity/custom_resolution_enum.dart';
import 'package:charts/entity/resolution_string_entity.dart';
import 'package:charts/entity/resolution_string_enum.dart';

class DataFeedUtil {
  static ResolutionForServerEnum parseCandleType(String resolution) {
    switch (resolution) {
      case ResolutionString.minute:
        return ResolutionForServerEnum.minute;
      case ResolutionString.hour:
        return ResolutionForServerEnum.hour;
      case ResolutionString.day:
        return ResolutionForServerEnum.day;
      case ResolutionString.month:
        return ResolutionForServerEnum.month;
      default:
        return ResolutionForServerEnum.day;
    }
  }

  static ResolutionBackValues calculateHistoryDepth(String resolution) {
    switch (resolution) {
      case ResolutionString.minute:
        return ResolutionBackValues(
            ResolutionString.minute, Duration(hours: 2));

      case ResolutionString.hour:
        return ResolutionBackValues(ResolutionString.hour, Duration(days: 2));

      case ResolutionString.day:
        return ResolutionBackValues(ResolutionString.day, Duration(days: 60));

      case ResolutionString.month:
        return ResolutionBackValues(
            ResolutionString.month, Duration(days: 365 * 5));

      default:
        return ResolutionBackValues(resolution, Duration(hours: 2));
    }
  }
}
