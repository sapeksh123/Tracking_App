import 'package:flutter/material.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/create_user_screen.dart';
import 'screens/track_user_screen_v2.dart';
import 'screens/user_login_screen.dart';
import 'screens/user_home_screen_v2.dart';
import 'screens/user_detail_screen_v2.dart';
import 'screens/attendance_history_screen.dart';
import 'screens/session_route_screen_enhanced.dart';

Map<String, WidgetBuilder> appRoutes = {
  "/admin-login": (context) => AdminLoginScreen(),
  "/admin-dashboard": (context) => AdminDashboardScreen(),
  "/create-user": (context) => CreateUserScreen(),
  "/track-user": (context) => TrackUserScreenV2(),
  "/user-detail": (context) => UserDetailScreenV2(userId: '', userName: ''),

  "/user-login": (context) => UserLoginScreen(),
  "/user-home": (context) => UserHomeScreenV2(),
  "/attendance-history": (context) => AttendanceHistoryScreen(),
  "/session-route": (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return SessionRouteScreenEnhanced(
      sessionId: args['sessionId'],
      userId: args['userId'],
    );
  },
};
