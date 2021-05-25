import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'entity/candle_type_enum.dart';
import 'entity/info_window_entity.dart';
import 'entity/k_line_entity.dart';
import 'renderer/chart_painter.dart';
import 'utils/date_format_util.dart' hide S;
import 'utils/number_util.dart';

class KChartWidget extends StatefulWidget {
  KChartWidget(
    this.datas, {
    required this.candleType,
    int fractionDigits = 2,
    required this.getData,
    required this.authToken,
    required this.instrumentId,
    required this.timeFrame,
    required this.candleResolution,
  }) {
    NumberUtil.fractionDigits = fractionDigits;
  }

  final List<KLineEntity> datas;
  final CandleTypeEnum candleType;

  final Function(String, String, String) getData;

  final String authToken;
  final String instrumentId;
  final DateTimeRange timeFrame;
  final String candleResolution;

  @override
  _KChartWidgetState createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  double _scaleX = 1.0, _scrollX = 0.0, _selectX = 0.0, _lastScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  late StreamController<InfoWindowEntity?> _infoWindowStream;
  late AnimationController _scrollXController;

  @override
  void initState() {
    super.initState();
    _infoWindowStream = StreamController<InfoWindowEntity>();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 850), vsync: this);
    _animation = Tween(begin: 0.9, end: 0.1).animate(_controller)
      ..addListener(reRenderView);
    _scrollXController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
        lowerBound: double.negativeInfinity,
        upperBound: double.infinity);
    _scrollListener();
  }

  void _scrollListener() {
    _scrollXController.addListener(() {
      _scrollX = _scrollXController.value;
      if (_scrollX <= 0) {
        _scrollX = 0;
        _stopAnimation();
      } else if (_scrollX >= ChartPainter.maxScrollX) {
        _scrollX = ChartPainter.maxScrollX;
        widget.getData(
            widget.authToken, widget.candleResolution, widget.instrumentId);
        _stopAnimation();
      } else {
        reRenderView();
      }
    });
    _scrollXController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        isDrag = false;
        reRenderView();
      }
    });
  }

  @override
  void didUpdateWidget(KChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.datas != widget.datas) {
      //  mScrollX = mSelectX = 0.0;
      _selectX = 0.0;
    }
  }

  @override
  void dispose() {
    _infoWindowStream.close();
    _controller.dispose();
    _scrollXController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datas.isEmpty) {
      _scrollX = _selectX = 0.0;
      _scaleX = 1.0;
    }
    return GestureDetector(
      onHorizontalDragDown: (details) {
        _stopAnimation();
        isDrag = true;
      },
      onHorizontalDragUpdate: (details) {
        if (isScale || isLongPress) return;
        if (details.primaryDelta != null) {
          _scrollX = (details.primaryDelta! / _scaleX + _scrollX)
              .clamp(0.0, ChartPainter.maxScrollX)
              .toDouble();
        }
        reRenderView();
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        // isDrag = false;
        // logical pixels per second
        if (WidgetsBinding.instance != null) {
          final tolerance = Tolerance(
            velocity: 1.0 /
                (0.050 * WidgetsBinding.instance!.window.devicePixelRatio),
            distance: 1.0 /
                WidgetsBinding
                    .instance!.window.devicePixelRatio, // logical pixels
          );

          if (details.primaryVelocity != null) {
            final simulation = ClampingScrollSimulation(
              position: _scrollX,
              velocity: details.primaryVelocity!,
              tolerance: tolerance,
            );
            _scrollXController.animateWith(simulation);
          }
        }
      },
      onHorizontalDragCancel: () => isDrag = false,
      onScaleStart: (_) {
        isScale = true;
      },
      onScaleUpdate: (details) {
        if (isDrag || isLongPress) return;
        _scaleX = (_lastScale * details.scale).clamp(0.5, 2.2);
        // ignore: avoid_print
        print(details);
        reRenderView();
      },
      onScaleEnd: (_) {
        isScale = false;
        _lastScale = _scaleX;
      },
      onLongPressStart: (details) {
        isLongPress = true;
        if (_selectX != details.globalPosition.dx) {
          _selectX = details.globalPosition.dx;
          reRenderView();
        }
      },
      onLongPressMoveUpdate: (details) {
        if (_selectX != details.globalPosition.dx) {
          _selectX = details.globalPosition.dx;
          reRenderView();
        }
      },
      onLongPressEnd: (details) {
        isLongPress = false;
        _infoWindowStream.sink.add(null);
        reRenderView();
      },
      child: Stack(
        children: <Widget>[
          CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: ChartPainter(
                datas: widget.datas,
                scaleX: _scaleX,
                scrollX: _scrollX,
                selectX: _selectX,
                isLongPass: isLongPress,
                candleType: widget.candleType,
                sink: _infoWindowStream.sink,
                opacity: _animation.value,
                resolution: widget.candleResolution,
                controller: _controller),
          ),
        ],
      ),
    );
  }

  void _stopAnimation() {
    if (_scrollXController.isAnimating) {
      _scrollXController.stop();
      isDrag = false;
      reRenderView();
    }
  }

  void reRenderView() => setState(() {});

  String getDate(int date) {
    return dateFormat(
        DateTime.fromMillisecondsSinceEpoch(date * 1000, isUtc: true),
        [yy, '-', mm, '-', dd, ' ', HH, ':', nn]);
  }
}
