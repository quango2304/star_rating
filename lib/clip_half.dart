import 'dart:ui';

import 'package:flutter/material.dart';

class HalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    final height = size.height;
    final width = size.width;
    path.lineTo(0, height);
    path.lineTo(width / 2, height);
    path.lineTo(width / 2, 0);
    path.lineTo(0, 0);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
