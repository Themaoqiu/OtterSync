import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  static const _usersCollection = 'users';

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<User?> authStateChanges() => FirebaseAuth.instance.authStateChanges();

  Future<User> signIn(String account, String password) async {
    return _guard(() async {
      final email = account.contains('@')
          ? account
          : await _resolveEmailByUsername(account);
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    });
  }

  Future<User> register(String username, String email, String password) async {
    return _guard(() async {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      await user.updateDisplayName(username);
      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'username': username,
            'email': email.trim().toLowerCase(),
            'createdAt': FieldValue.serverTimestamp(),
          });
      return user;
    });
  }

  Future<User> signInWithGoogle() async {
    return _guard(() async {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw AuthServiceException('已取消 Google 登录');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      await _ensureUserRecord(userCredential.user!);
      return userCredential.user!;
    });
  }

  Future<User> signInWithApple() async {
    return _guard(() async {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );
      final user = userCredential.user!;

      final displayName =
          credential.givenName != null || credential.familyName != null
          ? '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim()
          : null;

      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      await _ensureUserRecord(user);
      return user;
    });
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  Future<String> _resolveEmailByUsername(String username) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(_usersCollection)
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw AuthServiceException('用户名不存在：$username');
    }

    return snapshot.docs.first.data()['email'] as String;
  }

  Future<void> _ensureUserRecord(User user) async {
    final doc = await FirebaseFirestore.instance.collection(_usersCollection).doc(user.uid).get();
    if (!doc.exists) {
      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'username': user.displayName ?? user.email?.split('@').first ?? '',
            'email': user.email?.trim().toLowerCase() ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error, stackTrace) {
      debugPrint('AuthService FirebaseAuthException: ${error.code}');
      debugPrintStack(stackTrace: stackTrace);
      throw AuthServiceException(_authErrorMessage(error.code));
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('AuthService FirebaseException: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw AuthServiceException(error.message ?? '操作失败，请稍后重试。');
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'invalid-credential':
        return '账号或密码错误。';
      case 'user-not-found':
        return '该账号未注册。';
      case 'wrong-password':
        return '密码错误。';
      case 'email-already-in-use':
        return '该邮箱已被注册。';
      case 'weak-password':
        return '密码强度不足，请至少使用6位字符。';
      case 'invalid-email':
        return '邮箱格式不正确。';
      case 'user-disabled':
        return '该账号已被停用。';
      case 'too-many-requests':
        return '操作过于频繁，请稍后再试。';
      case 'network-request-failed':
        return '网络连接失败，请检查网络设置。';
      case 'operation-not-allowed':
        return '该登录方式未启用，请在 Firebase Console 中开启 Email/Password 认证。';
      case 'admin-restricted-operation':
        return '该操作被限制，请检查 Firebase 认证配置。';
      default:
        return '操作失败（$code），请稍后重试。';
    }
  }
}
