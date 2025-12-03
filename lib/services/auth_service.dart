import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// -------------------------
  /// LOGIN USER
  /// -------------------------
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        // Ambil role dari metadata Supabase JWT
        final role = response.user?.userMetadata?['role'] ?? 'kasir';

        return {
          'success': true,
          'user': {
            'id': response.user!.id,
            'email': response.user!.email,
            'role': role,
          },
        };
      } else {
        return {'success': false, 'message': "Email atau password salah!"};
      }
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// -------------------------
  /// REGISTER USER BARU
  /// -------------------------
  Future<Map<String, dynamic>?> register(
      String email, String password, String role) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'role': role}, // role tersimpan di metadata
      );

      if (response.user != null) {
        // Simpan ke tabel users untuk keperluan UI (opsional, tidak dipakai di RLS)
        await supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'role': role,
        });

        return {
          'success': true,
          'user': {
            'id': response.user!.id,
            'email': email,
            'role': role,
          },
        };
      } else {
        return {'success': false, 'message': "Pendaftaran gagal!"};
      }
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// -------------------------
  /// LOGOUT USER
  /// -------------------------
  Future<Map<String, dynamic>> logout() async {
    try {
      await supabase.auth.signOut();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// -------------------------
  /// GET CURRENT USER ROLE
  /// -------------------------
  Future<String?> getCurrentRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    // Role utama dari metadata JWT (yang dipakai RLS)
    final metadataRole = user.userMetadata?['role'];
    if (metadataRole != null) return metadataRole;

    // Fallback dari tabel users (untuk antisipasi developer edit manual)
    final userData = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return userData?['role'];
  }

  /// -------------------------
  /// IS ADMIN?
  /// -------------------------
  Future<bool> isAdmin() async {
    final role = await getCurrentRole();
    return role == 'admin';
  }
}
