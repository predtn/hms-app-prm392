import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hms_app/providers/booking_draft_provider.dart';
import 'package:hms_app/providers/booking_provider.dart';
import 'package:hms_app/providers/color_provider.dart';
import 'package:hms_app/providers/fee_provider.dart';
import 'package:hms_app/providers/pricing_config_provider.dart';
import 'package:hms_app/providers/report_provider.dart';
import 'package:hms_app/providers/room_provider.dart';
import 'package:hms_app/providers/room_type_provider.dart';
import 'package:hms_app/providers/service_catalog_provider.dart';
import 'package:hms_app/models/enums/user_role.dart';
import 'package:hms_app/views/receptionist/bill_details_view.dart';
import 'package:hms_app/views/receptionist/booking_details_view.dart';
import 'package:hms_app/views/receptionist/check_out_view.dart';
import 'package:hms_app/views/receptionist/create_booking.dart';
import 'package:hms_app/views/receptionist/booking_search_view.dart';
import 'package:hms_app/views/receptionist/customer_bookings_view.dart';
import 'package:hms_app/views/receptionist/find_room_view.dart';
import 'package:hms_app/views/my_profile_view.dart';
import 'package:hms_app/views/receptionist/payment_view.dart';
import 'package:hms_app/views/receptionist/room_details_view.dart';
import 'package:hms_app/views/front_desk_manager/reports/revenue_report_view.dart';
import 'package:hms_app/views/front_desk_manager/settings/penalty_fee_config/penalty_fee_config.dart';
import 'package:hms_app/views/front_desk_manager/settings/room/add_room.dart';
import 'package:hms_app/views/front_desk_manager/settings/room/room_list.dart';
import 'package:hms_app/views/front_desk_manager/settings/room_type/room_type_list.dart';
import 'package:hms_app/views/front_desk_manager/settings/service/create_service_view.dart';
import 'package:hms_app/views/front_desk_manager/settings/service/service_list.dart';
import 'package:hms_app/views/settings_view.dart';
import 'package:hms_app/views/receptionist/stay_management.dart';
import 'package:hms_app/views/receptionist/reception_tasks_view.dart';
import 'package:hms_app/models/dtos/customer_short_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hms_app/views/receptionist/room_map_view.dart';
import 'package:hms_app/views/login_view.dart';
import 'package:provider/provider.dart';
import 'package:hms_app/providers/theme_provider.dart';
import 'package:hms_app/providers/user_provider.dart';

bool _canManageHotelConfig(UserRole role) => role.canManageHotelConfig;
bool _canManageHotelOperations(UserRole role) => role.canManageHotelOperations;
bool _canOpenSettings(UserRole role) =>
    role.canManageHotelConfig || role.canManageHotelOperations;

class RoleGuard extends StatelessWidget {
  const RoleGuard({super.key, required this.child, required this.isAllowed});

  final Widget child;
  final bool Function(UserRole role) isAllowed;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProvider>().userProfile;
    final role = profile?.role;

    if (role == null) {
      return const LoginView();
    }

    if (isAllowed(role)) {
      return child;
    }

    return const AccessDeniedView();
  }
}

class AccessDeniedView extends StatelessWidget {
  const AccessDeniedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Không có quyền truy cập')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tài khoản của bạn không có quyền truy cập màn hình này.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final role = context.read<UserProvider>().userProfile?.role;
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(role?.defaultRoute ?? '/login');
                },
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tgrjqdfzpkbhlncomcah.supabase.co',
    anonKey: 'sb_publishable_blxE4BiCmUVHm90drunqHg_WinyBHyM',
  );

  final themeProvider = ThemeProvider();
  final colorProvider = ColorProvider();

  await Future.wait([themeProvider.loadTheme(), colorProvider.loadColor()]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BookingDraftProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: colorProvider),
        ChangeNotifierProvider(create: (_) => PricingConfigProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => RoomTypeProvider()),
        ChangeNotifierProvider(create: (_) => ServiceCatalogProvider()),
        ChangeNotifierProvider(create: (_) => FeeProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: const HMSApp(),
    ),
  );
}

class HMSApp extends StatelessWidget {
  const HMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorProvider = Provider.of<ColorProvider>(context);

    return MaterialApp(
      title: 'HMS App',
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      // 1. Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorProvider.primaryColor,
          brightness: Brightness.light,
        ),
        // Use a generic light text theme as the base
        textTheme: GoogleFonts.interTextTheme(Typography.material2021().black),
      ),

      // 2. Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorProvider.primaryColor,
          brightness: Brightness.dark,
        ),
        // CRITICAL: Use the white typography base so text isn't black-on-black
        textTheme: GoogleFonts.interTextTheme(Typography.material2021().white),
      ),
      initialRoute: '/login', // login
      routes: {
        '/login': (context) => const LoginView(),
        '/room-map': (context) => const RoleGuard(
          isAllowed: _canManageHotelOperations,
          child: RoomMapView(),
        ),
        '/upcoming-checkouts': (context) => const RoleGuard(
          isAllowed: _canManageHotelOperations,
          child: ReceptionTasksView(),
        ),
        '/find-room': (context) => const RoleGuard(
          isAllowed: _canManageHotelOperations,
          child: FindRoomView(),
        ),
        '/find-customer': (context) => const RoleGuard(
          isAllowed: _canManageHotelOperations,
          child: BookingSearchView(),
        ),
        '/settings': (context) =>
            const RoleGuard(isAllowed: _canOpenSettings, child: SettingsView()),
        '/revenue-report': (context) => const RoleGuard(
          isAllowed: _canManageHotelConfig,
          child: RevenueReportView(),
        ),
        '/profile': (context) => const MyProfileView(),
        '/room-type-list': (context) => const RoleGuard(
          isAllowed: _canManageHotelConfig,
          child: RoomTypeList(),
        ),
        '/room-list': (context) => const RoleGuard(
          isAllowed: _canManageHotelConfig,
          child: RoomList(),
        ),
        '/service-list': (context) => const RoleGuard(
          isAllowed: _canManageHotelConfig,
          child: ServiceList(),
        ),
        '/create-service': (context) => const RoleGuard(
          isAllowed: _canManageHotelConfig,
          child: CreateServiceView(),
        ),
        '/add-room': (context) =>
            const RoleGuard(isAllowed: _canManageHotelConfig, child: AddRoom()),
        '/penalty-fee-config': (context) => const RoleGuard(
          isAllowed: _canManageHotelConfig,
          child: PenaltyFeeConfig(),
        ),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name!);

        // Match: /room-details/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'room-details') {
          final roomId = int.tryParse(uri.pathSegments[1]);
          if (roomId != null) {
            return MaterialPageRoute(
              builder: (context) => RoleGuard(
                isAllowed: _canManageHotelOperations,
                child: RoomDetailScreen(roomId: roomId),
              ),
            );
          }
        }

        // Match: /customer-bookings/:userId
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'customer-bookings') {
          final customer = settings.arguments as CustomerShortDetail;
          return MaterialPageRoute(
            builder: (context) => RoleGuard(
              isAllowed: _canManageHotelOperations,
              child: CustomerBookingsView(customer: customer),
            ),
          );
        }

        // Match: /edit-room/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'edit-room') {
          final roomId = int.tryParse(uri.pathSegments[1]);
          if (roomId != null) {
            return MaterialPageRoute(
              builder: (context) => RoleGuard(
                isAllowed: _canManageHotelConfig,
                child: AddRoom(roomId: roomId),
              ),
            );
          }
        }

        // Match: /create-booking/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'create-booking') {
          final roomId = int.tryParse(uri.pathSegments[1]);
          if (roomId != null) {
            return MaterialPageRoute(
              builder: (context) => RoleGuard(
                isAllowed: _canManageHotelOperations,
                child: CreateBookingScreen(roomId: roomId),
              ),
            );
          }
        }

        // Match: /stay-management/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'stay-management') {
          final bookingId = int.tryParse(uri.pathSegments[1]);
          if (bookingId != null) {
            return MaterialPageRoute(
              builder: (context) => RoleGuard(
                isAllowed: _canManageHotelOperations,
                child: StayManagement(bookingId: bookingId),
              ),
            );
          }
        }

        // Match: /booking-details/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'booking-details') {
          final bookingId = int.tryParse(uri.pathSegments[1]);
          if (bookingId != null) {
            return MaterialPageRoute(
              builder: (context) => RoleGuard(
                isAllowed: _canManageHotelOperations,
                child: BookingDetailsScreen(bookingId: bookingId),
              ),
            );
          }
        }

        // Match: /check-out/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'check-out') {
          final bookingId = int.tryParse(uri.pathSegments[1]);
          if (bookingId != null) {
            return MaterialPageRoute(
              builder: (context) => RoleGuard(
                isAllowed: _canManageHotelOperations,
                child: CheckOutView(bookingId: bookingId),
              ),
            );
          }
        }

        // Match: /bill-details/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'bill-details') {
          final bookingId = int.tryParse(uri.pathSegments[1]);
          if (bookingId != null) {
            return MaterialPageRoute(
              builder: (context) => RoleGuard(
                isAllowed: _canManageHotelOperations,
                child: BillDetailsView(bookingId: bookingId),
              ),
            );
          }
        }

        // Match: /payment/:totalAmount
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'payment') {
          final totalAmount = int.tryParse(uri.pathSegments[1]);
          if (totalAmount != null) {
            return MaterialPageRoute<bool>(
              builder: (context) => RoleGuard(
                isAllowed: _canManageHotelOperations,
                child: PaymentView(totalAmount: totalAmount),
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
