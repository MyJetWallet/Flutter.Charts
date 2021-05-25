import '../entity/k_line_entity.dart';

class InfoWindowEntity {
  InfoWindowEntity(this.kLineEntity, {required this.isLeft});

  KLineEntity kLineEntity;
  bool isLeft = false;
}
