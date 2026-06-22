import 'package:flutter/material.dart';

class ServiceCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String unit;
  final int initialQuantity;
  final ValueChanged<int>? onChanged;

  const ServiceCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.unit,
    this.initialQuantity = 0,
    this.onChanged,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = widget.initialQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withAlpha(120), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.subtitle,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton.outlined(
              onPressed: _qty > 0
                  ? () {
                      setState(() => _qty--);
                      widget.onChanged?.call(_qty);
                    }
                  : null,
              icon: const Icon(Icons.remove, size: 16),
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    '$_qty',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.unit,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton.outlined(
              onPressed: () {
                setState(() => _qty++);
                widget.onChanged?.call(_qty);
              },
              icon: const Icon(Icons.add, size: 16),
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
