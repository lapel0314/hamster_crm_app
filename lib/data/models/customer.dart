class Customer {
  final int? id;
  final String date;
  final String customerName;
  final String gender;
  final String phone;
  final String adoption;
  final String purchase;
  final int revenue;
  final int cost;
  final String memo;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const Customer({
    this.id,
    required this.date,
    required this.customerName,
    this.gender = '',
    this.phone = '',
    this.adoption = '',
    this.purchase = '',
    this.revenue = 0,
    this.cost = 0,
    this.memo = '',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  int get profit => revenue - cost;

  Customer copyWith({
    int? id,
    String? date,
    String? customerName,
    String? gender,
    String? phone,
    String? adoption,
    String? purchase,
    int? revenue,
    int? cost,
    String? memo,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      date: date ?? this.date,
      customerName: customerName ?? this.customerName,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      adoption: adoption ?? this.adoption,
      purchase: purchase ?? this.purchase,
      revenue: revenue ?? this.revenue,
      cost: cost ?? this.cost,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'customer_name': customerName,
      'gender': gender,
      'phone': phone,
      'adoption': adoption,
      'purchase': purchase,
      'revenue': revenue,
      'cost': cost,
      'memo': memo,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as int?,
      date: map['date'] as String,
      customerName: map['customer_name'] as String,
      gender: (map['gender'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      adoption: (map['adoption'] as String?) ?? '',
      purchase: (map['purchase'] as String?) ?? '',
      revenue: (map['revenue'] as int?) ?? 0,
      cost: (map['cost'] as int?) ?? 0,
      memo: (map['memo'] as String?) ?? '',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }
}
