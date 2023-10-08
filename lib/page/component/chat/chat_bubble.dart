import 'package:flutter/material.dart';

/// Source from https://github.com/prahack/chat_bubbles/blob/master/lib/bubbles/bubble_special_one.dart
class SpecialChatBubbleOne extends CustomPainter {
  final Color color;
  final Alignment alignment;
  final bool tail;

  SpecialChatBubbleOne({
    required this.color,
    required this.alignment,
    required this.tail,
  });

  final double _radius = 10.0;
  final double _x = 5.0;

  // ... rest of the code remains the same ...
}
