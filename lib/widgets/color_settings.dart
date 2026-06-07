import 'package:hms_app/providers/color_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ColorSettings extends StatelessWidget {
  final List<Color> colors = const [
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  const ColorSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final currentColor = context.watch<ColorProvider>().primaryColor;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected = currentColor == color;

        return GestureDetector(
          onTap: () => context.read<ColorProvider>().setColor(color),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
