import 'package:get/get.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/terms_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/auth/presentation/confirm_reset_password_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/home/home_binding.dart';
import '../data/middleware/auth_middleware.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/schedule/presentation/schedule_page.dart';
import '../features/calendar/presentation/calendar_page.dart';
import '../features/feedback/presentation/feedback_page.dart';
import '../features/exams/presentation/exams_page.dart';
import '../features/auth/presentation/access_selection_page.dart';
import '../features/admin/presentation/admin_upload_page.dart';
import '../features/admin/presentation/horario_upload_page.dart';
import '../features/admin/presentation/eventos_upload_page.dart';
import '../features/admin/presentation/calendario_upload_page.dart';
import '../features/admin/presentation/provas_upload_page.dart';
import '../features/admin/presentation/admin_feedback_stats_page.dart';
import '../features/events/presentation/events_page.dart';
import '../features/debug/presentation/route_debug_widget.dart';

abstract class AppRoutes {
  static const INITIAL = '/';
  static const ACCESS_SELECTION = '/access-selection';
  static const SPLASH = '/splash';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const TERMS = '/terms';
  static const HOME = '/home';
  static const PROFILE = '/profile';
  static const SCHEDULE = '/schedule';
  static const EVENTS = '/events';
  static const CALENDAR = '/calendar';
  static const EXAMS = '/exams';
  static const FEEDBACK = '/feedback';
  static const RESET_PASSWORD = '/reset-password';
  static const LOCATION_SEARCH = '/location-search';
  static const ADMIN_UPLOAD = '/admin-upload';
  static const ADMIN_UPLOAD_HORARIO = '/admin-upload/horario';
  static const ADMIN_UPLOAD_EVENTOS = '/admin-upload/eventos';
  static const ADMIN_UPLOAD_CALENDARIO = '/admin-upload/calendario';
  static const ADMIN_UPLOAD_PROVAS = '/admin-upload/provas';
  static const ADMIN_FEEDBACK_STATS = '/admin-feedback-stats';
  static const DEBUG_ROUTE = '/debug-route';

  static final pages = [
    GetPage(
      name: INITIAL,
      page: () => const AccessSelectionPage(),
    ),
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
      page: () {
        final uri = Uri.tryParse(Uri.base.toString());
        String? token;
        
        if (uri != null) {
          // Tenta pegar do queryParameters primeiro
          if (uri.queryParameters.containsKey('token')) {
            token = uri.queryParameters['token'];
          } else {
            // Para Flutter web com hash routing, parse o fragment
            final fragment = uri.fragment;
            if (fragment.isNotEmpty) {
              final fragmentUri = Uri.tryParse('http://dummy.com/$fragment');
              if (fragmentUri != null && fragmentUri.queryParameters.containsKey('token')) {
                token = fragmentUri.queryParameters['token'];
              }
            }
          }
          
          if (token != null && token.isNotEmpty) {
            return ConfirmResetPasswordPage();
          }
        }
        return const ResetPasswordPage();
      },
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: TERMS,
      page: () => const TermsPage(),
    ),
    GetPage(
      name: HOME,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: FEEDBACK,
      page: () => const FeedbackPage(),
    ),
    GetPage(
      name: SCHEDULE,
      page: () => SchedulePage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: LOCATION_SEARCH,
      page: () => const HomePage(showSearch: true),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: CALENDAR,
      page: () => CalendarPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: EXAMS,
      page: () => ExamsPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: EVENTS,
      page: () => const EventsPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: ADMIN_UPLOAD,
      page: () => const AdminUploadPage(),
    ),
    GetPage(
      name: ADMIN_UPLOAD_HORARIO,
      page: () => const HorarioUploadPage(),
    ),
    GetPage(
      name: ADMIN_UPLOAD_EVENTOS,
      page: () => const EventosUploadPage(),
    ),
    GetPage(
      name: ADMIN_UPLOAD_CALENDARIO,
      page: () => const CalendarioUploadPage(),
    ),
    GetPage(
      name: ADMIN_UPLOAD_PROVAS,
      page: () => const ProvasUploadPage(),
    ),
    GetPage(
      name: ADMIN_FEEDBACK_STATS,
      page: () => const AdminFeedbackStatsPage(),
    ),
    GetPage(
      name: FEEDBACK,
      page: () => const FeedbackPage(),
    ),
    GetPage(
      name: DEBUG_ROUTE,
      page: () => const RouteDebugPage(),
    ),
  ];
}