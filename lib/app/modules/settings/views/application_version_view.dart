import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../resources/app_strings.dart';

class ApplicationVersionView extends StatelessWidget {
  const ApplicationVersionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4511E), // Slightly lighter orange for this screen
        foregroundColor: Colors.white,
        title: const Text('Application Version'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top orange section
          Container(
            color: const Color(0xFFF4511E),
            padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
            child: Column(
              children: const [
                Text(
                  'GOODCOM',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    fontFamily: 'serif', // matching the logo style roughly
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Version: v3.1.0.19',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom white section
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: const [
                Text(
                  'Version status:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'latest version',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
