library ridemate_ai;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;

part 'core/api_client.dart';
part 'core/app_colors.dart';
part 'core/app_theme.dart';
part 'models/app_user.dart';
part 'models/driver_summary.dart';
part 'models/ride.dart';
part 'models/ride_location.dart';
part 'models/ride_match.dart';
part 'screens/auth/auth_page.dart';


part 'screens/rider/rider_home.dart';
part 'screens/rider/rider_map_tab.dart';
part 'screens/rider/chat_screen.dart';
part 'screens/rider/rider_trips_tab.dart';
part 'screens/rider/rider_profile_tab.dart';
part 'screens/driver/driver_home.dart';
part 'screens/driver/driver_live_tab.dart';
part 'screens/driver/driver_requests_tab.dart';
part 'screens/driver/driver_profile_tab.dart';
part 'widgets/app_field.dart';
part 'widgets/app_shell.dart';
part 'widgets/app_top_bar.dart';
part 'widgets/card_surface.dart';
part 'widgets/ride_map_preview.dart';
part 'widgets/status_pill.dart';
part 'widgets/segmented_switch.dart';
part 'widgets/home_widgets.dart';
part 'widgets/ride_cards.dart';
part 'widgets/transport_widgets.dart';
part 'widgets/interactive_ride_map.dart';
part 'screens/admin/admin_dashboard.dart';

class RideMateApp extends StatelessWidget {
  const RideMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RideMate AI',
      theme: AppTheme.build(),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final api = ApiClient();
  AppUser? user;
  bool loadingSession = false;
  bool adminMode = false;

  @override
  void initState() {
    super.initState();
  }

  void _openAdmin() {
    setState(() => adminMode = true);
  }

  void _closeAdmin() {
    setState(() => adminMode = false);
  }

  Future<void> _openDemo(String role) async {
    setState(() => loadingSession = true);
    try {
      final data = await api.demoSession(role);
      if (!mounted) return;
      setState(() {
        api.token = data['token']?.toString();
        user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
        loadingSession = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        user = AppUser(
          id: 'local-$role',
          fullName: role == 'DRIVER' ? 'Aman Driver' : 'Alex Rider',
          mobileNumber: '9000000000',
          email: 'demo@ridemate.ai',
          role: role,
        );
        loadingSession = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await api.post('/api/auth/logout', {});
    } catch (_) {}
    api.logout();
    if (mounted) {
      setState(() {
        user = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (adminMode) {
      return AdminDashboard(api: api, onLogout: _closeAdmin);
    }

    if (loadingSession) {
      return const DemoBootPage();
    }
    
    if (user == null) {
      return AuthPage(
        api: api,
        onLoggedIn: (token, loggedInUser) {
          setState(() {
            api.token = token;
            user = loggedInUser;
          });
        },
      );
    }

    return user!.role == 'DRIVER'
        ? DriverHome(api: api, user: user!, onLogout: _logout)
        : RiderHome(api: api, user: user!, onLogout: _logout);
  }
}

class DemoBootPage extends StatelessWidget {
  const DemoBootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bg, AppColors.bgAlt],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBrandMark(),
              SizedBox(height: 18),
              Text('RideMate AI',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Preparing your ride dashboard',
                  style: TextStyle(color: AppColors.muted)),
              SizedBox(height: 20),
              SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5)),
            ],
          ),
        ),
      ),
    );
  }
}
