import 'package:flutter/material.dart';

class DateTimePicker extends StatelessWidget {
  const DateTimePicker({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDisabled
                    ? colorScheme.onSurface.withValues(alpha: 0.3)
                    : colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: isDisabled
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: isDisabled
                    ? colorScheme.onSurface.withValues(alpha: 0.3)
                    : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
