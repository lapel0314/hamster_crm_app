import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:hamster_crm_app/data/models/customer.dart';
import 'package:hamster_crm_app/data/models/prospect.dart';
import 'package:hamster_crm_app/data/repositories/crm_repository.dart';
import 'package:web/web.dart' as web;

CrmStore createPlatformCrmStore() => ElectronFileCrmRepository();

@JS('hamsterCrmStorage')
external JSObject? get _electronStorage;

class ElectronFileCrmRepository extends InMemoryCrmRepository {
  ElectronFileCrmRepository() : super();

  static const _localStorageKey = 'hamster_crm_data_json';

  late final Future<void> _ready = _loadFromStorage();

  Future<String?> _loadRaw() async {
    final api = _electronStorage;
    if (api != null) {
      final value = await api.callMethod<JSPromise<JSAny?>>('load'.toJS).toDart;
      return (value as JSString?)?.toDart;
    }
    return web.window.localStorage.getItem(_localStorageKey);
  }

  Future<void> _saveRaw(String value) async {
    final api = _electronStorage;
    if (api != null) {
      await api.callMethod<JSPromise<JSAny?>>('save'.toJS, value.toJS).toDart;
      return;
    }
    web.window.localStorage.setItem(_localStorageKey, value);
  }

  Future<void> _loadFromStorage() async {
    final raw = await _loadRaw();
    if (raw == null || raw.trim().isEmpty) return;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final customers = (decoded['customers'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(Customer.fromMap)
        .toList();
    final prospects = (decoded['prospects'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(Prospect.fromMap)
        .toList();

    replaceData(customers: customers, prospects: prospects);
  }

  Future<void> _persist() async {
    final allCustomers = [
      ...await super.customers(),
      ...await super.deletedCustomers(),
    ];
    final allProspects = [
      ...await super.prospects(),
      ...await super.deletedProspects(),
    ];
    await _saveRaw(
      const JsonEncoder.withIndent('  ').convert({
        'version': 1,
        'updatedAt': DateTime.now().toIso8601String(),
        'customers': allCustomers.map((customer) => customer.toMap()).toList(),
        'prospects': allProspects.map((prospect) => prospect.toMap()).toList(),
      }),
    );
  }

  @override
  Future<int> addCustomer(Customer customer) async {
    await _ready;
    final id = await super.addCustomer(customer);
    await _persist();
    return id;
  }

  @override
  Future<int> addProspect(Prospect prospect) async {
    await _ready;
    final id = await super.addProspect(prospect);
    await _persist();
    return id;
  }

  @override
  Future<List<Customer>> customers({String query = ''}) async {
    await _ready;
    return super.customers(query: query);
  }

  @override
  Future<List<Prospect>> prospects({String query = ''}) async {
    await _ready;
    return super.prospects(query: query);
  }

  @override
  Future<List<Customer>> deletedCustomers() async {
    await _ready;
    return super.deletedCustomers();
  }

  @override
  Future<List<Prospect>> deletedProspects() async {
    await _ready;
    return super.deletedProspects();
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    await _ready;
    await super.updateCustomer(customer);
    await _persist();
  }

  @override
  Future<void> updateProspect(Prospect prospect) async {
    await _ready;
    await super.updateProspect(prospect);
    await _persist();
  }

  @override
  Future<void> softDeleteCustomer(int id) async {
    await _ready;
    await super.softDeleteCustomer(id);
    await _persist();
  }

  @override
  Future<void> softDeleteProspect(int id) async {
    await _ready;
    await super.softDeleteProspect(id);
    await _persist();
  }

  @override
  Future<void> restoreCustomer(int id) async {
    await _ready;
    await super.restoreCustomer(id);
    await _persist();
  }

  @override
  Future<void> restoreProspect(int id) async {
    await _ready;
    await super.restoreProspect(id);
    await _persist();
  }

  @override
  Future<void> hardDeleteCustomer(int id) async {
    await _ready;
    await super.hardDeleteCustomer(id);
    await _persist();
  }

  @override
  Future<void> hardDeleteProspect(int id) async {
    await _ready;
    await super.hardDeleteProspect(id);
    await _persist();
  }

  @override
  Future<DashboardSummary> dashboardSummary() async {
    await _ready;
    return super.dashboardSummary();
  }
}
