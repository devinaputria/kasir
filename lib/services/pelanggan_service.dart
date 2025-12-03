import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pelanggan_model.dart';

class PelangganService {
  final supabase = Supabase.instance.client;
  final String table = 'pelanggan';

  // -------------------------------
  // Ambil semua pelanggan
  // -------------------------------
  Future<List<Pelanggan>> getAllPelanggan() async {
    try {
      final response = await supabase
          .from(table)
          .select()
          .order('id', ascending: true);

      if (response.isEmpty) return [];
      return response.map((e) => Pelanggan.fromJson(e)).toList();
    } catch (e) {
      print("❌ Gagal mengambil data pelanggan: $e");
      return [];
    }
  }

  // -------------------------------
  // Tambah pelanggan
  // -------------------------------
  Future<Pelanggan?> addPelanggan(Pelanggan p) async {
    try {
      final response = await supabase
          .from(table)
          .insert([p.toMap()])
          .select()
          .maybeSingle();

      if (response == null) {
        print("❌ Insert ditolak RLS");
        return null;
      }

      return Pelanggan.fromJson(response);
    } catch (e) {
      print("❌ Error insert pelanggan: $e");
      return null;
    }
  }

  // -------------------------------
  // Update pelanggan
  // -------------------------------
  Future<Pelanggan?> updatePelanggan(int id, Pelanggan p) async {
    try {
      final response = await supabase
          .from(table)
          .update(p.toMap())
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response == null) {
        print("❌ Update ditolak RLS / ID tidak ditemukan");
        return null;
      }

      return Pelanggan.fromJson(response);
    } catch (e) {
      print("❌ Error update pelanggan: $e");
      return null;
    }
  }

  // -------------------------------
  // Hapus pelanggan
  // -------------------------------
  Future<bool> deletePelanggan(int id) async {
    try {
      await supabase.from(table).delete().eq('id', id);
      return true;
    } catch (e) {
      print("❌ Error delete pelanggan: $e");
      return false;
    }
  }

  // -------------------------------
  // Realtime listener
  // -------------------------------
  RealtimeChannel listenPelanggan(void Function() onChange) {
    final channel = supabase
        .channel('pelanggan_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) => onChange(),
        )
        .subscribe();

    return channel;
  }
}