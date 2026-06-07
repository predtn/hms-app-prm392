import 'package:flutter/material.dart';
import 'package:hms_app/widgets/app_drawer.dart';
import 'package:hms_app/widgets/color_settings.dart';
import 'package:provider/provider.dart';
import 'package:hms_app/providers/theme_provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    String currentThemeString;
    if (themeProvider.isLight) {
      currentThemeString = 'light';
    } else if (themeProvider.isDark) {
      currentThemeString = 'dark';
    } else {
      currentThemeString = 'system';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      drawer: const AppDrawer(),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 8.0,
            ),
            child: Text(
              'Cài đặt khách sạn',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: Text(
              'Danh mục',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.meeting_room, color: Colors.blue),
            trailing: const Icon(Icons.chevron_right),
            title: const Text('Loại phòng'),
            subtitle: const Text('Thiết lập danh mục loại phòng'),
            onTap: () {
              Navigator.pushNamed(context, '/room-type-list');
            },
          ),
          ListTile(
            leading: const Icon(Icons.door_front_door, color: Colors.green),
            trailing: const Icon(Icons.chevron_right),
            title: const Text('Phòng'),
            subtitle: const Text('Quản lý thông tin các phòng'),
            onTap: () {
              Navigator.pushNamed(context, '/room-list');
            },
          ),
          ListTile(
            leading: const Icon(Icons.room_service, color: Colors.orange),
            trailing: const Icon(Icons.chevron_right),
            title: const Text('Dịch vụ'),
            subtitle: const Text('Các dịch vụ cung cấp cho khách'),
            onTap: () {
              Navigator.pushNamed(context, '/service-list');
            },
          ),
          ListTile(
            leading: const Icon(Icons.money, color: Colors.orange),
            trailing: const Icon(Icons.chevron_right),
            title: const Text('Phí phạt'),
            subtitle: const Text('Các phí phạt quá giờ'),
            onTap: () {
              Navigator.pushNamed(context, '/penalty-fee-config');
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Cài đặt hệ thống',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: Text(
              'Giao diện',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          RadioGroup<String>(
            groupValue: currentThemeString,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeFromString(value);
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Sáng'),
                  value: 'light',
                ),
                RadioListTile<String>(title: const Text('Tối'), value: 'dark'),
                RadioListTile<String>(
                  title: const Text('Hệ thống'),
                  value: 'system',
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 8.0,
            ),
            child: Text(
              'Màu chủ đạo',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: ColorSettings(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
