import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error de autenticación: $e';
    }
  }

  // Register with email and password
  Future<AuthResponse> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error de registro: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al enviar correo de recuperación: $e';
    }
  }

  // Handle Supabase Auth exceptions
  String _handleAuthException(AuthException e) {
    switch (e.message.toLowerCase()) {
      case String msg when msg.contains('invalid login credentials'):
        return 'Correo o contraseña incorrectos';
      case String msg when msg.contains('user already registered'):
        return 'Este correo ya está registrado';
      case String msg when msg.contains('password should be at least'):
        return 'La contraseña debe tener al menos 6 caracteres';
      case String msg when msg.contains('invalid email'):
        return 'Correo electrónico inválido';
      case String msg when msg.contains('email not confirmed'):
        return 'Por favor confirma tu correo electrónico';
      case String msg when msg.contains('user not found'):
        return 'No se encontró ninguna cuenta con este correo';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
