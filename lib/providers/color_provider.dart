import 'package:flutter/material.dart';

class ColorProvider extends ChangeNotifier {
  Color _primaryColor = Colors.blue;

  Color get primaryColor => _primaryColor;

  void setColor(Color color) {
    if (_primaryColor == color) return;
    _primaryColor = color;
    notifyListeners();
  }
}
