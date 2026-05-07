import 'package:hamster_crm_app/core/database/app_database.dart';
import 'package:hamster_crm_app/data/models/customer.dart';
import 'package:hamster_crm_app/data/models/prospect.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract class CrmStore {
  Future<int> addCustomer(Customer customer);
  Future<int> addProspect(Prospect prospect);
  Future<List<Customer>> customers({String query = ''});
  Future<List<Prospect>> prospects({String query = ''});
  Future<List<Customer>> deletedCustomers();
  Future<List<Prospect>> deletedProspects();
  Future<void> updateCustomer(Customer customer);
  Future<void> updateProspect(Prospect prospect);
  Future<void> softDeleteCustomer(int id);
  Future<void> softDeleteProspect(int id);
  Future<void> restoreCustomer(int id);
  Future<void> restoreProspect(int id);
  Future<void> hardDeleteCustomer(int id);
  Future<void> hardDeleteProspect(int id);
  Future<DashboardSummary> dashboardSummary();
}

class CrmRepository implements CrmStore {
  CrmRepository(this.database);

  final AppDatabase database;

  @override
  Future<int> addCustomer(Customer customer) async {
    final db = await database.instance;
    final values = customer.toMap()..remove('id');
    return db.insert('customers', values);
  }

  @override
  Future<int> addProspect(Prospect prospect) async {
    final db = await database.instance;
    final values = prospect.toMap()..remove('id');
    return db.insert('prospects', values);
  }

  @override
  Future<List<Customer>> customers({String query = ''}) async {
    final db = await database.instance;
    final where = _searchWhere(query, [
      'customer_name',
      'phone',
      'adoption',
      'purchase',
      'memo',
    ]);
    final rows = await db.query(
      'customers',
      where: where.$1,
      whereArgs: where.$2,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  @override
  Future<List<Prospect>> prospects({String query = ''}) async {
    final db = await database.instance;
    final where = _searchWhere(query, [
      'customer_name',
      'phone',
      'adoption',
      'purchase',
      'memo',
    ]);
    final rows = await db.query(
      'prospects',
      where: where.$1,
      whereArgs: where.$2,
      orderBy: 'consultation_date DESC, id DESC',
    );
    return rows.map(Prospect.fromMap).toList();
  }

  @override
  Future<List<Customer>> deletedCustomers() async {
    final db = await database.instance;
    final rows = await db.query(
      'customers',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC, id DESC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  @override
  Future<List<Prospect>> deletedProspects() async {
    final db = await database.instance;
    final rows = await db.query(
      'prospects',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC, id DESC',
    );
    return rows.map(Prospect.fromMap).toList();
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    final id = customer.id;
    if (id == null) return;
    final db = await database.instance;
    final values = customer.toMap()..remove('id');
    values['updated_at'] = DateTime.now().toIso8601String();
    await db.update('customers', values, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateProspect(Prospect prospect) async {
    final id = prospect.id;
    if (id == null) return;
    final db = await database.instance;
    final values = prospect.toMap()..remove('id');
    values['updated_at'] = DateTime.now().toIso8601String();
    await db.update('prospects', values, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> softDeleteCustomer(int id) async {
    final db = await database.instance;
    await db.update(
      'customers',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> softDeleteProspect(int id) async {
    final db = await database.instance;
    await db.update(
      'prospects',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> restoreCustomer(int id) async {
    final db = await database.instance;
    await db.update(
      'customers',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> restoreProspect(int id) async {
    final db = await database.instance;
    await db.update(
      'prospects',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> hardDeleteCustomer(int id) async {
    final db = await database.instance;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> hardDeleteProspect(int id) async {
    final db = await database.instance;
    await db.delete('prospects', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<DashboardSummary> dashboardSummary() async {
    final db = await database.instance;
    final monthPrefix = DateTime.now().toIso8601String().substring(0, 7);
    final customerRows = await db.query(
      'customers',
      where: 'deleted_at IS NULL',
    );
    final customers = customerRows.map(Customer.fromMap).toList();
    final monthly = List.generate(12, (i) => MonthlySettlement(month: i + 1));

    for (final customer in customers) {
      final month = int.tryParse(
        customer.date.split('-').elementAtOrNull(1) ?? '',
      );
      if (month == null || month < 1 || month > 12) continue;
      monthly[month - 1] = monthly[month - 1].add(customer);
    }

    final currentMonthCustomers = customers
        .where((c) => c.date.startsWith(monthPrefix))
        .toList();
    return DashboardSummary(
      totalCustomers: customers.length,
      totalProspects: await _activeProspectCount(db),
      monthRevenue: currentMonthCustomers.fold<int>(
        0,
        (sum, c) => sum + c.revenue,
      ),
      monthCost: currentMonthCustomers.fold<int>(0, (sum, c) => sum + c.cost),
      monthly: monthly,
      adoptionRanking: _ranking(currentMonthCustomers.map((c) => c.adoption)),
      purchaseRanking: _ranking(currentMonthCustomers.map((c) => c.purchase)),
    );
  }

  Future<int> _activeProspectCount(Database db) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM prospects WHERE deleted_at IS NULL',
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  (String, List<Object?>) _searchWhere(String query, List<String> columns) {
    final trimmed = query.trim();
    final clauses = ['deleted_at IS NULL'];
    final args = <Object?>[];
    if (trimmed.isNotEmpty) {
      clauses.add(
        '(${columns.map((column) => '$column LIKE ?').join(' OR ')})',
      );
      args.addAll(List.filled(columns.length, '%$trimmed%'));
    }
    return (clauses.join(' AND '), args);
  }

  List<RankItem> _ranking(Iterable<String> values) {
    return buildRanking(values);
  }
}

const Object _keepDeletedAt = Object();

class InMemoryCrmRepository implements CrmStore {
  InMemoryCrmRepository({List<Customer>? customers, List<Prospect>? prospects})
    : _customers = [...?customers],
      _prospects = [...?prospects];

  factory InMemoryCrmRepository.seeded() {
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    final createdAt = now.toIso8601String();
    return InMemoryCrmRepository(
      customers: [
        Customer(
          id: 1,
          date: today,
          customerName: '김우주',
          gender: '여',
          phone: '010-1234-5678',
          adoption: '골든햄스터',
          purchase: '케이지 세트',
          revenue: 180000,
          cost: 95000,
          memo: '처음 키우는 고객, 사육 안내 필요',
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
        Customer(
          id: 2,
          date: today,
          customerName: '박보리',
          gender: '남',
          phone: '010-7777-1020',
          adoption: '드워프',
          purchase: '사료/베딩',
          revenue: 90000,
          cost: 42000,
          memo: '토요일 재방문 예정',
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      ],
      prospects: [
        Prospect(
          id: 1,
          consultationDate: today,
          visitDate: today,
          customerName: '이모카',
          phone: '010-9000-8811',
          adoption: '펄 드워프',
          memo: '방문 전 사진 요청',
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      ],
    );
  }

  final List<Customer> _customers;
  final List<Prospect> _prospects;
  int _nextCustomerId = 100;
  int _nextProspectId = 100;

  @override
  Future<int> addCustomer(Customer customer) async {
    final id = _nextCustomerId++;
    _customers.add(_copyCustomer(customer, id));
    return id;
  }

  @override
  Future<int> addProspect(Prospect prospect) async {
    final id = _nextProspectId++;
    _prospects.add(_copyProspect(prospect, id));
    return id;
  }

  @override
  Future<List<Customer>> customers({String query = ''}) async {
    final filtered = _customers
        .where((c) => c.deletedAt == null && _matchesCustomer(c, query))
        .toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  @override
  Future<List<Prospect>> prospects({String query = ''}) async {
    final filtered = _prospects
        .where((p) => p.deletedAt == null && _matchesProspect(p, query))
        .toList();
    filtered.sort((a, b) => b.consultationDate.compareTo(a.consultationDate));
    return filtered;
  }

  @override
  Future<List<Customer>> deletedCustomers() async {
    final filtered = _customers.where((c) => c.deletedAt != null).toList();
    filtered.sort((a, b) => (b.deletedAt ?? '').compareTo(a.deletedAt ?? ''));
    return filtered;
  }

  @override
  Future<List<Prospect>> deletedProspects() async {
    final filtered = _prospects.where((p) => p.deletedAt != null).toList();
    filtered.sort((a, b) => (b.deletedAt ?? '').compareTo(a.deletedAt ?? ''));
    return filtered;
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    final id = customer.id;
    if (id == null) return;
    final index = _customers.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _customers[index] = customer;
  }

  @override
  Future<void> updateProspect(Prospect prospect) async {
    final id = prospect.id;
    if (id == null) return;
    final index = _prospects.indexWhere((p) => p.id == id);
    if (index == -1) return;
    _prospects[index] = prospect;
  }

  @override
  Future<void> softDeleteCustomer(int id) async {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _customers[index] = _copyCustomer(
      _customers[index],
      id,
      deletedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<void> softDeleteProspect(int id) async {
    final index = _prospects.indexWhere((p) => p.id == id);
    if (index == -1) return;
    _prospects[index] = _copyProspect(
      _prospects[index],
      id,
      deletedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<void> restoreCustomer(int id) async {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _customers[index] = _copyCustomer(_customers[index], id, deletedAt: null);
  }

  @override
  Future<void> restoreProspect(int id) async {
    final index = _prospects.indexWhere((p) => p.id == id);
    if (index == -1) return;
    _prospects[index] = _copyProspect(_prospects[index], id, deletedAt: null);
  }

  @override
  Future<void> hardDeleteCustomer(int id) async {
    _customers.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> hardDeleteProspect(int id) async {
    _prospects.removeWhere((p) => p.id == id);
  }

  @override
  Future<DashboardSummary> dashboardSummary() async {
    final activeCustomers = await customers();
    final activeProspects = await prospects();
    final monthPrefix = DateTime.now().toIso8601String().substring(0, 7);
    final monthly = List.generate(12, (i) => MonthlySettlement(month: i + 1));
    for (final customer in activeCustomers) {
      final month = int.tryParse(
        customer.date.split('-').elementAtOrNull(1) ?? '',
      );
      if (month == null || month < 1 || month > 12) continue;
      monthly[month - 1] = monthly[month - 1].add(customer);
    }
    final currentMonth = activeCustomers
        .where((c) => c.date.startsWith(monthPrefix))
        .toList();
    return DashboardSummary(
      totalCustomers: activeCustomers.length,
      totalProspects: activeProspects.length,
      monthRevenue: currentMonth.fold(0, (sum, c) => sum + c.revenue),
      monthCost: currentMonth.fold(0, (sum, c) => sum + c.cost),
      monthly: monthly,
      adoptionRanking: buildRanking(currentMonth.map((c) => c.adoption)),
      purchaseRanking: buildRanking(currentMonth.map((c) => c.purchase)),
    );
  }

  bool _matchesCustomer(Customer c, String query) {
    final q = query.trim();
    if (q.isEmpty) return true;
    return [
      c.customerName,
      c.phone,
      c.adoption,
      c.purchase,
      c.memo,
    ].any((value) => value.contains(q));
  }

  bool _matchesProspect(Prospect p, String query) {
    final q = query.trim();
    if (q.isEmpty) return true;
    return [
      p.customerName,
      p.phone,
      p.adoption,
      p.purchase,
      p.memo,
    ].any((value) => value.contains(q));
  }

  Customer _copyCustomer(
    Customer c,
    int id, {
    Object? deletedAt = _keepDeletedAt,
  }) {
    return Customer(
      id: id,
      date: c.date,
      customerName: c.customerName,
      gender: c.gender,
      phone: c.phone,
      adoption: c.adoption,
      purchase: c.purchase,
      revenue: c.revenue,
      cost: c.cost,
      memo: c.memo,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
      deletedAt: identical(deletedAt, _keepDeletedAt)
          ? c.deletedAt
          : deletedAt as String?,
    );
  }

  Prospect _copyProspect(
    Prospect p,
    int id, {
    Object? deletedAt = _keepDeletedAt,
  }) {
    return Prospect(
      id: id,
      consultationDate: p.consultationDate,
      visitDate: p.visitDate,
      customerName: p.customerName,
      gender: p.gender,
      phone: p.phone,
      adoption: p.adoption,
      purchase: p.purchase,
      revenue: p.revenue,
      cost: p.cost,
      memo: p.memo,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
      deletedAt: identical(deletedAt, _keepDeletedAt)
          ? p.deletedAt
          : deletedAt as String?,
    );
  }
}

class DashboardSummary {
  final int totalCustomers;
  final int totalProspects;
  final int monthRevenue;
  final int monthCost;
  final List<MonthlySettlement> monthly;
  final List<RankItem> adoptionRanking;
  final List<RankItem> purchaseRanking;

  const DashboardSummary({
    required this.totalCustomers,
    required this.totalProspects,
    required this.monthRevenue,
    required this.monthCost,
    required this.monthly,
    required this.adoptionRanking,
    required this.purchaseRanking,
  });

  int get monthProfit => monthRevenue - monthCost;
}

class MonthlySettlement {
  final int month;
  final int adoptionCount;
  final int purchaseCount;
  final int revenue;
  final int cost;

  const MonthlySettlement({
    required this.month,
    this.adoptionCount = 0,
    this.purchaseCount = 0,
    this.revenue = 0,
    this.cost = 0,
  });

  int get profit => revenue - cost;

  MonthlySettlement add(Customer customer) {
    return MonthlySettlement(
      month: month,
      adoptionCount: adoptionCount + (customer.adoption.trim().isEmpty ? 0 : 1),
      purchaseCount: purchaseCount + (customer.purchase.trim().isEmpty ? 0 : 1),
      revenue: revenue + customer.revenue,
      cost: cost + customer.cost,
    );
  }
}

class RankItem {
  final String label;
  final int count;

  const RankItem({required this.label, required this.count});
}

List<RankItem> buildRanking(Iterable<String> values) {
  final counts = <String, int>{};
  final labels = <String, String>{};
  for (final value in values) {
    final label = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    final key = label.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
    labels.putIfAbsent(key, () => label);
  }
  final items = counts.entries
      .map((e) => RankItem(label: labels[e.key] ?? e.key, count: e.value))
      .toList();
  items.sort((a, b) => b.count.compareTo(a.count));
  return items.take(5).toList();
}
