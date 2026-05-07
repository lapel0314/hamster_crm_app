import 'package:flutter_test/flutter_test.dart';
import 'package:hamster_crm_app/core/database/app_database.dart';
import 'package:hamster_crm_app/data/models/customer.dart';
import 'package:hamster_crm_app/data/models/prospect.dart';
import 'package:hamster_crm_app/data/repositories/crm_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late CrmRepository repository;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = CrmRepository(database);
  });

  tearDown(() => database.close());

  test('stores customers and builds dashboard summary', () async {
    const now = '2026-05-07T00:00:00';
    await repository.addCustomer(
      const Customer(
        date: '2026-05-07',
        customerName: '랭가',
        phone: '010-0000-0000',
        adoption: '골든햄스터',
        purchase: '케이지',
        revenue: 100000,
        cost: 40000,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final customers = await repository.customers(query: '랭가');
    final summary = await repository.dashboardSummary();

    expect(customers, hasLength(1));
    expect(customers.single.profit, 60000);
    expect(summary.totalCustomers, 1);
  });

  test('ranking ignores spacing differences', () {
    final ranking = buildRanking(['골든햄스터', '골든 햄스터', ' 골든   햄스터 ']);

    expect(ranking, hasLength(1));
    expect(ranking.single.label, '골든햄스터');
    expect(ranking.single.count, 3);
  });

  test('stores prospects separately from customers', () async {
    const now = '2026-05-07T00:00:00';
    await repository.addProspect(
      const Prospect(
        consultationDate: '2026-05-07',
        visitDate: '2026-05-10',
        customerName: '예비고객',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(await repository.prospects(query: '예비'), hasLength(1));
    expect((await repository.dashboardSummary()).totalProspects, 1);
  });

  test('updates and soft deletes customer and prospect records', () async {
    const now = '2026-05-07T00:00:00';
    final customerId = await repository.addCustomer(
      const Customer(
        date: '2026-05-07',
        customerName: '수정전',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final prospectId = await repository.addProspect(
      const Prospect(
        consultationDate: '2026-05-07',
        customerName: '가망수정전',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await repository.updateCustomer(
      Customer(
        id: customerId,
        date: '2026-05-08',
        customerName: '수정후',
        revenue: 30000,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.updateProspect(
      Prospect(
        id: prospectId,
        consultationDate: '2026-05-09',
        customerName: '가망수정후',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect((await repository.customers(query: '수정후')).single.revenue, 30000);
    expect(await repository.prospects(query: '가망수정후'), hasLength(1));

    await repository.softDeleteCustomer(customerId);
    await repository.softDeleteProspect(prospectId);

    expect(await repository.customers(), isEmpty);
    expect(await repository.prospects(), isEmpty);
    expect(await repository.deletedCustomers(), hasLength(1));
    expect(await repository.deletedProspects(), hasLength(1));
  });

  test('restores and hard deletes trash records', () async {
    const now = '2026-05-07T00:00:00';
    final customerId = await repository.addCustomer(
      const Customer(
        date: '2026-05-07',
        customerName: '휴지통고객',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final prospectId = await repository.addProspect(
      const Prospect(
        consultationDate: '2026-05-07',
        customerName: '휴지통가망',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await repository.softDeleteCustomer(customerId);
    await repository.softDeleteProspect(prospectId);
    await repository.restoreCustomer(customerId);
    await repository.restoreProspect(prospectId);

    expect(await repository.customers(query: '휴지통고객'), hasLength(1));
    expect(await repository.prospects(query: '휴지통가망'), hasLength(1));

    await repository.softDeleteCustomer(customerId);
    await repository.softDeleteProspect(prospectId);
    await repository.hardDeleteCustomer(customerId);
    await repository.hardDeleteProspect(prospectId);

    expect(await repository.deletedCustomers(), isEmpty);
    expect(await repository.deletedProspects(), isEmpty);
  });
}
