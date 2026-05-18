import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/modules/home/views/home_view.dart';
import 'app/bindings/initial_binding.dart';
import 'app/resources/app_colors.dart';
import 'app/routes/app_pages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/services/notification_service.dart';
import 'app/services/logger_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  await Get.putAsync(() => LoggerService().init());
  LoggerService.to.log('Application started');
  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    LoggerService.to.log('App Lifecycle State: ${state.name}');
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Standard POS screen size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Bites Orders',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.deepOrange,
            primaryColor: AppColors.primary,
            textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
            useMaterial3: true,
          ),
          initialBinding: InitialBinding(),
          getPages: AppPages.routes,
          initialRoute: AppPages.INITIAL,
          navigatorObservers: [LogNavigatorObserver()],
        );
      },
    );
  }
}

