import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hms_app/providers/pricing_config_provider.dart';

class PenaltyFeeConfig extends StatefulWidget {
  const PenaltyFeeConfig({super.key});

  @override
  State<PenaltyFeeConfig> createState() => _PenaltyFeeConfigState();
}

class _PenaltyFeeConfigState extends State<PenaltyFeeConfig> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _graceMinutesController;
  late TextEditingController _under6hController;
  late TextEditingController _under12hController;
  late TextEditingController _over12hController;

  @override
  void initState() {
    super.initState();
    final config = context.read<PricingConfigProvider>().config;
    _graceMinutesController = TextEditingController(
      text: config.graceMinutes.toString(),
    );
    _under6hController = TextEditingController(
      text: config.penaltyUnder6Hours.toString(),
    );
    _under12hController = TextEditingController(
      text: config.penaltyUnder12Hours.toString(),
    );
    _over12hController = TextEditingController(
      text: config.penaltyOver12Hours.toString(),
    );
  }

  @override
  void dispose() {
    _graceMinutesController.dispose();
    _under6hController.dispose();
    _under12hController.dispose();
    _over12hController.dispose();
    super.dispose();
  }

  void _saveConfig() {
    if (_formKey.currentState!.validate()) {
      context.read<PricingConfigProvider>().updateConfig(
        graceMinutes: int.parse(_graceMinutesController.text),
        penaltyUnder6Hours: double.parse(_under6hController.text),
        penaltyUnder12Hours: double.parse(_under12hController.text),
        penaltyOver12Hours: double.parse(_over12hController.text),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu cấu hình phí phạt')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phí phạt quá giờ'),
        actions: [
          IconButton(
            onPressed: _saveConfig,
            icon: const Icon(Icons.save),
            tooltip: 'Lưu',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _graceMinutesController,
              decoration: const InputDecoration(
                labelText: 'Số phút ân hạn',
                suffixText: 'phút',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập';
                if (int.tryParse(value) == null) return 'Phải là số nguyên';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _under6hController,
              decoration: const InputDecoration(
                labelText: 'Phí phạt dưới 6 giờ',
                helperText: 'Ví dụ: 0.25 tương đương 25% giá phòng',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập';
                if (double.tryParse(value) == null) return 'Phải là số';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _under12hController,
              decoration: const InputDecoration(
                labelText: 'Phí phạt từ 6 đến 12 giờ',
                helperText: 'Ví dụ: 0.50 tương đương 50% giá phòng',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập';
                if (double.tryParse(value) == null) return 'Phải là số';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _over12hController,
              decoration: const InputDecoration(
                labelText: 'Phí phạt trên 12 giờ',
                helperText: 'Ví dụ: 1.0 tương đương 100% giá phòng',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập';
                if (double.tryParse(value) == null) return 'Phải là số';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              label: const Text('Lưu cấu hình'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
