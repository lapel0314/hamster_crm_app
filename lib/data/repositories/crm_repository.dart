import 'package:hamster_crm_app/core/database/app_database.dart';
import 'package:hamster_crm_app/data/models/customer.dart';
import 'package:hamster_crm_app/data/models/prospect.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CrmRepository {
  CrmRepository(this.database);

  final AppDatabase database;

  Future<int> addCustomer(Customer customer) async {
    final db = await database.instance;
    final values = customer.toMap()..remove('id');
    return db.insert('customers', values);
  }

  Future<int> addProspect(Prospect prospect) async {
    final db = await database.instance;
    final values = prospect.toMap()..remove('id');
    return db.insert('prospects', values);
  }

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

  Future<void> softDeleteCustomer(int id) async {
    final db = await database.instance;
    await db.update(
      'customers',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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
    final counts = <String, int>{};
    for (final value in values) {
      final key = value.trim();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final items = counts.entries
        .map((e) => RankItem(label: e.key, count: e.value))
        .toList();
    items.sort((a, b) => b.count.compareTo(a.count));
    return items.take(5).toList();
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
