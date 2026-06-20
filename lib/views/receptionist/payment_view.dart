import 'package:flutter/material.dart';
import 'package:hms_app/utils/format_vnd.dart';

enum _PaymentMethod { cash, bankTransfer }

class PaymentView extends StatefulWidget {
  final int totalAmount;
  const PaymentView({super.key, required this.totalAmount});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  _PaymentMethod _selectedMethod = _PaymentMethod.cash;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Total Amount Card ──────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Tổng thanh toán',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${formatVND(widget.totalAmount)} đ',
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Payment Method Section ─────────────────────────────────────
          Text(
            'Phương thức thanh toán',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),

          RadioGroup<_PaymentMethod>(
            groupValue: _selectedMethod,
            onChanged: (v) => setState(() => _selectedMethod = v!),
            child: Column(
              children: [
                // Cash option
                _PaymentMethodCard(
                  title: 'Tiền mặt',
                  subtitle: 'Thanh toán tiền mặt',
                  icon: Icons.payments_outlined,
                  value: _PaymentMethod.cash,
                ),

                const SizedBox(height: 10),

                // Bank Transfer option
                _PaymentMethodCard(
                  title: 'Chuyển khoản',
                  subtitle: 'Chuyển khoản ngân hàng qua VietQR',
                  icon: Icons.account_balance_outlined,
                  value: _PaymentMethod.bankTransfer,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Xác nhận thanh toán'),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final _PaymentMethod value;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected =
        RadioGroup.maybeOf<_PaymentMethod>(context)?.groupValue == value;

    return Card(
      child: RadioListTile<_PaymentMethod>(
        value: value,
        secondary: Icon(
          icon,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? colorScheme.primary : null,
          ),
        ),
        subtitle: Text(subtitle),
        controlAffinity: ListTileControlAffinity.trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
