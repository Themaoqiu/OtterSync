import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:ottersync/firebase_options.dart';
import 'package:ottersync/routes/index.dart';
import 'package:ottersync/services/messaging_service.dart';
import 'package:ottersync/services/pomodoro_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? bootstrapError;

  FlutterForegroundTask.initCommunicationPort();
  try {
    await PomodoroController.instance.init();
  } catch (error) {
    debugPrint('番茄钟前台服务初始化失败: $error');
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    debugPrint('dotenv load skipped: $error');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await MessagingService.instance.initialize();
  } catch (error) {
    bootstrapError = error;
    debugPrint('Firebase bootstrap failed: $error');
  }

  runApp(getRootWidget(bootstrapError: bootstrapError));
}
