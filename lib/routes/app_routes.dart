import 'package:get/get.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/terms_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/home/home_binding.dart';
import '../data/middleware/auth_middleware.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/schedule/presentation/schedule_page.dart';
import '../features/locations/presentation/location_search_page.dart';
import '../features/locations/presentation/class_notifications_page.dart';
import '../features/locations/location_binding.dart';

abstract class AppRoutes {
  static const INITIAL = '/';
  static const SPLASH = '/splash';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const TERMS = '/terms';
  static const HOME = '/home';
  static const PROFILE = '/profile';
  static const SCHEDULE = '/schedule';
  static const EVENTS = '/events';
  static const EXAMS = '/exams';
  static const RESET_PASSWORD = '/reset-password';
  static const LOCATION_SEARCH = '/location-search';
  static const CLASS_NOTIFICATIONS = '/class-notifications';

  static final pages = [
    GetPage(
      name: SPLASH,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: LOGIN,
      page: () => const LoginPage(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: REGISTER,
      page: () => const RegisterPage(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: RESET_PASSWORD,
      page: () => const ResetPasswordPage(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: TERMS,
      page: () => const TermsPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: HOME,
      page: () => const HomePage(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),    GetPage(
      name: SCHEDULE,
      page: () => SchedulePage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: LOCATION_SEARCH,
      page: () => LocationSearchPage(),
      binding: LocationBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: CLASS_NOTIFICATIONS,
      page: () => ClassNotificationsPage(),
      binding: LocationBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}