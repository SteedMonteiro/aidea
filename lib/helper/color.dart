import 'package:flutter/material.dart';

/// Convert color to string
String colorToString(Color color) {
  return color.toString().split('(0x')[1].split(')')[0];
}

/// Convert string to color
Color stringToColor(String colorString) {
  return Color(int.parse(colorString, radix: 16));
}