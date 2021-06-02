import '../entity/custom_resolution_enum.dart';
import '../entity/resolution_string_entity.dart';
import '../entity/resolution_string_enum.dart';

class DataFeedUtil {
  static ResolutionForServerEnum parseCandleType(String resolution) {
    switch (resolution) {
      case ResolutionString.minute:
        return ResolutionForServerEnum.minute;
      case ResolutionString.hour:
        return ResolutionForServerEnum.hour;
        // return ServerResolutionEnum.tenSec;
      case ResolutionString.day:
        return ResolutionForServerEnum.day;
        // return ServerResolutionEnum.fifteenMin;
      // case ResolutionString.week:
      //   return ServerResolutionEnum.hour;
      case ResolutionString.month:
        return ResolutionForServerEnum.month;
        // return ServerResolutionEnum.fourHour;
      case ResolutionString.threeMonth:
        return ResolutionForServerEnum.month;
        // return ServerResolutionEnum.day;
      default:
        return ResolutionForServerEnum.day;
        // return ServerResolutionEnum.week;
    }
  }

  static ResolutionBackValues calculateHistoryDepth(String resolution) {
    switch (resolution) {
      case ResolutionString.minute:
        return ResolutionBackValues(
            ResolutionString.minute, const Duration(hours: 2));

      case ResolutionString.hour:
        return ResolutionBackValues(
            ResolutionString.hour, const Duration(days: 2));

      case ResolutionString.day:
        return ResolutionBackValues(
            ResolutionString.day, const Duration(days: 60));

      case ResolutionString.month:
        return ResolutionBackValues(
            ResolutionString.month, const Duration(days: 365 * 5));

      default:
        return ResolutionBackValues(resolution, const Duration(hours: 2));
    }
  }
}
