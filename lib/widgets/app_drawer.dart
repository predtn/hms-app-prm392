import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hms_app/providers/user_provider.dart';

class AppDrawerDestination {
  const AppDrawerDestination(
    this.label,
    this.icon,
    this.selectedIcon,
    this.route,
  );
  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final String route;
}

const List<AppDrawerDestination> drawerDestinations = [
  AppDrawerDestination(
    'Sơ đồ phòng',
    Icon(Icons.map_outlined),
    Icon(Icons.map),
    '/room-map',
  ),
  AppDrawerDestination(
    'Tìm phòng phù hợp',
    Icon(Icons.search),
    Icon(Icons.search),
    '/find-room',
  ),
  AppDrawerDestination(
    'Tìm thông tin khách hàng',
    Icon(Icons.person_search_outlined),
    Icon(Icons.person_search),
    '/find-customer',
  ),
  AppDrawerDestination(
    'Cài đặt',
    Icon(Icons.settings_outlined),
    Icon(Icons.settings),
    '/settings',
  ),
  AppDrawerDestination(
    'Thông tin cá nhân',
    Icon(Icons.person_outline),
    Icon(Icons.person),
    '/profile',
  ),
];

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  int _getCurrentIndex(BuildContext context) {
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final index = drawerDestinations.indexWhere((d) => d.route == currentRoute);
    return index == -1 ? 0 : index;
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.of(context).pop(); // close drawer first
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Provider.of<UserProvider>(context, listen: false).clearUser();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _handleDestinationSelected(BuildContext context, int index) {
    // logout tap
    if (index == drawerDestinations.length) {
      _handleLogout(context);
      return;
    }

    final selectedRoute = drawerDestinations[index].route;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    Navigator.of(context).pop(); // close drawer

    if (selectedRoute != currentRoute) {
      Navigator.of(context).pushReplacementNamed(selectedRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _getCurrentIndex(context);
    final userProvider = Provider.of<UserProvider>(context);
    final profile = userProvider.userProfile;
    final fullName = profile?.fullName ?? 'User';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
    final avatarUrl = profile?.avatarUrl;

    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) =>
          _handleDestinationSelected(context, index),
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 16, 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          initial,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.fromLTRB(28, 16, 16, 10)),
        ...drawerDestinations.map(
          (dest) => NavigationDrawerDestination(
            label: Text(dest.label),
            icon: dest.icon,
            selectedIcon: dest.selectedIcon,
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
        const NavigationDrawerDestination(
          label: Text('Đăng xuất'),
          icon: Icon(Icons.logout),
          selectedIcon: Icon(Icons.logout),
        ),
      ],
    );
  }
}
