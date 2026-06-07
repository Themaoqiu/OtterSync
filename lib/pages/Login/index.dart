import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ottersync/components/Login/BrandHeader.dart';
import 'package:ottersync/components/Login/LoginActions.dart';
import 'package:ottersync/components/Login/StickyCollage.dart';

const _bgColor = Color(0xFF1F5DBD);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: Column(
                  children: const [
                    SizedBox(height: 12),
                    BrandHeader(),
                    SizedBox(height: 44),
                    StickyCollage(),
                    SizedBox(height: 40),
                    Text(
                      '计划并跟踪任务、缺陷、支持票证等。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            LoginActions(
              onLogin: () => context.push('/sign-in'),
              onRegister: () => context.push('/register'),
            ),
          ],
        ),
      ),
    );
  }
}
