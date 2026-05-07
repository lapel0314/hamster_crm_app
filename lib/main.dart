import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hamster_crm_app/core/database/app_database.dart';
import 'package:hamster_crm_app/core/theme/app_theme.dart';
import 'package:hamster_crm_app/data/models/customer.dart';
import 'package:hamster_crm_app/data/models/prospect.dart';
import 'package:hamster_crm_app/data/repositories/crm_repository.dart';

void main() {
  final CrmStore repository = kIsWeb
      ? InMemoryCrmRepository.seeded()
      : CrmRepository(AppDatabase());
  runApp(HamsterCrmApp(repository: repository));
}

class HamsterCrmApp extends StatelessWidget {
  const HamsterCrmApp({super.key, required this.repository});

  final CrmStore repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golden Hamster CRM',
      debugShowCheckedModeBanner: false,
      theme: buildHamsterTheme(),
      home: HamsterHomePage(repository: repository),
    );
  }
}

class HamsterHomePage extends StatefulWidget {
  const HamsterHomePage({super.key, required this.repository});

  final CrmStore repository;

  @override
  State<HamsterHomePage> createState() => _HamsterHomePageState();
}

class _HamsterHomePageState extends State<HamsterHomePage> {
  String selectedPage = '대시보드';
  late Future<_HomeData> _dataFuture = _load();
  final searchController = TextEditingController();

  Future<_HomeData> _load() async {
    return _HomeData(
      summary: await widget.repository.dashboardSummary(),
      customers: await widget.repository.customers(
        query: searchController.text,
      ),
      prospects: await widget.repository.prospects(
        query: searchController.text,
      ),
    );
  }

  void _refresh() {
    setState(() {
      _dataFuture = _load();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selected: selectedPage,
            onSelected: (page) => setState(() => selectedPage = page),
          ),
          Expanded(
            child: FutureBuilder<_HomeData>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data;
                if (data == null) {
                  return const Center(child: Text('데이터를 불러오지 못했습니다.'));
                }
                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: _content(data),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(_HomeData data) {
    return switch (selectedPage) {
      '고객등록' => CustomerFormPage(
        repository: widget.repository,
        onSaved: _refresh,
      ),
      '고객DB' => CustomerDbPage(
        customers: data.customers,
        searchController: searchController,
        onSearch: _refresh,
      ),
      '가망고객' => ProspectsPage(
        repository: widget.repository,
        prospects: data.prospects,
        searchController: searchController,
        onChanged: _refresh,
      ),
      _ => _DashboardPage(data: data),
    };
  }
}

class _HomeData {
  final DashboardSummary summary;
  final List<Customer> customers;
  final List<Prospect> prospects;

  const _HomeData({
    required this.summary,
    required this.customers,
    required this.prospects,
  });
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final pages = ['대시보드', '고객등록', '고객DB', '가망고객'];
    return Container(
      width: 250,
      color: HamsterColors.brown,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🐹 Golden Hamster',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '로컬 오프라인 CRM',
            style: TextStyle(color: HamsterColors.cream),
          ),
          const SizedBox(height: 30),
          for (final page in pages)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton.tonal(
                onPressed: () => onSelected(page),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  alignment: Alignment.centerLeft,
                  backgroundColor: selected == page
                      ? HamsterColors.gold
                      : HamsterColors.cream.withValues(alpha: 0.14),
                  foregroundColor: selected == page
                      ? HamsterColors.brown
                      : Colors.white,
                ),
                child: Text(
                  page,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          const Spacer(),
          const Text(
            '혼자 쓰는 PC용\n로그인 없이 바로 시작',
            style: TextStyle(color: HamsterColors.cream, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.data});

  final _HomeData data;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###원');
    return ListView(
      children: [
        Text('대시보드', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _MetricCard('고객DB', '${data.summary.totalCustomers}명'),
            _MetricCard('가망고객', '${data.summary.totalProspects}명'),
            _MetricCard('이번달 매출', money.format(data.summary.monthRevenue)),
            _MetricCard('이번달 순이익', money.format(data.summary.monthProfit)),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1월~12월 정산현황',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('월')),
                    DataColumn(label: Text('분양')),
                    DataColumn(label: Text('구매')),
                    DataColumn(label: Text('매출')),
                    DataColumn(label: Text('원가')),
                    DataColumn(label: Text('순이익')),
                  ],
                  rows: data.summary.monthly
                      .map(
                        (m) => DataRow(
                          cells: [
                            DataCell(Text('${m.month}월')),
                            DataCell(Text('${m.adoptionCount}')),
                            DataCell(Text('${m.purchaseCount}')),
                            DataCell(Text(money.format(m.revenue))),
                            DataCell(Text(money.format(m.cost))),
                            DataCell(Text(money.format(m.profit))),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _RankingCard(
                title: '이번달 분양 순위',
                items: data.summary.adoptionRanking,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _RankingCard(
                title: '이번달 구매 순위',
                items: data.summary.purchaseRanking,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CustomerFormPage extends StatefulWidget {
  const CustomerFormPage({
    super.key,
    required this.repository,
    required this.onSaved,
  });

  final CrmStore repository;
  final VoidCallback onSaved;

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final adoption = TextEditingController();
  final purchase = TextEditingController();
  final revenue = TextEditingController();
  final cost = TextEditingController();
  final memo = TextEditingController();
  DateTime date = DateTime.now();
  String gender = '미입력';

  @override
  void dispose() {
    for (final c in [name, phone, adoption, purchase, revenue, cost, memo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('고객명을 입력해 주세요.')));
      return;
    }
    final now = DateTime.now().toIso8601String();
    await widget.repository.addCustomer(
      Customer(
        date: DateFormat('yyyy-MM-dd').format(date),
        customerName: name.text.trim(),
        gender: gender,
        phone: phone.text.trim(),
        adoption: adoption.text.trim(),
        purchase: purchase.text.trim(),
        revenue: _toInt(revenue.text),
        cost: _toInt(cost.text),
        memo: memo.text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    widget.onSaved();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('고객DB에 저장했습니다.')));
    }
    for (final c in [name, phone, adoption, purchase, revenue, cost, memo]) {
      c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('고객등록', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _DateButton(
                  label: '날짜',
                  date: date,
                  onChanged: (v) => setState(() => date = v),
                ),
                _Field(label: '고객명', controller: name),
                _Dropdown(
                  label: '성별',
                  value: gender,
                  values: const ['미입력', '남', '여'],
                  onChanged: (v) => setState(() => gender = v),
                ),
                _Field(label: '휴대폰번호', controller: phone),
                _Field(label: '분양', controller: adoption),
                _Field(label: '구매', controller: purchase),
                _Field(label: '매출', controller: revenue, number: true),
                _Field(label: '원가', controller: cost, number: true),
                SizedBox(
                  width: 700,
                  child: TextField(
                    controller: memo,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: '메모'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _save,
          icon: const Text('🐹'),
          label: const Text('고객 저장'),
        ),
      ],
    );
  }
}

class CustomerDbPage extends StatelessWidget {
  const CustomerDbPage({
    super.key,
    required this.customers,
    required this.searchController,
    required this.onSearch,
  });

  final List<Customer> customers;
  final TextEditingController searchController;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###원');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('고객DB', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 14),
        _SearchBar(controller: searchController, onSearch: onSearch),
        const SizedBox(height: 14),
        Expanded(
          child: Card(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('날짜')),
                  DataColumn(label: Text('고객명')),
                  DataColumn(label: Text('성별')),
                  DataColumn(label: Text('휴대폰번호')),
                  DataColumn(label: Text('분양')),
                  DataColumn(label: Text('구매')),
                  DataColumn(label: Text('매출')),
                  DataColumn(label: Text('원가')),
                  DataColumn(label: Text('메모')),
                ],
                rows: customers
                    .map(
                      (c) => DataRow(
                        cells: [
                          DataCell(Text(c.date)),
                          DataCell(Text(c.customerName)),
                          DataCell(Text(c.gender)),
                          DataCell(Text(c.phone)),
                          DataCell(Text(c.adoption)),
                          DataCell(Text(c.purchase)),
                          DataCell(Text(money.format(c.revenue))),
                          DataCell(Text(money.format(c.cost))),
                          DataCell(Text(c.memo)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProspectsPage extends StatefulWidget {
  const ProspectsPage({
    super.key,
    required this.repository,
    required this.prospects,
    required this.searchController,
    required this.onChanged,
  });

  final CrmStore repository;
  final List<Prospect> prospects;
  final TextEditingController searchController;
  final VoidCallback onChanged;

  @override
  State<ProspectsPage> createState() => _ProspectsPageState();
}

class _ProspectsPageState extends State<ProspectsPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  DateTime consultationDate = DateTime.now();
  DateTime visitDate = DateTime.now();

  Future<void> _add() async {
    if (name.text.trim().isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await widget.repository.addProspect(
      Prospect(
        consultationDate: DateFormat('yyyy-MM-dd').format(consultationDate),
        visitDate: DateFormat('yyyy-MM-dd').format(visitDate),
        customerName: name.text.trim(),
        phone: phone.text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    name.clear();
    phone.clear();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('가망고객', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 14),
        _SearchBar(
          controller: widget.searchController,
          onSearch: widget.onChanged,
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _DateButton(
                  label: '상담날짜',
                  date: consultationDate,
                  onChanged: (v) => setState(() => consultationDate = v),
                ),
                _DateButton(
                  label: '방문예정',
                  date: visitDate,
                  onChanged: (v) => setState(() => visitDate = v),
                ),
                _Field(label: '고객명', controller: name),
                _Field(label: '휴대폰번호', controller: phone),
                FilledButton(onPressed: _add, child: const Text('가망고객 추가')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('상담날짜')),
              DataColumn(label: Text('방문예정')),
              DataColumn(label: Text('고객명')),
              DataColumn(label: Text('휴대폰번호')),
              DataColumn(label: Text('메모')),
            ],
            rows: widget.prospects
                .map(
                  (p) => DataRow(
                    cells: [
                      DataCell(Text(p.consultationDate)),
                      DataCell(Text(p.visitDate)),
                      DataCell(Text(p.customerName)),
                      DataCell(Text(p.phone)),
                      DataCell(Text(p.memo)),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.title, this.value);
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: HamsterColors.softBrown),
              ),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.title, required this.items});
  final String title;
  final List<RankItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (items.isEmpty) const Text('아직 데이터가 없습니다.'),
            for (final item in items) Text('${item.label} · ${item.count}건'),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSearch});
  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '검색'),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(onPressed: onSearch, child: const Text('검색')),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {
            controller.clear();
            onSearch();
          },
          child: const Text('초기화'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.number = false,
  });
  final String label;
  final TextEditingController controller;
  final bool number;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (v) => v == null ? null : onChanged(v),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onChanged,
  });
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: OutlinedButton(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            initialDate: date,
          );
          if (picked != null) onChanged(picked);
        },
        child: Text('$label: ${DateFormat('yyyy-MM-dd').format(date)}'),
      ),
    );
  }
}

int _toInt(String value) => int.tryParse(value.replaceAll(',', '').trim()) ?? 0;
