import 'package:flutter/material.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/create_user_screen.dart';
import 'screens/track_user_screen.dart';
import 'screens/user_login_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/user_detail_screen.dart';

Map<String, WidgetBuilder> appRoutes = {
  "/admin-login": (context) => AdminLoginScreen(),
  "/admin-dashboard": (context) => AdminDashboardScreen(),
  "/create-user": (context) => CreateUserScreen(),
  "/track-user": (context) => TrackUserScreen(),
  "/user-detail": (context) => UserDetailScreen(userId: '', userName: ''),

  "/user-login": (context) => UserLoginScreen(),
  "/user-home": (context) => UserHomeScreen(),
};
