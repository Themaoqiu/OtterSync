import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ottersync/firebase_options.dart';
import 'package:ottersync/routes/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? bootstrapError;

  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    debugPrint('dotenv load skipped: $error');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    bootstrapError = error;
    debugPrint('Firebase bootstrap failed: $error');
  }

  runApp(getRootWidget(bootstrapError: bootstrapError));
}
