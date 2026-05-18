part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const LOGIN = _Paths.LOGIN;
  static const SETTINGS = _Paths.SETTINGS;
  static const ORDER_REPORT = _Paths.ORDER_REPORT;
  static const SPLASH = _Paths.SPLASH;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const LOGIN = '/login';
  static const SETTINGS = '/settings';
  static const ORDER_REPORT = '/order-report';
  static const SPLASH = '/splash';
}
