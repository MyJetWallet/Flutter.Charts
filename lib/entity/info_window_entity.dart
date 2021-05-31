import '../entity/k_line_entity.dart';

class InfoWindowEntity {
  InfoWindowEntity(this.kLineEntity, {required this.isLeft});

  CandleModel kLineEntity;
  bool isLeft = false;
}
