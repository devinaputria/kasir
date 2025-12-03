class ProdukModel {
  final int id;
  final String nama;
  final String? deskripsi;
  final String? kategori;
  final double harga;
  final String? gambarUrl;
  final int stokSaatIni;

  ProdukModel({
    required this.id,
    required this.nama,
    this.deskripsi,
    this.kategori,
    required this.harga,
    this.gambarUrl,
    required this.stokSaatIni,
  });

  // Convert JSON -> Model
  factory ProdukModel.fromJson(Map<String, dynamic> json) {
    return ProdukModel(
      id: json['id'],
      nama: json['nama'],
      deskripsi: json['deskripsi'],
      kategori: json['kategori'],
      harga: (json['harga'] as num).toDouble(),
      gambarUrl: json['gambar_url'],
      stokSaatIni: json['stok_saat_ini'],
    );
  }

  // Convert Model -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'deskripsi': deskripsi,
      'kategori': kategori,
      'harga': harga,
      'gambar_url': gambarUrl,
      'stok_saat_ini': stokSaatIni,
    };
  }
}
