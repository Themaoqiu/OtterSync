import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ottersync/services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _authSubscription = _authService.authStateChanges().listen(_onAuthChanged);
  }

  final AuthService _authService;
  late final StreamSubscription<User?> _authSubscription;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  String get displayName => _user?.displayName ?? _user?.email?.split('@').first ?? '';
  String get email => _user?.email ?? '';

  void _onAuthChanged(User? user) {
    _user = user;
    _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> signIn(String account, String password) async {
    await _authService.signIn(account, password);
  }

  Future<void> register(String username, String email, String password) async {
    await _authService.register(username, email, password);
  }

  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
  }

  Future<void> signInWithApple() async {
    await _authService.signInWithApple();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    final user = _authService.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name);
    await user.reload();
    _user = _authService.currentUser;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in widget tree.');
    return scope!.notifier!;
  }
}