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
