class Pelanggan {
  final int? id;
  final String nama;
  final String? email;
  final String? phone;

  const Pelanggan({
    this.id,
    required this.nama,
    this.email,
    this.phone,
  });

  Pelanggan copyWith({
    int? id,
    String? nama,
    String? email,
    String? phone,
  }) {
    return Pelanggan(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  factory Pelanggan.fromJson(Map<String, dynamic> json) => Pelanggan(
        id: json['id'] as int?,
        nama: json['nama'] as String,
        email: json['email'] as String?,
        phone: (json['no_telepon'] as num?)?.toString(),
      );

  Map<String, dynamic> toMap() => {
        'nama': nama,
        if (email?.isNotEmpty == true) 'email': email,
        if (phone?.isNotEmpty == true) 'no_telepon': int.tryParse(phone!.replaceAll(RegExp(r'[^\d]'), '')),
      };
}