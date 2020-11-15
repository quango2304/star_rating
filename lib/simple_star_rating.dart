library simple_star_rating;


import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import './clip_half.dart';

typedef void RatingChangeCallback(double rating);

class SimpleStarRating extends StatefulWidget {
  final int starCount;
  final double rating;
  final RatingChangeCallback onRated;
  final double size;
  final bool allowHalfRating;
  final Widget halfFilledIcon;
  final Widget filledIcon;
  final Widget nonFilledIcon;//this is needed only when having fullRatedIconData && halfRatedIconData
  final double spacing;
  final bool isReadOnly;
  SimpleStarRating({
    this.starCount = 5,
    this.isReadOnly = false,
    this.spacing = 0.0,
    this.rating = 0.0,
    this.onRated,
    this.size = 25,
    this.allowHalfRating = true,
    this.halfFilledIcon,
    this.filledIcon,
    this.nonFilledIcon,
  }) {
    assert(this.rating != null);
  }
  @override
  _SimpleStarRatingState createState() => _SimpleStarRatingState();
}

class _SimpleStarRatingState extends State<SimpleStarRating> {
  final double halfStarThreshold =
  0.53; //half star value starts from this number

  //tracks for user tapping on this widget
  bool isWidgetTapped = false;
  double currentRating;
  Timer debounceTimer;
  @override
  void initState() {
    currentRating = widget.rating;
    super.initState();
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    debounceTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Wrap(
          alignment: WrapAlignment.start,
          spacing: widget.spacing,
          children: List.generate(
              widget.starCount, (index) => buildStar(context, index))),
    );
  }

  Widget buildStar(BuildContext context, int index) {
    Widget icon;
    if (index >= currentRating) {
      icon = widget.nonFilledIcon ?? _buildDefaultIcon(Color(0xffB0B0B0));
    } else if (index >
        currentRating -
            (widget.allowHalfRating ? halfStarThreshold : 1.0) &&
        index < currentRating) {
      icon = Stack(
        children: [
          widget.nonFilledIcon ?? _buildDefaultIcon(Color(0xffB0B0B0)),
          ClipPath(child: widget.filledIcon ?? _buildDefaultIcon(Color(0xffFFBF1C)), clipBehavior: Clip.hardEdge, clipper: HalfClipper(),),
        ],
      );
    } else {
      icon = widget.filledIcon ?? _buildDefaultIcon(Color(0xffFFBF1C));
    }
    final Widget star = widget.isReadOnly
        ? icon
        : kIsWeb
        ? MouseRegion(
      onExit: (event) {
        if (widget.onRated != null && !isWidgetTapped) {
          //reset to zero only if rating is not set by user
          setState(() {
            currentRating = 0;
          });
        }
      },
      onEnter: (event) {
        isWidgetTapped = false; //reset
      },
      onHover: (event) {
        RenderBox box = context.findRenderObject();
        var _pos = box.globalToLocal(event.position);
        final _rate = calculateRateFromOffset(_pos.dx);
        if(_rate == null) return;
        var newRating =
        widget.allowHalfRating ? _rate : _rate.ceil().toDouble();
        if(_rate < 0.2) newRating = 0;
        if (newRating > widget.starCount) {
          newRating = widget.starCount.toDouble();
        }
        if (newRating < 0) {
          newRating = 0.0;
        }
        setState(() {
          currentRating = newRating;
        });
      },
      child: GestureDetector(
        onTapDown: (detail) {
          isWidgetTapped = true;

          RenderBox box = context.findRenderObject();
          var _pos = box.globalToLocal(detail.globalPosition);
          var _rate = ((_pos.dx - index*widget.spacing) / widget.size);
          var newRating =
          widget.allowHalfRating ? _rate : _rate.ceil().toDouble();
          if(_rate < 0.2) newRating = 0;
          if (newRating > widget.starCount) {
            newRating = widget.starCount.toDouble();
          }
          if (newRating < 0) {
            newRating = 0.0;
          }
          setState(() {
            currentRating = newRating;
          });
          if (widget.onRated != null) {
            widget.onRated(normalizeRating(currentRating));
          }
        },
        onHorizontalDragUpdate: (dragDetails) {
          isWidgetTapped = true;

          RenderBox box = context.findRenderObject();
          var _pos = box.globalToLocal(dragDetails.globalPosition);
          final _rate = calculateRateFromOffset(_pos.dx);
          if(_rate == null) return;
          var newRating =
          widget.allowHalfRating ? _rate : _rate.ceil().toDouble();
          if(_rate < 0.2) newRating = 0;
          if (newRating > widget.starCount) {
            newRating = widget.starCount.toDouble();
          }
          if (newRating < 0) {
            newRating = 0.0;
          }
          setState(() {
            currentRating = newRating;
          });
          debounceTimer?.cancel();
          debounceTimer = Timer(Duration(milliseconds: 100), () {
            if (widget.onRated != null) {
              currentRating = normalizeRating(newRating);
              widget.onRated(currentRating);
            }
          });
        },
        child: icon,
      ),
    )
        : GestureDetector(
      onTapDown: (detail) {
        RenderBox box = context.findRenderObject();
        var _pos = box.globalToLocal(detail.globalPosition);
        var i = ((_pos.dx - index*widget.spacing) / widget.size);
        var newRating =
        widget.allowHalfRating ? i : i.ceil().toDouble();
        if(i<0.2) newRating = 0;
        if (newRating > widget.starCount) {
          newRating = widget.starCount.toDouble();
        }
        if (newRating < 0) {
          newRating = 0.0;
        }
        newRating = normalizeRating(newRating);
        print("newrating is $newRating");
        setState(() {
          currentRating = newRating;
        });
      },
      onTapUp: (e) {
        if (widget.onRated != null) widget.onRated(currentRating);
      },
      onHorizontalDragUpdate: (dragDetails) {
        RenderBox box = context.findRenderObject();
        var _pos = box.globalToLocal(dragDetails.globalPosition);
        final _rate = calculateRateFromOffset(_pos.dx);
        if(_rate == null) return;
        var newRating =
        widget.allowHalfRating ? _rate : _rate.ceil().toDouble();
        if(_rate<0.2) newRating = 0;
        if (newRating > widget.starCount) {
          newRating = widget.starCount.toDouble();
        }
        if (newRating < 0) {
          newRating = 0.0;
        }
        setState(() {
          currentRating = newRating;
        });
        debounceTimer?.cancel();
        debounceTimer = Timer(Duration(milliseconds: 100), () {
          if (widget.onRated != null) {
            currentRating = normalizeRating(newRating);
            widget.onRated(currentRating);
          }
        });
      },
      child: icon,
    );

    return star;
  }

  double calculateRateFromOffset(double dx) {
    int starIndex;
    for(int i=0; i< widget.starCount; i++) {
      double starBegin = i* widget.spacing + i*widget.size;
      double starEnd = i * widget.spacing + (i+1) * widget.size;
      if(dx >= starBegin && dx<= starEnd) {
        starIndex = i;
      }
    }
    if(starIndex!=null) {
      var rate = (dx  - starIndex*widget.spacing) / widget.size;
      return rate;
    }
    return null;
  }

  double normalizeRating(double newRating) {
    var k = newRating - newRating.floor();
    if (k != 0) {
      //half stars
      if (k >= halfStarThreshold) {
        newRating = newRating.floor() + 1.0;
      } else {
        newRating = newRating.floor() + 0.5;
      }
    }
    return newRating;
  }

  Widget _buildDefaultIcon(Color color) {
    return Image.asset(
      'assets/star.png',
      package: 'simple_star_rating',
      width: widget.size,
      height: widget.size,
      color: color,
    );
  }
}
