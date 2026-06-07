import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hms_app/providers/color_provider.dart';
import 'package:hms_app/providers/pricing_config_provider.dart';
import 'package:hms_app/views/bill_details_view.dart';
import 'package:hms_app/views/booking_details_view.dart';
import 'package:hms_app/views/check_out_view.dart';
import 'package:hms_app/views/create_booking.dart';
import 'package:hms_app/views/booking_search_view.dart';
import 'package:hms_app/views/customer_bookings_view.dart';
import 'package:hms_app/views/find_room_view.dart';
import 'package:hms_app/views/my_profile_view.dart';
import 'package:hms_app/views/payment_view.dart';
import 'package:hms_app/views/room_details_view.dart';
import 'package:hms_app/views/settings/penalty_fee_config/penalty_fee_config.dart';
import 'package:hms_app/views/settings/room/add_room.dart';
import 'package:hms_app/views/settings/room/room_list.dart';
import 'package:hms_app/views/settings/room_type/room_type_list.dart';
import 'package:hms_app/views/settings/service/create_service_view.dart';
import 'package:hms_app/views/settings/service/service_list.dart';
import 'package:hms_app/views/settings_view.dart';
import 'package:hms_app/views/stay_management.dart';
import 'package:hms_app/models/dtos/customer_short_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/room_map_view.dart';
import 'views/login_view.dart';
import 'package:provider/provider.dart';
import 'package:hms_app/providers/theme_provider.dart';
import 'package:hms_app/providers/user_provider.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://tgrjqdfzpkbhlncomcah.supabase.co',
    anonKey: 'sb_publishable_blxE4BiCmUVHm90drunqHg_WinyBHyM',
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ColorProvider()),
        ChangeNotifierProvider(create: (_) => PricingConfigProvider()),
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
      title: 'Flutter Demo',
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
        '/room-map': (context) => const RoomMapView(),
        '/find-room': (context) => const FindRoomView(),
        '/find-customer': (context) => const BookingSearchView(),
        '/settings': (context) => const SettingsView(),
        '/profile': (context) => const MyProfileView(),
        '/room-type-list': (context) => const RoomTypeList(),
        '/room-list': (context) => const RoomList(),
        '/service-list': (context) => const ServiceList(),
        '/create-service': (context) => const CreateServiceView(),
        '/add-room': (context) => const AddRoom(),
        '/penalty-fee-config': (context) => const PenaltyFeeConfig(),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name!);

        // Match: /room-details/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'room-details') {
          final roomId = int.tryParse(uri.pathSegments[1]);
          if (roomId != null) {
            return MaterialPageRoute(
              builder: (context) => RoomDetailScreen(roomId: roomId),
            );
          }
        }

        // Match: /customer-bookings/:userId
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'customer-bookings') {
          final customer = settings.arguments as CustomerShortDetail;
          return MaterialPageRoute(
            builder: (context) => CustomerBookingsView(customer: customer),
          );
        }

        // Match: /edit-room/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'edit-room') {
          final roomId = int.tryParse(uri.pathSegments[1]);
          if (roomId != null) {
            return MaterialPageRoute(
              builder: (context) => AddRoom(roomId: roomId),
            );
          }
        }

        // Match: /create-booking/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'create-booking') {
          final roomId = int.tryParse(uri.pathSegments[1]);
          if (roomId != null) {
            return MaterialPageRoute(
              builder: (context) => CreateBookingScreen(roomId: roomId),
            );
          }
        }

        // Match: /stay-management/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'stay-management') {
          final bookingId = int.tryParse(uri.pathSegments[1]);
          if (bookingId != null) {
            return MaterialPageRoute(
              builder: (context) => StayManagement(bookingId: bookingId),
            );
          }
        }

        // Match: /booking-details/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'booking-details') {
          final bookingId = int.tryParse(uri.pathSegments[1]);
          if (bookingId != null) {
            return MaterialPageRoute(
              builder: (context) => BookingDetailsScreen(bookingId: bookingId),
            );
          }
        }

        // Match: /check-out/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'check-out') {
          final bookingId = int.tryParse(uri.pathSegments[1]);
          if (bookingId != null) {
            return MaterialPageRoute(
              builder: (context) => CheckOutView(bookingId: bookingId),
            );
          }
        }

        // Match: /bill-details/:id
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'bill-details') {
          final bookingId = int.tryParse(uri.pathSegments[1]);
          if (bookingId != null) {
            return MaterialPageRoute(
              builder: (context) => BillDetailsView(bookingId: bookingId),
            );
          }
        }

        // Match: /payment/:totalAmount
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'payment') {
          final totalAmount = int.tryParse(uri.pathSegments[1]);
          if (totalAmount != null) {
            return MaterialPageRoute<bool>(
              builder: (context) => PaymentView(totalAmount: totalAmount),
            );
          }
        }
        return null;
      },
    );
  }
}
