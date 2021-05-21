import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:my_app/entity/candle_type_enum.dart';
import 'entity/info_window_entity.dart';
import 'entity/k_line_entity.dart';
import 'http/http_service.dart';
import 'renderer/chart_painter.dart';
import 'utils/date_format_util.dart' hide S;
import 'utils/number_util.dart';

class KChartWidget extends StatefulWidget {
  final List<KLineEntity> datas;
  final CandleTypeEnum candleType;

  final Function(String, String, String) getData;

  final String authToken;
  final String instrumentId;
  final DateTimeRange timeFrame;
  final String candleResolution;

  KChartWidget(this.datas,
      {this.candleType,
      int fractionDigits = 2,
      this.getData,
      this.authToken,
      this.instrumentId,
      this.timeFrame,
      this.candleResolution}) {
    NumberUtil.fractionDigits = fractionDigits;
  }

  @override
  _KChartWidgetState createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;
  double mScaleX = 1.0, mScrollX = 0.0, mSelectX = 0.0;
  StreamController<InfoWindowEntity> mInfoWindowStream;
  double mWidth = 0;
  AnimationController _scrollXController;
  final HttpService httpService = HttpService();

  double getMinScrollX() {
    return mScaleX;
  }

  double _lastScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false;

  @override
  void initState() {
    super.initState();
    mInfoWindowStream = StreamController<InfoWindowEntity>();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 850), vsync: this);
    _animation = Tween(begin: 0.9, end: 0.1).animate(_controller)
      ..addListener(rerenderView);
    _scrollXController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
        lowerBound: double.negativeInfinity,
        upperBound: double.infinity);
    _scrollListener();
  }

  void _scrollListener() {
    _scrollXController.addListener(() {
      mScrollX = _scrollXController.value;
      if (mScrollX <= 0) {
        mScrollX = 0;
        _stopAnimation();
      } else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        widget.getData(
            widget.authToken, widget.candleResolution, widget.instrumentId);
        _stopAnimation();
      } else {
        rerenderView();
      }
    });
    _scrollXController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        isDrag = false;
        rerenderView();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    mWidth = MediaQuery.of(context).size.width;
  }

  @override
  void didUpdateWidget(KChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.datas != widget.datas) {
      //  mScrollX = mSelectX = 0.0;
      mSelectX = 0.0;
    }
  }

  @override
  void dispose() {
    mInfoWindowStream?.close();
    _controller?.dispose();
    _scrollXController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datas == null || widget.datas.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 1.0;
    }
    return GestureDetector(
      onHorizontalDragDown: (details) {
        _stopAnimation();
        isDrag = true;
      },
      onHorizontalDragUpdate: (details) {
        if (isScale || isLongPress) return;
        mScrollX = (details.primaryDelta / mScaleX + mScrollX)
            .clamp(0.0, ChartPainter.maxScrollX);
        rerenderView();
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        // isDrag = false;
        final Tolerance tolerance = Tolerance(
          velocity: 1.0 /
              (0.050 *
                  WidgetsBinding.instance.window
                      .devicePixelRatio), // logical pixels per second
          distance: 1.0 /
              WidgetsBinding.instance.window.devicePixelRatio, // logical pixels
        );

        ClampingScrollSimulation simulation = ClampingScrollSimulation(
          position: mScrollX,
          velocity: details.primaryVelocity,
          tolerance: tolerance,
        );
        _scrollXController.animateWith(simulation);
      },
      onHorizontalDragCancel: () => isDrag = false,
      onScaleStart: (_) {
        isScale = true;
      },
      onScaleUpdate: (details) {
        if (isDrag || isLongPress) return;
        mScaleX = (_lastScale * details.scale).clamp(0.5, 2.2);
        print(details);
        rerenderView();
      },
      onScaleEnd: (_) {
        isScale = false;
        _lastScale = mScaleX;
      },
      onLongPressStart: (details) {
        isLongPress = true;
        if (mSelectX != details.globalPosition.dx) {
          mSelectX = details.globalPosition.dx;
          rerenderView();
        }
      },
      onLongPressMoveUpdate: (details) {
        if (mSelectX != details.globalPosition.dx) {
          mSelectX = details.globalPosition.dx;
          rerenderView();
        }
      },
      onLongPressEnd: (details) {
        isLongPress = false;
        mInfoWindowStream?.sink?.add(null);
        rerenderView();
      },
      child: Stack(
        children: <Widget>[
          CustomPaint(
            size: Size(double.infinity, double.infinity),
            painter: ChartPainter(
                datas: widget.datas,
                scaleX: mScaleX,
                scrollX: mScrollX,
                selectX: mSelectX,
                isLongPass: isLongPress,
                candleType: widget.candleType,
                sink: mInfoWindowStream?.sink,
                opacity: _animation.value,
                resolution: widget.candleResolution,
                controller: _controller),
          ),
        ],
      ),
    );
  }

  void _stopAnimation() {
    if (_scrollXController != null && _scrollXController.isAnimating) {
      _scrollXController.stop();
      isDrag = false;
      rerenderView();
    }
  }

  void rerenderView() => setState(() {});

  String getDate(int date) {
    return dateFormat(
        DateTime.fromMillisecondsSinceEpoch(date * 1000, isUtc: true),
        [yy, '-', mm, '-', dd, ' ', HH, ':', nn]);
  }
}
