import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProdukService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // READ: Get all
  Future<List<Map<String, dynamic>>> getAllProduk() async {
    try {
      final response = await _supabase.from('produk').select().order('id', ascending: false);
      debugPrint('✅ getAllProduk: ${response.length} items');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ getAllProduk error: $e');
      rethrow;
    }
  }

  // CREATE: Add with optional image
  Future<void> addProdukWithImage({
    required String nama,
    required double harga,
    required int stokSaatIni,
    required String kategori,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      String? gambarPath;
      String? contentType = 'image/jpeg'; // Default
      final storage = _supabase.storage.from('gambar');

      if ((imageBytes != null && kIsWeb) || (imageFile != null && !kIsWeb)) {
        if (fileName == null) throw Exception('FileName required for image upload');
        
        // Detect content type based on extension
        if (fileName.toLowerCase().endsWith('.png')) contentType = 'image/png';
        
        if (kIsWeb && imageBytes != null) {
          final response = await storage.uploadBinary(
            fileName,
            imageBytes,
            fileOptions: FileOptions(contentType: contentType),
          );
          gambarPath = response;
        } else if (!kIsWeb && imageFile != null) {
          final response = await storage.upload(
            fileName,
            imageFile,
            fileOptions: FileOptions(contentType: contentType),
          );
          gambarPath = response;
        }
        debugPrint('✅ Upload image: $gambarPath');
      } else {
        gambarPath = null;
        debugPrint('ℹ️ No image, gambar_url = null');
      }

      // FIX: Add .select() to return inserted data and avoid null response
      final insertResponse = await _supabase.from('produk').insert({
        'nama': nama,
        'harga': harga,
        'stok_saat_ini': stokSaatIni,
        'kategori': kategori,
        'gambar_url': gambarPath,
      }).select();

      // FIX: Safe check for null or empty
      if (insertResponse == null || (insertResponse is List && insertResponse.isEmpty)) {
        throw Exception('Gagal insert produk: No response');
      }
      debugPrint('✅ Add success: ID ${insertResponse[0]['id']}');
    } catch (e) {
      debugPrint('❌ Add error: $e');
      rethrow;
    }
  }

  // UPDATE: Update produk
  Future<void> updateProduk(String id, Map<String, dynamic> data) async {
    try {
      // FIX: Cast ID to int (assuming auto-increment integer in DB)
      final intId = int.tryParse(id) ?? int.parse(id);
      debugPrint('🔍 Checking existence for ID: $intId'); // Debug log
      
      // FIX: First check if ID exists
      final checkResponse = await _supabase.from('produk').select('id').eq('id', intId).maybeSingle();
      if (checkResponse == null) {
        debugPrint('❌ ID $intId not found in DB');
        throw Exception('Produk ID $id not found');
      }
      debugPrint('✅ ID $intId exists, proceeding with update');
      
      final response = await _supabase.from('produk').update(data).eq('id', intId);
      // FIX: Do not throw if response empty – Supabase returns [] on success if no changes or RLS
      if (response == null) {
        debugPrint('⚠️ Update response null for ID: $intId (possible RLS or no changes)');
      } else {
        debugPrint('✅ Update success for ID: $id, response length: ${response.length}');
      }
    } catch (e) {
      debugPrint('❌ Update error: $e');
      rethrow;
    }
  }

  // DELETE: Delete with image remove
  Future<void> deleteProduk(String id) async {
    try {
      // FIX: Cast ID to int
      final intId = int.tryParse(id) ?? int.parse(id);
      debugPrint('🔍 Checking for delete ID: $intId'); // Debug log
      
      final produk = await _supabase.from('produk').select('gambar_url').eq('id', intId).maybeSingle();
      if (produk != null && produk['gambar_url'] != null && produk['gambar_url'].isNotEmpty) {
        await _supabase.storage.from('gambar').remove([produk['gambar_url']]);
        debugPrint('🗑️ Image removed: ${produk['gambar_url']}');
      }
      await _supabase.from('produk').delete().eq('id', intId);
      debugPrint('✅ Delete success for ID: $id');
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      rethrow;
    }
  }

  // Helpers for upload
  Future<String?> uploadImage(File file, String fileName) async {
    try {
      final storage = _supabase.storage.from('gambar');
      String? contentType = 'image/jpeg';
      if (fileName.toLowerCase().endsWith('.png')) contentType = 'image/png';
      
      final response = await storage.upload(
        fileName,
        file,
        fileOptions: FileOptions(contentType: contentType),
      );
      return response;
    } catch (e) {
      debugPrint('❌ Upload file error: $e');
      return null;
    }
  }

  Future<String?> uploadImageWeb(Uint8List bytes, String fileName) async {
    try {
      final storage = _supabase.storage.from('gambar');
      String? contentType = 'image/jpeg';
      if (fileName.toLowerCase().endsWith('.png')) contentType = 'image/png';
      
      final response = await storage.uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(contentType: contentType),
      );
      return response;
    } catch (e) {
      debugPrint('❌ Upload web error: $e');
      return null;
    }
  }
}