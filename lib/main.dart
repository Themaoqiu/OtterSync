import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ottersync/firebase_options.dart';
import 'package:ottersync/routes/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? bootstrapError;

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
